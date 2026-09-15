/**
 * 通用工具函数
 * 文件路径解析、任务 ID 生成、文件复制等纯逻辑。
 */
import { fileIo as fs } from '@kit.CoreFileKit'

const COPY_BUFFER_SIZE: number = 64 * 1024

export class FileUtils {
  /** 从路径中取文件名（含扩展名） */
  static getFileName(path: string): string {
    const segments = path.split('/')
    return segments[segments.length - 1]
  }

  /** 取不含扩展名的文件名 */
  static getBaseName(path: string): string {
    const name = FileUtils.getFileName(path)
    const idx = name.lastIndexOf('.')
    return idx > 0 ? name.substring(0, idx) : name
  }

  /** 取文件扩展名（小写，无点） */
  static getExtension(path: string): string {
    const name = FileUtils.getFileName(path)
    const idx = name.lastIndexOf('.')
    return idx > 0 ? name.substring(idx + 1).toLowerCase() : ''
  }

  /**
   * 生成在同一目录中不与已占用名称冲突的文件名。
   * 同名文件按“名称 (2).扩展名”递增，保留原始扩展名。
   */
  static makeUniqueFileName(fileName: string, usedNames: string[]): string {
    const lastDot = fileName.lastIndexOf('.')
    const baseName = lastDot > 0 ? fileName.substring(0, lastDot) : fileName
    const extension = lastDot > 0 ? fileName.substring(lastDot) : ''
    let candidate = fileName
    let suffix = 2
    while (usedNames.includes(candidate)) {
      candidate = `${baseName} (${suffix})${extension}`
      suffix++
    }
    usedNames.push(candidate)
    return candidate
  }

  /** 生成任务唯一 ID */
  static genTaskId(): string {
    return `task_${Date.now()}_${Math.floor(Math.random() * 10000)}`
  }

  /** 比特率转可读文本，如 128000 → '128k' */
  static formatBitrate(bitrate: number): string {
    return `${Math.round(bitrate / 1000)}k`
  }

  /** 复制文件（流式,适用于大文件） */
  static copyFile(sourcePath: string, targetUri: string): boolean {
    let src: fs.File | null = null
    let dst: fs.File | null = null
    try {
      src = fs.openSync(sourcePath, fs.OpenMode.READ_ONLY)
      dst = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY)
      const buffer = new ArrayBuffer(COPY_BUFFER_SIZE)
      while (true) {
        const readCount: number = fs.readSync(src.fd, buffer)
        if (readCount <= 0) {
          break
        }
        fs.writeSync(dst.fd, buffer.slice(0, readCount))
      }
      return true
    } catch (e) {
      return false
    } finally {
      if (src) {
        fs.closeSync(src)
      }
      if (dst) {
        fs.closeSync(dst)
      }
    }
  }
}
