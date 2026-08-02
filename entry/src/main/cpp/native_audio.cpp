#include <node_api.h>

#include <multimedia/player_framework/native_avbuffer.h>
#include <multimedia/player_framework/native_avcodec_audiocodec.h>
#include <multimedia/player_framework/native_avcodec_base.h>
#include <multimedia/player_framework/native_avdemuxer.h>
#include <multimedia/player_framework/native_avformat.h>
#include <multimedia/player_framework/native_avmuxer.h>
#include <multimedia/player_framework/native_avsource.h>

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <stdexcept>
#include <string>
#include <sys/stat.h>
#include <unistd.h>
#include <vector>

namespace {

struct WavInfo {
    int32_t sampleRate = 0;
    int32_t channels = 0;
    int32_t bitsPerSample = 0;
    int64_t dataOffset = 0;
    int64_t dataSize = 0;
};

struct ConvertWork {
    napi_env env = nullptr;
    napi_deferred deferred = nullptr;
    napi_async_work asyncWork = nullptr;
    int32_t sourceFd = -1;
    int32_t targetFd = -1;
    int32_t bitrate = 128000;
    std::string error;
};

struct ExtractWork {
    napi_deferred deferred = nullptr;
    napi_async_work asyncWork = nullptr;
    int32_t sourceFd = -1;
    int64_t sourceSize = 0;
    int32_t targetFd = -1;
    std::string error;
};

struct RemuxTrack {
    uint32_t sourceIndex = 0;
    int32_t outputIndex = -1;
    OH_AVBuffer *sample = nullptr;
    OH_AVCodecBufferAttr attr {};
    bool eos = false;
};

uint16_t ReadLe16(const uint8_t *data)
{
    return static_cast<uint16_t>(data[0]) |
        static_cast<uint16_t>(data[1] << 8);
}

uint32_t ReadLe32(const uint8_t *data)
{
    return static_cast<uint32_t>(data[0]) |
        (static_cast<uint32_t>(data[1]) << 8) |
        (static_cast<uint32_t>(data[2]) << 16) |
        (static_cast<uint32_t>(data[3]) << 24);
}

void ReadExact(int fd, int64_t offset, void *buffer, size_t size, const char *stage)
{
    auto *target = static_cast<uint8_t *>(buffer);
    size_t total = 0;
    while (total < size) {
        const ssize_t count = pread(fd, target + total, size - total, offset + static_cast<int64_t>(total));
        if (count <= 0) {
            throw std::runtime_error(std::string(stage) + ": unexpected end of file");
        }
        total += static_cast<size_t>(count);
    }
}

WavInfo ParseWav(int fd)
{
    struct stat fileStat {};
    if (fstat(fd, &fileStat) != 0 || fileStat.st_size < 12) {
        throw std::runtime_error("WAV parse: invalid file");
    }

    uint8_t header[12] {};
    ReadExact(fd, 0, header, sizeof(header), "WAV header");
    if (std::memcmp(header, "RIFF", 4) != 0 || std::memcmp(header + 8, "WAVE", 4) != 0) {
        throw std::runtime_error("WAV parse: RIFF/WAVE header required");
    }

    WavInfo info;
    bool foundFormat = false;
    bool foundData = false;
    int64_t offset = 12;
    while (offset + 8 <= fileStat.st_size) {
        uint8_t chunkHeader[8] {};
        ReadExact(fd, offset, chunkHeader, sizeof(chunkHeader), "WAV chunk");
        const uint32_t chunkSize = ReadLe32(chunkHeader + 4);
        const int64_t chunkDataOffset = offset + 8;
        const int64_t chunkEnd = chunkDataOffset + static_cast<int64_t>(chunkSize);
        if (chunkEnd > fileStat.st_size) {
            throw std::runtime_error("WAV parse: chunk exceeds file size");
        }

        if (std::memcmp(chunkHeader, "fmt ", 4) == 0) {
            if (chunkSize < 16) {
                throw std::runtime_error("WAV parse: invalid fmt chunk");
            }
            uint8_t format[16] {};
            ReadExact(fd, chunkDataOffset, format, sizeof(format), "WAV format");
            const uint16_t audioFormat = ReadLe16(format);
            info.channels = ReadLe16(format + 2);
            info.sampleRate = static_cast<int32_t>(ReadLe32(format + 4));
            info.bitsPerSample = ReadLe16(format + 14);
            if (audioFormat != 1) {
                throw std::runtime_error("WAV parse: only PCM format 1 is supported");
            }
            foundFormat = true;
        } else if (std::memcmp(chunkHeader, "data", 4) == 0) {
            info.dataOffset = chunkDataOffset;
            info.dataSize = chunkSize;
            foundData = true;
        }

        offset = chunkEnd + (chunkSize & 1U);
    }

    if (!foundFormat || !foundData) {
        throw std::runtime_error("WAV parse: fmt and data chunks are required");
    }
    if ((info.channels != 1 && info.channels != 2) || info.sampleRate <= 0 || info.bitsPerSample != 16) {
        throw std::runtime_error("WAV parse: only 16-bit mono or stereo PCM is supported");
    }
    const int32_t blockAlign = info.channels * static_cast<int32_t>(sizeof(int16_t));
    if (info.dataSize <= 0 || info.dataSize % blockAlign != 0) {
        throw std::runtime_error("WAV parse: PCM data is empty or not frame-aligned");
    }
    return info;
}

void CheckCode(OH_AVErrCode code, const char *stage)
{
    if (code != AV_ERR_OK) {
        throw std::runtime_error(std::string(stage) + " failed, code=" +
            std::to_string(static_cast<int32_t>(code)));
    }
}

void SetFormatInt(OH_AVFormat *format, const char *key, int32_t value, const char *stage)
{
    if (!OH_AVFormat_SetIntValue(format, key, value)) {
        throw std::runtime_error(std::string(stage) + " failed");
    }
}

void SetFormatLong(OH_AVFormat *format, const char *key, int64_t value, const char *stage)
{
    if (!OH_AVFormat_SetLongValue(format, key, value)) {
        throw std::runtime_error(std::string(stage) + " failed");
    }
}

void StartMuxerFromCodec(OH_AVCodec *codec, OH_AVMuxer *muxer, int32_t &trackIndex, bool &muxerStarted)
{
    if (muxerStarted) {
        return;
    }
    OH_AVFormat *outputFormat = OH_AudioCodec_GetOutputDescription(codec);
    if (outputFormat == nullptr) {
        throw std::runtime_error("GetOutputDescription returned null");
    }
    const OH_AVErrCode addTrackResult = OH_AVMuxer_AddTrack(muxer, &trackIndex, outputFormat);
    OH_AVFormat_Destroy(outputFormat);
    CheckCode(addTrackResult, "AVMuxer AddTrack");
    CheckCode(OH_AVMuxer_Start(muxer), "AVMuxer Start");
    muxerStarted = true;
}

void ConvertWavToM4a(int sourceFd, int targetFd, int32_t bitrate)
{
    const WavInfo wav = ParseWav(sourceFd);
    if (bitrate < 32000 || bitrate > 512000) {
        throw std::runtime_error("AAC bitrate must be between 32000 and 512000");
    }
    if (ftruncate(targetFd, 0) != 0 || lseek(targetFd, 0, SEEK_SET) < 0) {
        throw std::runtime_error("Target file reset failed");
    }

    OH_AVCodec *codec = nullptr;
    OH_AVMuxer *muxer = nullptr;
    bool codecStarted = false;
    bool muxerStarted = false;
    try {
        codec = OH_AudioCodec_CreateByMime(OH_AVCODEC_MIMETYPE_AUDIO_AAC, true);
        if (codec == nullptr) {
            throw std::runtime_error("Create AAC encoder failed");
        }

        OH_AVFormat *format = OH_AVFormat_CreateAudioFormat(
            OH_AVCODEC_MIMETYPE_AUDIO_AAC, wav.sampleRate, wav.channels);
        if (format == nullptr) {
            throw std::runtime_error("Create audio format failed");
        }
        try {
            SetFormatLong(format, OH_MD_KEY_BITRATE, bitrate, "Set bitrate");
            SetFormatInt(format, OH_MD_KEY_AUDIO_SAMPLE_FORMAT, SAMPLE_S16LE, "Set sample format");
            SetFormatInt(format, OH_MD_KEY_MAX_INPUT_SIZE, 32768, "Set max input size");
            SetFormatInt(format, OH_MD_KEY_PROFILE, AAC_PROFILE_LC, "Set AAC profile");
            SetFormatInt(format, OH_MD_KEY_AAC_IS_ADTS, 0, "Disable ADTS");
            SetFormatInt(format, OH_MD_KEY_ENABLE_SYNC_MODE, 1, "Enable sync mode");
            CheckCode(OH_AudioCodec_Configure(codec, format), "AudioCodec Configure");
        } catch (...) {
            OH_AVFormat_Destroy(format);
            throw;
        }
        OH_AVFormat_Destroy(format);

        CheckCode(OH_AudioCodec_Prepare(codec), "AudioCodec Prepare");
        muxer = OH_AVMuxer_Create(targetFd, AV_OUTPUT_FORMAT_M4A);
        if (muxer == nullptr) {
            throw std::runtime_error("Create M4A muxer failed");
        }
        CheckCode(OH_AudioCodec_Start(codec), "AudioCodec Start");
        codecStarted = true;

        const int32_t blockAlign = wav.channels * static_cast<int32_t>(sizeof(int16_t));
        int64_t consumed = 0;
        int32_t trackIndex = -1;
        bool inputEos = false;
        bool outputEos = false;
        int32_t idleRounds = 0;

        while (!outputEos) {
            bool progressed = false;
            if (!inputEos) {
                uint32_t inputIndex = 0;
                const OH_AVErrCode inputResult = OH_AudioCodec_QueryInputBuffer(codec, &inputIndex, 10000);
                if (inputResult == AV_ERR_OK) {
                    OH_AVBuffer *inputBuffer = OH_AudioCodec_GetInputBuffer(codec, inputIndex);
                    if (inputBuffer == nullptr) {
                        throw std::runtime_error("GetInputBuffer returned null");
                    }
                    const int32_t capacity = OH_AVBuffer_GetCapacity(inputBuffer);
                    uint8_t *address = OH_AVBuffer_GetAddr(inputBuffer);
                    if (capacity < blockAlign || address == nullptr) {
                        throw std::runtime_error("Input buffer is invalid");
                    }

                    OH_AVCodecBufferAttr attr {};
                    attr.offset = 0;
                    attr.pts = (consumed / blockAlign) * 1000000LL / wav.sampleRate;
                    const int64_t remaining = wav.dataSize - consumed;
                    if (remaining <= 0) {
                        attr.size = 0;
                        attr.flags = AVCODEC_BUFFER_FLAGS_EOS;
                        inputEos = true;
                    } else {
                        int32_t bytesToRead = static_cast<int32_t>(
                            std::min<int64_t>(remaining, capacity));
                        bytesToRead -= bytesToRead % blockAlign;
                        if (bytesToRead <= 0) {
                            throw std::runtime_error("Input buffer cannot hold a PCM frame");
                        }
                        ReadExact(sourceFd, wav.dataOffset + consumed, address,
                            static_cast<size_t>(bytesToRead), "Read PCM data");
                        attr.size = bytesToRead;
                        attr.flags = AVCODEC_BUFFER_FLAGS_NONE;
                        consumed += bytesToRead;
                    }
                    CheckCode(OH_AVBuffer_SetBufferAttr(inputBuffer, &attr), "Set input buffer attributes");
                    CheckCode(OH_AudioCodec_PushInputBuffer(codec, inputIndex), "Push input buffer");
                    progressed = true;
                } else if (inputResult != AV_ERR_TRY_AGAIN_LATER) {
                    CheckCode(inputResult, "Query input buffer");
                }
            }

            uint32_t outputIndex = 0;
            const OH_AVErrCode outputResult = OH_AudioCodec_QueryOutputBuffer(codec, &outputIndex, 10000);
            if (outputResult == AV_ERR_STREAM_CHANGED) {
                StartMuxerFromCodec(codec, muxer, trackIndex, muxerStarted);
                progressed = true;
            } else if (outputResult == AV_ERR_OK) {
                OH_AVBuffer *outputBuffer = OH_AudioCodec_GetOutputBuffer(codec, outputIndex);
                if (outputBuffer == nullptr) {
                    throw std::runtime_error("GetOutputBuffer returned null");
                }
                OH_AVCodecBufferAttr attr {};
                CheckCode(OH_AVBuffer_GetBufferAttr(outputBuffer, &attr), "Get output buffer attributes");
                StartMuxerFromCodec(codec, muxer, trackIndex, muxerStarted);
                OH_AVErrCode writeResult = AV_ERR_OK;
                if (attr.size > 0 && (attr.flags & AVCODEC_BUFFER_FLAGS_CODEC_DATA) == 0) {
                    writeResult = OH_AVMuxer_WriteSampleBuffer(
                        muxer, static_cast<uint32_t>(trackIndex), outputBuffer);
                }
                const OH_AVErrCode freeResult = OH_AudioCodec_FreeOutputBuffer(codec, outputIndex);
                CheckCode(writeResult, "AVMuxer WriteSampleBuffer");
                CheckCode(freeResult, "Free output buffer");
                outputEos = (attr.flags & AVCODEC_BUFFER_FLAGS_EOS) != 0;
                progressed = true;
            } else if (outputResult != AV_ERR_TRY_AGAIN_LATER) {
                CheckCode(outputResult, "Query output buffer");
            }

            idleRounds = progressed ? 0 : idleRounds + 1;
            if (idleRounds > 1000) {
                throw std::runtime_error("Audio encoder timed out");
            }
        }

        CheckCode(OH_AudioCodec_Stop(codec), "AudioCodec Stop");
        codecStarted = false;
        CheckCode(OH_AVMuxer_Stop(muxer), "AVMuxer Stop");
        muxerStarted = false;
        CheckCode(OH_AVMuxer_Destroy(muxer), "AVMuxer Destroy");
        muxer = nullptr;
        CheckCode(OH_AudioCodec_Destroy(codec), "AudioCodec Destroy");
        codec = nullptr;
    } catch (...) {
        if (codecStarted && codec != nullptr) {
            OH_AudioCodec_Stop(codec);
        }
        if (muxerStarted && muxer != nullptr) {
            OH_AVMuxer_Stop(muxer);
        }
        if (muxer != nullptr) {
            OH_AVMuxer_Destroy(muxer);
        }
        if (codec != nullptr) {
            OH_AudioCodec_Destroy(codec);
        }
        ftruncate(targetFd, 0);
        throw;
    }
}

void ExtractMp4AudioToM4a(int sourceFd, int64_t sourceSize, int targetFd)
{
    if (sourceFd < 0 || targetFd < 0 || sourceSize <= 0) {
        throw std::runtime_error("Invalid source or target file");
    }
    if (ftruncate(targetFd, 0) != 0 || lseek(targetFd, 0, SEEK_SET) < 0) {
        throw std::runtime_error("Target file reset failed");
    }

    OH_AVSource *source = nullptr;
    OH_AVDemuxer *demuxer = nullptr;
    OH_AVMuxer *muxer = nullptr;
    OH_AVBuffer *sample = nullptr;
    OH_AVFormat *audioFormat = nullptr;
    bool muxerStarted = false;
    try {
        source = OH_AVSource_CreateWithFD(sourceFd, 0, sourceSize);
        if (source == nullptr) {
            throw std::runtime_error("Open MP4 source failed");
        }
        demuxer = OH_AVDemuxer_CreateWithSource(source);
        if (demuxer == nullptr) {
            throw std::runtime_error("Create MP4 demuxer failed");
        }

        OH_AVFormat *sourceFormat = OH_AVSource_GetSourceFormat(source);
        if (sourceFormat == nullptr) {
            throw std::runtime_error("Read MP4 source format failed");
        }
        int32_t trackCount = 0;
        const bool hasTrackCount = OH_AVFormat_GetIntValue(sourceFormat, OH_MD_KEY_TRACK_COUNT, &trackCount);
        OH_AVFormat_Destroy(sourceFormat);
        if (!hasTrackCount || trackCount <= 0) {
            throw std::runtime_error("MP4 source has no tracks");
        }

        int32_t audioTrack = -1;
        for (int32_t i = 0; i < trackCount; ++i) {
            OH_AVFormat *trackFormat = OH_AVSource_GetTrackFormat(source, static_cast<uint32_t>(i));
            if (trackFormat == nullptr) {
                continue;
            }
            const char *mime = nullptr;
            if (OH_AVFormat_GetStringValue(trackFormat, OH_MD_KEY_CODEC_MIME, &mime) && mime != nullptr &&
                std::strcmp(mime, OH_AVCODEC_MIMETYPE_AUDIO_AAC) == 0) {
                audioTrack = i;
                audioFormat = trackFormat;
                break;
            }
            OH_AVFormat_Destroy(trackFormat);
        }
        if (audioTrack < 0 || audioFormat == nullptr) {
            throw std::runtime_error("No AAC audio track found");
        }

        muxer = OH_AVMuxer_Create(targetFd, AV_OUTPUT_FORMAT_M4A);
        if (muxer == nullptr) {
            throw std::runtime_error("Create M4A muxer failed");
        }
        int32_t outputTrack = -1;
        CheckCode(OH_AVMuxer_AddTrack(muxer, &outputTrack, audioFormat), "AVMuxer AddTrack");
        OH_AVFormat_Destroy(audioFormat);
        audioFormat = nullptr;
        CheckCode(OH_AVDemuxer_SelectTrackByID(demuxer, static_cast<uint32_t>(audioTrack)),
            "AVDemuxer SelectTrack");
        CheckCode(OH_AVMuxer_Start(muxer), "AVMuxer Start");
        muxerStarted = true;

        sample = OH_AVBuffer_Create(4 * 1024 * 1024);
        if (sample == nullptr) {
            throw std::runtime_error("Create demuxer sample buffer failed");
        }
        while (true) {
            CheckCode(OH_AVDemuxer_ReadSampleBuffer(
                demuxer, static_cast<uint32_t>(audioTrack), sample), "AVDemuxer ReadSampleBuffer");
            OH_AVCodecBufferAttr attr {};
            CheckCode(OH_AVBuffer_GetBufferAttr(sample, &attr), "Get sample attributes");
            if ((attr.flags & AVCODEC_BUFFER_FLAGS_EOS) != 0) {
                break;
            }
            if (attr.size > 0) {
                CheckCode(OH_AVMuxer_WriteSampleBuffer(
                    muxer, static_cast<uint32_t>(outputTrack), sample), "AVMuxer WriteSampleBuffer");
            }
        }

        CheckCode(OH_AVMuxer_Stop(muxer), "AVMuxer Stop");
        muxerStarted = false;
        CheckCode(OH_AVBuffer_Destroy(sample), "AVBuffer Destroy");
        sample = nullptr;
        CheckCode(OH_AVMuxer_Destroy(muxer), "AVMuxer Destroy");
        muxer = nullptr;
        CheckCode(OH_AVDemuxer_Destroy(demuxer), "AVDemuxer Destroy");
        demuxer = nullptr;
        CheckCode(OH_AVSource_Destroy(source), "AVSource Destroy");
        source = nullptr;
    } catch (...) {
        if (audioFormat != nullptr) {
            OH_AVFormat_Destroy(audioFormat);
        }
        if (sample != nullptr) {
            OH_AVBuffer_Destroy(sample);
        }
        if (muxerStarted && muxer != nullptr) {
            OH_AVMuxer_Stop(muxer);
        }
        if (muxer != nullptr) {
            OH_AVMuxer_Destroy(muxer);
        }
        if (demuxer != nullptr) {
            OH_AVDemuxer_Destroy(demuxer);
        }
        if (source != nullptr) {
            OH_AVSource_Destroy(source);
        }
        ftruncate(targetFd, 0);
        throw;
    }
}

void RemuxMovToMp4(int sourceFd, int64_t sourceSize, int targetFd)
{
    if (sourceFd < 0 || targetFd < 0 || sourceSize <= 0) {
        throw std::runtime_error("Invalid source or target file");
    }
    if (ftruncate(targetFd, 0) != 0 || lseek(targetFd, 0, SEEK_SET) < 0) {
        throw std::runtime_error("Target file reset failed");
    }

    OH_AVSource *source = nullptr;
    OH_AVDemuxer *demuxer = nullptr;
    OH_AVMuxer *muxer = nullptr;
    std::vector<RemuxTrack> tracks;
    bool muxerStarted = false;
    try {
        source = OH_AVSource_CreateWithFD(sourceFd, 0, sourceSize);
        if (source == nullptr) {
            throw std::runtime_error("Open MOV source failed");
        }
        demuxer = OH_AVDemuxer_CreateWithSource(source);
        if (demuxer == nullptr) {
            throw std::runtime_error("Create MOV demuxer failed");
        }

        OH_AVFormat *sourceFormat = OH_AVSource_GetSourceFormat(source);
        if (sourceFormat == nullptr) {
            throw std::runtime_error("Read MOV source format failed");
        }
        int32_t trackCount = 0;
        const bool hasTrackCount = OH_AVFormat_GetIntValue(sourceFormat, OH_MD_KEY_TRACK_COUNT, &trackCount);
        OH_AVFormat_Destroy(sourceFormat);
        if (!hasTrackCount || trackCount <= 0) {
            throw std::runtime_error("MOV source has no tracks");
        }

        muxer = OH_AVMuxer_Create(targetFd, AV_OUTPUT_FORMAT_MPEG_4);
        if (muxer == nullptr) {
            throw std::runtime_error("Create MP4 muxer failed");
        }

        bool hasVideo = false;
        for (int32_t i = 0; i < trackCount; ++i) {
            OH_AVFormat *trackFormat = OH_AVSource_GetTrackFormat(source, static_cast<uint32_t>(i));
            if (trackFormat == nullptr) {
                continue;
            }
            const char *mime = nullptr;
            const bool hasMime = OH_AVFormat_GetStringValue(trackFormat, OH_MD_KEY_CODEC_MIME, &mime);
            if (!hasMime || mime == nullptr) {
                OH_AVFormat_Destroy(trackFormat);
                continue;
            }

            const bool isVideo = std::strncmp(mime, "video/", 6) == 0;
            const bool isAudio = std::strncmp(mime, "audio/", 6) == 0;
            const bool supportedVideo = std::strcmp(mime, OH_AVCODEC_MIMETYPE_VIDEO_AVC) == 0;
            const bool supportedAudio = std::strcmp(mime, OH_AVCODEC_MIMETYPE_AUDIO_AAC) == 0;
            if ((isVideo && !supportedVideo) || (isAudio && !supportedAudio)) {
                const std::string unsupportedMime(mime);
                OH_AVFormat_Destroy(trackFormat);
                throw std::runtime_error("MOV track codec is not supported for lossless MP4 remux: " +
                    unsupportedMime);
            }
            if (!supportedVideo && !supportedAudio) {
                OH_AVFormat_Destroy(trackFormat);
                continue;
            }

            RemuxTrack track;
            track.sourceIndex = static_cast<uint32_t>(i);
            CheckCode(OH_AVMuxer_AddTrack(muxer, &track.outputIndex, trackFormat), "AVMuxer AddTrack");
            OH_AVFormat_Destroy(trackFormat);
            CheckCode(OH_AVDemuxer_SelectTrackByID(demuxer, track.sourceIndex), "AVDemuxer SelectTrack");
            hasVideo = hasVideo || supportedVideo;
            tracks.push_back(track);
        }
        if (!hasVideo) {
            throw std::runtime_error("MOV source has no H.264 video track");
        }

        CheckCode(OH_AVMuxer_Start(muxer), "AVMuxer Start");
        muxerStarted = true;
        for (auto &track : tracks) {
            track.sample = OH_AVBuffer_Create(8 * 1024 * 1024);
            if (track.sample == nullptr) {
                throw std::runtime_error("Create remux sample buffer failed");
            }
            CheckCode(OH_AVDemuxer_ReadSampleBuffer(demuxer, track.sourceIndex, track.sample),
                "AVDemuxer ReadSampleBuffer");
            CheckCode(OH_AVBuffer_GetBufferAttr(track.sample, &track.attr), "Get sample attributes");
            track.eos = (track.attr.flags & AVCODEC_BUFFER_FLAGS_EOS) != 0;
        }

        while (true) {
            RemuxTrack *next = nullptr;
            for (auto &track : tracks) {
                if (!track.eos && (next == nullptr || track.attr.pts < next->attr.pts)) {
                    next = &track;
                }
            }
            if (next == nullptr) {
                break;
            }
            if (next->attr.size > 0) {
                CheckCode(OH_AVMuxer_WriteSampleBuffer(
                    muxer, static_cast<uint32_t>(next->outputIndex), next->sample),
                    "AVMuxer WriteSampleBuffer");
            }
            CheckCode(OH_AVDemuxer_ReadSampleBuffer(demuxer, next->sourceIndex, next->sample),
                "AVDemuxer ReadSampleBuffer");
            CheckCode(OH_AVBuffer_GetBufferAttr(next->sample, &next->attr), "Get sample attributes");
            next->eos = (next->attr.flags & AVCODEC_BUFFER_FLAGS_EOS) != 0;
        }

        CheckCode(OH_AVMuxer_Stop(muxer), "AVMuxer Stop");
        muxerStarted = false;
        for (auto &track : tracks) {
            CheckCode(OH_AVBuffer_Destroy(track.sample), "AVBuffer Destroy");
            track.sample = nullptr;
        }
        CheckCode(OH_AVMuxer_Destroy(muxer), "AVMuxer Destroy");
        muxer = nullptr;
        CheckCode(OH_AVDemuxer_Destroy(demuxer), "AVDemuxer Destroy");
        demuxer = nullptr;
        CheckCode(OH_AVSource_Destroy(source), "AVSource Destroy");
        source = nullptr;
    } catch (...) {
        for (auto &track : tracks) {
            if (track.sample != nullptr) {
                OH_AVBuffer_Destroy(track.sample);
            }
        }
        if (muxerStarted && muxer != nullptr) {
            OH_AVMuxer_Stop(muxer);
        }
        if (muxer != nullptr) {
            OH_AVMuxer_Destroy(muxer);
        }
        if (demuxer != nullptr) {
            OH_AVDemuxer_Destroy(demuxer);
        }
        if (source != nullptr) {
            OH_AVSource_Destroy(source);
        }
        ftruncate(targetFd, 0);
        throw;
    }
}

void ExecuteConvert(napi_env, void *data)
{
    auto *work = static_cast<ConvertWork *>(data);
    try {
        ConvertWavToM4a(work->sourceFd, work->targetFd, work->bitrate);
    } catch (const std::exception &error) {
        work->error = error.what();
    } catch (...) {
        work->error = "Unknown native audio conversion error";
    }
}

void CompleteConvert(napi_env env, napi_status status, void *data)
{
    auto *work = static_cast<ConvertWork *>(data);
    if (status != napi_ok && work->error.empty()) {
        work->error = "Native async work failed";
    }
    if (work->error.empty()) {
        napi_value undefinedValue = nullptr;
        napi_get_undefined(env, &undefinedValue);
        napi_resolve_deferred(env, work->deferred, undefinedValue);
    } else {
        napi_value message = nullptr;
        napi_value error = nullptr;
        napi_create_string_utf8(env, work->error.c_str(), NAPI_AUTO_LENGTH, &message);
        napi_create_error(env, nullptr, message, &error);
        napi_reject_deferred(env, work->deferred, error);
    }
    napi_delete_async_work(env, work->asyncWork);
    delete work;
}

napi_value ConvertWavToM4aAsync(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value argv[3] {};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    if (argc != 3) {
        napi_throw_type_error(env, nullptr, "sourceFd, targetFd and bitrate are required");
        return nullptr;
    }

    auto *work = new ConvertWork();
    work->env = env;
    if (napi_get_value_int32(env, argv[0], &work->sourceFd) != napi_ok ||
        napi_get_value_int32(env, argv[1], &work->targetFd) != napi_ok ||
        napi_get_value_int32(env, argv[2], &work->bitrate) != napi_ok) {
        delete work;
        napi_throw_type_error(env, nullptr, "sourceFd, targetFd and bitrate must be numbers");
        return nullptr;
    }

    napi_value promise = nullptr;
    napi_value resourceName = nullptr;
    napi_create_promise(env, &work->deferred, &promise);
    napi_create_string_utf8(env, "convertWavToM4a", NAPI_AUTO_LENGTH, &resourceName);
    if (napi_create_async_work(env, nullptr, resourceName, ExecuteConvert, CompleteConvert,
        work, &work->asyncWork) != napi_ok || napi_queue_async_work(env, work->asyncWork) != napi_ok) {
        if (work->asyncWork != nullptr) {
            napi_delete_async_work(env, work->asyncWork);
        }
        delete work;
        napi_throw_error(env, nullptr, "Unable to queue native audio conversion");
        return nullptr;
    }
    return promise;
}

void ExecuteExtract(napi_env, void *data)
{
    auto *work = static_cast<ExtractWork *>(data);
    try {
        ExtractMp4AudioToM4a(work->sourceFd, work->sourceSize, work->targetFd);
    } catch (const std::exception &error) {
        work->error = error.what();
    } catch (...) {
        work->error = "Unknown native audio extraction error";
    }
}

void CompleteExtract(napi_env env, napi_status status, void *data)
{
    auto *work = static_cast<ExtractWork *>(data);
    if (status != napi_ok && work->error.empty()) {
        work->error = "Native async work failed";
    }
    if (work->error.empty()) {
        napi_value undefinedValue = nullptr;
        napi_get_undefined(env, &undefinedValue);
        napi_resolve_deferred(env, work->deferred, undefinedValue);
    } else {
        napi_value message = nullptr;
        napi_value error = nullptr;
        napi_create_string_utf8(env, work->error.c_str(), NAPI_AUTO_LENGTH, &message);
        napi_create_error(env, nullptr, message, &error);
        napi_reject_deferred(env, work->deferred, error);
    }
    napi_delete_async_work(env, work->asyncWork);
    delete work;
}

napi_value ExtractMp4AudioToM4aAsync(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value argv[3] {};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    if (argc != 3) {
        napi_throw_type_error(env, nullptr, "sourceFd, sourceSize and targetFd are required");
        return nullptr;
    }

    auto *work = new ExtractWork();
    if (napi_get_value_int32(env, argv[0], &work->sourceFd) != napi_ok ||
        napi_get_value_int64(env, argv[1], &work->sourceSize) != napi_ok ||
        napi_get_value_int32(env, argv[2], &work->targetFd) != napi_ok) {
        delete work;
        napi_throw_type_error(env, nullptr, "sourceFd, sourceSize and targetFd must be numbers");
        return nullptr;
    }

    napi_value promise = nullptr;
    napi_value resourceName = nullptr;
    napi_create_promise(env, &work->deferred, &promise);
    napi_create_string_utf8(env, "extractMp4AudioToM4a", NAPI_AUTO_LENGTH, &resourceName);
    if (napi_create_async_work(env, nullptr, resourceName, ExecuteExtract, CompleteExtract,
        work, &work->asyncWork) != napi_ok || napi_queue_async_work(env, work->asyncWork) != napi_ok) {
        if (work->asyncWork != nullptr) {
            napi_delete_async_work(env, work->asyncWork);
        }
        delete work;
        napi_throw_error(env, nullptr, "Unable to queue native audio extraction");
        return nullptr;
    }
    return promise;
}

void ExecuteRemux(napi_env, void *data)
{
    auto *work = static_cast<ExtractWork *>(data);
    try {
        RemuxMovToMp4(work->sourceFd, work->sourceSize, work->targetFd);
    } catch (const std::exception &error) {
        work->error = error.what();
    } catch (...) {
        work->error = "Unknown native video remux error";
    }
}

napi_value RemuxMovToMp4Async(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value argv[3] {};
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    if (argc != 3) {
        napi_throw_type_error(env, nullptr, "sourceFd, sourceSize and targetFd are required");
        return nullptr;
    }

    auto *work = new ExtractWork();
    if (napi_get_value_int32(env, argv[0], &work->sourceFd) != napi_ok ||
        napi_get_value_int64(env, argv[1], &work->sourceSize) != napi_ok ||
        napi_get_value_int32(env, argv[2], &work->targetFd) != napi_ok) {
        delete work;
        napi_throw_type_error(env, nullptr, "sourceFd, sourceSize and targetFd must be numbers");
        return nullptr;
    }

    napi_value promise = nullptr;
    napi_value resourceName = nullptr;
    napi_create_promise(env, &work->deferred, &promise);
    napi_create_string_utf8(env, "remuxMovToMp4", NAPI_AUTO_LENGTH, &resourceName);
    if (napi_create_async_work(env, nullptr, resourceName, ExecuteRemux, CompleteExtract,
        work, &work->asyncWork) != napi_ok || napi_queue_async_work(env, work->asyncWork) != napi_ok) {
        if (work->asyncWork != nullptr) {
            napi_delete_async_work(env, work->asyncWork);
        }
        delete work;
        napi_throw_error(env, nullptr, "Unable to queue native video remux");
        return nullptr;
    }
    return promise;
}

napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor properties[] = {
        {"convertWavToM4a", nullptr, ConvertWavToM4aAsync, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"extractMp4AudioToM4a", nullptr, ExtractMp4AudioToM4aAsync,
            nullptr, nullptr, nullptr, napi_default, nullptr},
        {"remuxMovToMp4", nullptr, RemuxMovToMp4Async, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(properties) / sizeof(properties[0]), properties);
    return exports;
}

} // namespace

NAPI_MODULE(native_audio, Init)
