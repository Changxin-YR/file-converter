/**
 * Audio conversion service.
 * API 22's AVTranscoder cannot prepare a header-only PCM WAV source reliably,
 * so WAV to M4A is handled by the synchronous native AudioCodec API.
 */
import nativeAudio from 'libnative_audio.so'
import { fileIo as fs } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ConvertOptions, ConvertResult } from '../common/ConvertTask'
import { FileUtils } from '../common/Utils'

export class AudioConvertService {
  async convertAudio(
    sourceUri: string,
    targetPath: string,
    targetFormat: string,
    options?: ConvertOptions
  ): Promise<ConvertResult> {
    if (FileUtils.getExtension(sourceUri) !== 'wav' || targetFormat.toLowerCase() !== 'm4a') {
      return { success: false, errorMsg: '当前原生音频转换仅支持 PCM WAV 转 M4A' }
    }

    let sourceFile: fs.File | null = null
    let targetFile: fs.File | null = null
    let success = false
    try {
      sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY)
      targetFile = fs.openSync(targetPath,
        fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.READ_WRITE)
      await nativeAudio.convertWavToM4a(
        sourceFile.fd,
        targetFile.fd,
        options?.audioBitrate ?? 128000
      )
      success = true
      return { success: true, targetPath }
    } catch (e) {
      const err = e as BusinessError
      return { success: false, errorMsg: `音频转换失败：${err.message}` }
    } finally {
      if (sourceFile) {
        fs.closeSync(sourceFile)
      }
      if (targetFile) {
        fs.closeSync(targetFile)
      }
      if (!success) {
        try {
          fs.unlinkSync(targetPath)
        } catch (_e) {
          // The target may not have been created yet.
        }
      }
    }
  }
}
