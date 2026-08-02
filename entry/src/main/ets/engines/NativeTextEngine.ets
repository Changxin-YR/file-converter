/**
 * 原生文档转换引擎
 * 基于 DocumentMatrix 实现文本类文档（TXT/CSV/JSON/XML/HTML/MD/LOG）互转,
 * 支持源/目标编码（UTF-8 / UTF-16 / GBK 等）。
 */
import { fileIo as fs } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { IConvertEngine } from './IConvertEngine'
import { ConvertTask, ConvertResult, ConvertType } from '../common/ConvertTask'
import { DocumentMatrix } from '../common/converters/DocumentMatrix'
import { TextCodec } from '../common/converters/TextCodec'

export class NativeTextEngine implements IConvertEngine {
  readonly engineName: string = 'NativeTextEngine'
  readonly nativelySupported: boolean = true

  supports(type: ConvertType, srcExt: string, dstExt: string): boolean {
    if (type !== ConvertType.DOCUMENT) {
      return false
    }
    return DocumentMatrix.isConvertible(srcExt, dstExt)
  }

  async convert(task: ConvertTask, onProgress: (percent: number) => void): Promise<ConvertResult> {
    if (!task.targetPath) {
      return { success: false, errorMsg: '目标路径为空' }
    }
    onProgress(10)
    let sourceFile: fs.File | null = null
    let targetFile: fs.File | null = null
    try {
      // 1. 读取源文件字节
      sourceFile = fs.openSync(task.sourcePath, fs.OpenMode.READ_ONLY)
      const stat = fs.statSync(sourceFile.fd)
      if (stat.size > 10 * 1024 * 1024) {
        return { success: false, errorMsg: '文件过大(超过10MB),请选择较小的文件' }
      }
      const buffer = new ArrayBuffer(stat.size)
      const bytesRead = fs.readSync(sourceFile.fd, buffer)
      onProgress(40)

      // 2. 按源编码解码为文本
      const sourceEncoding = task.options?.sourceEncoding ?? 'utf-8'
      const text = TextCodec.decode(buffer.slice(0, bytesRead), sourceEncoding)
      onProgress(55)

      // 3. 通过转换矩阵执行格式转换
      const outcome = DocumentMatrix.convert(task.sourceFormat, task.targetFormat, text)
      if (!outcome.success || outcome.text === undefined) {
        return { success: false, errorMsg: outcome.error ?? '文档转换失败' }
      }
      onProgress(80)

      // 4. 编码写回（API 22 仅支持 UTF-8 输出）
      const encoded = TextCodec.encode(outcome.text)
      targetFile = fs.openSync(task.targetPath, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY)
      fs.writeSync(targetFile.fd, encoded)
      onProgress(100)

      return { success: true, targetPath: task.targetPath }
    } catch (e) {
      const err = e as BusinessError
      return { success: false, errorMsg: `文档转换失败:${err.message}` }
    } finally {
      if (sourceFile) {
        fs.closeSync(sourceFile)
      }
      if (targetFile) {
        fs.closeSync(targetFile)
      }
    }
  }
}
