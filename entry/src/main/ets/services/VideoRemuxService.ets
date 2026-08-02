import nativeAudio from 'libnative_audio.so'
import { fileIo as fs } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ConvertResult } from '../common/ConvertTask'
import { FileUtils } from '../common/Utils'

export class VideoRemuxService {
  async remux(sourceUri: string, targetPath: string): Promise<ConvertResult> {
    if (FileUtils.getExtension(sourceUri) !== 'mov') {
      return { success: false, errorMsg: '无损重封装仅支持 MOV 输入' }
    }

    let sourceFile: fs.File | null = null
    let targetFile: fs.File | null = null
    let success = false
    try {
      sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY)
      const sourceSize: number = fs.statSync(sourceUri).size
      targetFile = fs.openSync(targetPath,
        fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.READ_WRITE)
      await nativeAudio.remuxMovToMp4(sourceFile.fd, sourceSize, targetFile.fd)
      success = true
      return { success: true, targetPath }
    } catch (e) {
      const err = e as BusinessError
      return {
        success: false,
        errorMsg: `MOV 无损重封装失败，仅支持 H.264 视频和 AAC 音频：${err.message}`
      }
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
