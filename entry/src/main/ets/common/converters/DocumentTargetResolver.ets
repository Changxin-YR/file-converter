import { ConvertType } from '../ConvertTask'
import { FormatInfo } from '../FormatTypes'
import { DocumentMatrix } from './DocumentMatrix'

const EXPORT_FORMATS: FormatInfo[] = [
  { extension: 'pdf', mimeType: 'application/pdf', displayName: 'PDF', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'doc', mimeType: 'application/msword', displayName: 'Word', category: ConvertType.DOCUMENT, nativeSupported: true }
]

const MATRIX_FORMATS: FormatInfo[] = [
  { extension: 'json', mimeType: 'application/json', displayName: 'JSON', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'xml', mimeType: 'text/xml', displayName: 'XML', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'md', mimeType: 'text/markdown', displayName: 'MD', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'html', mimeType: 'text/html', displayName: 'HTML', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'csv', mimeType: 'text/csv', displayName: 'CSV', category: ConvertType.DOCUMENT, nativeSupported: true },
  { extension: 'txt', mimeType: 'text/plain', displayName: 'TXT', category: ConvertType.DOCUMENT, nativeSupported: true }
]

export class DocumentTargetResolver {
  static resolve(sourceExtensions: string[]): FormatInfo[] {
    const targets: FormatInfo[] = [...EXPORT_FORMATS]
    if (sourceExtensions.length === 0) {
      targets.push(...MATRIX_FORMATS)
      return targets
    }
    for (const target of MATRIX_FORMATS) {
      let supported = true
      for (const source of sourceExtensions) {
        if (!DocumentMatrix.isConvertible(source, target.extension)) {
          supported = false
          break
        }
      }
      if (supported) {
        targets.push(target)
      }
    }
    return targets
  }
}
