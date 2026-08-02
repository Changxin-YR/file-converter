/**
 * 格式类型定义
 * 声明各分类下支持的格式、mimeType 与原生支持度。
 */
import { ConvertType } from './ConvertTask'

export interface FormatInfo {
  extension: string
  mimeType: string
  displayName: string
  category: ConvertType
  /** 是否当前原生可实现（false 表示需三方引擎或灰置） */
  nativeSupported: boolean
}

export const IMAGE_FORMATS: FormatInfo[] = [
  { extension: 'png', mimeType: 'image/png', displayName: 'PNG', category: ConvertType.IMAGE, nativeSupported: true },
  { extension: 'jpg', mimeType: 'image/jpeg', displayName: 'JPG', category: ConvertType.IMAGE, nativeSupported: true },
  { extension: 'webp', mimeType: 'image/webp', displayName: 'WEBP', category: ConvertType.IMAGE, nativeSupported: true },
  { extension: 'bmp', mimeType: 'image/bmp', displayName: 'BMP', category: ConvertType.IMAGE, nativeSupported: true },
  { extension: 'heif', mimeType: 'image/heif', displayName: 'HEIF', category: ConvertType.IMAGE, nativeSupported: false },
  { extension: 'gif', mimeType: 'image/gif', displayName: 'GIF', category: ConvertType.IMAGE, nativeSupported: false }
]

export const DOCUMENT_TEXT_FORMATS: FormatInfo[] = [
  { extension: 'txt', mimeType: 'text/plain', displayName: 'TXT', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'csv', mimeType: 'text/csv', displayName: 'CSV', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'json', mimeType: 'application/json', displayName: 'JSON', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'xml', mimeType: 'text/xml', displayName: 'XML', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'html', mimeType: 'text/html', displayName: 'HTML', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'md', mimeType: 'text/markdown', displayName: 'MD', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'log', mimeType: 'text/plain', displayName: 'LOG', category: ConvertType.DOCUMENT, nativeSupported: true }
]

// 注意:AVTranscoder 官方注释当前仅支持 AAC 编码 + MP4 容器,
// 因此原生可靠输出路径为 AAC → M4A;其余格式作为能力矩阵中的"需验证"项灰置。
export const AUDIO_FORMATS: FormatInfo[] = [
  { extension: 'm4a', mimeType: 'audio/mp4', displayName: 'M4A', category: ConvertType.AUDIO, nativeSupported: true },
  { extension: 'aac', mimeType: 'audio/aac', displayName: 'AAC', category: ConvertType.AUDIO, nativeSupported: false },
  { extension: 'mp3', mimeType: 'audio/mpeg', displayName: 'MP3', category: ConvertType.AUDIO, nativeSupported: false },
  { extension: 'flac', mimeType: 'audio/flac', displayName: 'FLAC', category: ConvertType.AUDIO, nativeSupported: false },
  { extension: 'wav', mimeType: 'audio/wav', displayName: 'WAV', category: ConvertType.AUDIO, nativeSupported: false },
  { extension: 'ogg', mimeType: 'audio/ogg', displayName: 'OGG', category: ConvertType.AUDIO, nativeSupported: false }
]

/** 按扩展名查找格式信息（含大小写归一） */
export function getFormatByExtension(ext: string): FormatInfo | undefined {
  const normalized = ext.toLowerCase()
  const all: FormatInfo[] = [...IMAGE_FORMATS, ...DOCUMENT_TEXT_FORMATS, ...AUDIO_FORMATS]
  for (const format of all) {
    if (format.extension === normalized) {
      return format
    }
  }
  return undefined
}
