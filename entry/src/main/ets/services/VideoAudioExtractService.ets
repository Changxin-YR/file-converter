import nativeAudio from 'libnative_audio.so'
import { fileIo as fs } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ConvertResult } from '../common/ConvertTask'
import { FileUtils } from '../common/Utils'

export class VideoAudioExtractService {
  async extract(sourceUri: string, targetPath: string): Promise<ConvertResult> {
    if (FileUtils.getExtension(sourceUri) !== 'mp4') {
      return { success: false, errorMsg: '当前音轨提取仅支持 MP4 文件' }
    }

    let sourceFile: fs.File | null = null
    let targetFile: fs.File | null = null
    let success = false
    try {
      sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY)
      const sourceSize: number = fs.statSync(sourceFile.fd).size
      targetFile = fs.openSync(targetPath,
        fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.READ_WRITE)
      await nativeAudio.extractMp4AudioToM4a(sourceFile.fd, sourceSize, targetFile.fd)
      success = true
      return { success: true, targetPath }
    } catch (e) {
      const err = e as BusinessError
      return { success: false, errorMsg: `M4A 音轨提取失败：${err.message}` }
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
