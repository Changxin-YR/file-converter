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
  { extension: 'bmp', mimeType: 'image/bmp', displayName: 'BMP', category: ConvertType.IMAGE, nativeSupported: true }
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

/** 按扩展名查找格式信息（含大小写归一） */
export function getFormatByExtension(ext: string): FormatInfo | undefined {
  const normalized = ext.toLowerCase()
  const all: FormatInfo[] = [...IMAGE_FORMATS, ...DOCUMENT_TEXT_FORMATS]
  for (const format of all) {
    if (format.extension === normalized) {
      return format
    }
  }
  return undefined
}
