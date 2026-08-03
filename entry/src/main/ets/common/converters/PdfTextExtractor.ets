export interface PdfTextExtractResult {
  success: boolean
  text: string
  errorMsg?: string
}

interface LiteralDecodeResult {
  value: string
  end: number
  closed: boolean
}

export class PdfTextExtractor {
  static extract(buffer: ArrayBuffer): PdfTextExtractResult {
    const raw = PdfTextExtractor.toBinaryString(buffer)
    if (!raw.startsWith('%PDF-')) {
      return { success: false, text: '', errorMsg: '文件不是有效的 PDF' }
    }
    if (raw.includes('/Encrypt')) {
      return { success: false, text: '', errorMsg: '不支持加密 PDF' }
    }
    if (raw.includes('/ObjStm')) {
      return { success: false, text: '', errorMsg: '不支持对象流 PDF' }
    }
    if (raw.includes('/Filter')) {
      return { success: false, text: '', errorMsg: '当前仅支持项目自产的未压缩文本 PDF' }
    }

    const parts: string[] = []
    const blockPattern = /BT[\s\S]*?ET/g
    let blockMatch: RegExpExecArray | null = blockPattern.exec(raw)
    while (blockMatch !== null) {
      PdfTextExtractor.extractBlock(blockMatch[0], parts)
      blockMatch = blockPattern.exec(raw)
    }
    if (parts.length === 0) {
      return { success: false, text: '', errorMsg: 'PDF 中没有可提取的文本内容' }
    }
    return { success: true, text: parts.join('\n') }
  }

  private static toBinaryString(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer)
    const chunks: string[] = []
    const chunkSize = 8192
    for (let offset = 0; offset < bytes.length; offset += chunkSize) {
      const end = Math.min(offset + chunkSize, bytes.length)
      let chunk = ''
      for (let index = offset; index < end; index++) {
        chunk += String.fromCharCode(bytes[index])
      }
      chunks.push(chunk)
    }
    return chunks.join('')
  }

  private static extractBlock(block: string, parts: string[]): void {
    let index = 0
    while (index < block.length) {
      const current = block.charAt(index)
      if (current === '(') {
        const decoded = PdfTextExtractor.decodeLiteral(block, index + 1)
        if (!decoded.closed) {
          return
        }
        if (PdfTextExtractor.isTjOperator(block, decoded.end + 1)) {
          parts.push(decoded.value)
        }
        index = decoded.end + 1
      } else if (current === '<' && block.charAt(index + 1) !== '<') {
        const end = block.indexOf('>', index + 1)
        if (end < 0) {
          return
        }
        if (PdfTextExtractor.isTjOperator(block, end + 1)) {
          const value = PdfTextExtractor.decodeUtf16BeHex(block.slice(index + 1, end))
          if (value.length > 0) {
            parts.push(value)
          }
        }
        index = end + 1
      } else {
        index++
      }
    }
  }

  private static isTjOperator(block: string, start: number): boolean {
    let index = start
    while (index < block.length && /\s/.test(block.charAt(index))) {
      index++
    }
    return block.slice(index, index + 2) === 'Tj'
  }

  private static decodeLiteral(block: string, start: number): LiteralDecodeResult {
    let value = ''
    let index = start
    let depth = 1
    while (index < block.length) {
      const current = block.charAt(index)
      if (current === '\\') {
        index++
        if (index >= block.length) {
          return { value, end: index, closed: false }
        }
        const escaped = block.charAt(index)
        if (escaped === 'n') {
          value += '\n'
        } else if (escaped === 'r') {
          value += '\r'
        } else if (escaped === 't') {
          value += '\t'
        } else if (escaped === 'b') {
          value += '\b'
        } else if (escaped === 'f') {
          value += '\f'
        } else if (escaped === '\n') {
          // A backslash followed by a line break is a PDF line continuation.
        } else if (escaped === '\r') {
          if (block.charAt(index + 1) === '\n') {
            index++
          }
        } else {
          value += escaped
        }
      } else if (current === '(') {
        depth++
        value += current
      } else if (current === ')') {
        depth--
        if (depth === 0) {
          return { value, end: index, closed: true }
        }
        value += current
      } else {
        value += current
      }
      index++
    }
    return { value, end: index, closed: false }
  }

  private static decodeUtf16BeHex(rawHex: string): string {
    const hex = rawHex.replace(/\s/g, '').toUpperCase()
    if (!hex.startsWith('FEFF') || hex.length < 8 || hex.length % 4 !== 0) {
      return ''
    }
    let value = ''
    for (let index = 4; index < hex.length; index += 4) {
      const code = parseInt(hex.slice(index, index + 4), 16)
      if (Number.isNaN(code)) {
        return ''
      }
      value += String.fromCharCode(code)
    }
    return value
  }
}
