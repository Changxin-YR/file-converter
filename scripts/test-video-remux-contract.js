const fs = require('fs')
const path = require('path')

function read(relativePath) {
  const absolutePath = path.join(__dirname, '..', relativePath)
  return fs.existsSync(absolutePath) ? fs.readFileSync(absolutePath, 'utf8') : ''
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message)
  }
}

const nativeSource = read('entry/src/main/cpp/native_audio.cpp')
const nativeTypes = read('entry/src/main/cpp/types/libnative_audio/index.d.ts')
const service = read('entry/src/main/ets/services/VideoRemuxService.ets')
const page = read('entry/src/main/ets/pages/VideoConvertPage.ets')

assert(
  nativeSource.includes('remuxMovToMp4') && nativeTypes.includes('remuxMovToMp4'),
  'The native module must expose MOV to MP4 remuxing'
)
assert(
  nativeSource.includes('OH_AVCODEC_MIMETYPE_VIDEO_AVC') &&
    nativeSource.includes('OH_AVCODEC_MIMETYPE_AUDIO_AAC'),
  'Remuxing must explicitly restrict tracks to H.264 video and AAC audio'
)
assert(
  service.includes("FileUtils.getExtension(sourceUri) !== 'mov'") &&
    service.includes('nativeAudio.remuxMovToMp4'),
  'The ArkTS service must guard the MOV-only native remux path'
)
assert(
  /srcExt\s*===\s*'mov'[\s\S]*?videoRemuxService\.remux/.test(page),
  'The video page must try deterministic MOV remuxing before encoder-based transcoding'
)
assert(
  !service.includes('statSync(sourceUri)') && service.includes('statSync(sourceFile.fd)'),
  'MOV remuxing must stat the opened picker file descriptor'
)

console.log('VIDEO REMUX CONTRACT PASSED')
