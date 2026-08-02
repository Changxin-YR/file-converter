/**
 * PDF 生成器
 * 离线生成 PDF 文件,将纯文本/Markdown 渲染为 PDF 格式。
 * 不依赖网络,不依赖三方库,手动构建 PDF 1.4 结构。
 * 支持中文（通过 CIDFont + UTF-16BE 编码）。
 */
export interface PdfImageData {
  jpegBytes: ArrayBuffer
  width: number
  height: number
}

export class PdfGenerator {
  static generate(text: string, title: string = ''): ArrayBuffer {
    const lines = PdfGenerator.wrapText(text, 38)
    const pageLines = 42
    const pages: string[][] = []
    for (let i = 0; i < lines.length; i += pageLines) {
      pages.push(lines.slice(i, i + pageLines))
    }
    if (pages.length === 0) {
      pages.push([''])
    }

    const objects: string[] = []
    let objNum = 0

    const addObj = (content: string): number => {
      objNum++
      objects.push(`${objNum} 0 obj\n${content}\nendobj\n`)
      return objNum
    }

    // Obj 1: Catalog
    addObj('<< /Type /Catalog /Pages 2 0 R >>')

    // Obj 2: Pages placeholder
    addObj('')

    // Obj 3: CIDFont for Chinese support (STSong-Light)
    addObj('<< /Type /Font /Subtype /Type0 /BaseFont /STSong-Light ' +
      '/Encoding /UniGB-UTF16-H /DescendantFonts [4 0 R] >>')

    // Obj 4: CIDFont Descendant
    addObj('<< /Type /Font /Subtype /CIDFontType2 /BaseFont /STSong-Light ' +
      '/CIDSystemInfo << /Registry (Adobe) /Ordering (GB1) /Supplement 0 >> ' +
      '/DW 1000 >>')

    // Obj 5: Fallback ASCII font
    addObj('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>')

    // Generate page streams and page objects
    const pageObjIds: number[] = []
    for (const pageContent of pages) {
      const stream = PdfGenerator.buildPageStream(pageContent)
      const streamBytes = PdfGenerator.encodeUtf8(stream)
      const streamObj = addObj(`<< /Length ${streamBytes.length} >>\nstream\n${stream}\nendstream`)
      const pageObj = addObj(
        `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] ` +
        `/Contents ${streamObj} 0 R /Resources << /Font << /F1 3 0 R /F2 5 0 R >> >> >>`
      )
      pageObjIds.push(pageObj)
    }

    // Update Pages object (obj 2)
    const kids = pageObjIds.map((id: number) => `${id} 0 R`).join(' ')
    objects[1] = `2 0 obj\n<< /Type /Pages /Kids [${kids}] /Count ${pageObjIds.length} >>\nendobj\n`

    // Build final PDF - use byte lengths for correct xref offsets
    const header = '%PDF-1.4\n'
    const headerBytes = PdfGenerator.encodeUtf8(header)
    const objectBytes: Uint8Array[] = objects.map((obj: string) => PdfGenerator.encodeUtf8(obj))
    let bodyLen = 0
    const offsets: number[] = []
    for (const objBuf of objectBytes) {
      offsets.push(headerBytes.length + bodyLen)
      bodyLen += objBuf.length
    }

    const xrefOffset = headerBytes.length + bodyLen
    let xref = `xref\n0 ${objNum + 1}\n0000000000 65535 f \n`
    for (const offset of offsets) {
      xref += PdfGenerator.padNumber(offset) + ' 00000 n \n'
    }
    const trailer = `trailer\n<< /Size ${objNum + 1} /Root 1 0 R >>\n` +
      `startxref\n${xrefOffset}\n%%EOF\n`

    const xrefTrailerBytes = PdfGenerator.encodeUtf8(xref + trailer)
    const totalLen = headerBytes.length + bodyLen + xrefTrailerBytes.length
    const result = new Uint8Array(totalLen)
    let pos = 0
    result.set(headerBytes, pos)
    pos += headerBytes.length
    for (const objBuf of objectBytes) {
      result.set(objBuf, pos)
      pos += objBuf.length
    }
    result.set(xrefTrailerBytes, pos)
    return result.buffer as ArrayBuffer
  }

  private static buildPageStream(lines: string[]): string {
    let stream = 'BT\n'
    stream += '50 780 Td\n'
    stream += '13 TL\n'
    for (const line of lines) {
      if (PdfGenerator.hasNonAscii(line)) {
        // 使用 CIDFont (F1) + UTF-16BE hex 编码
        const hex = PdfGenerator.toUtf16BEHex(line)
        stream += `/F1 11 Tf\n<${hex}> Tj T*\n`
      } else {
        // 纯 ASCII 使用 Helvetica (F2)
        const escaped = PdfGenerator.escapePdfString(line)
        stream += `/F2 11 Tf\n(${escaped}) Tj T*\n`
      }
    }
    stream += 'ET'
    return stream
  }

  private static hasNonAscii(text: string): boolean {
    for (let i = 0; i < text.length; i++) {
      if (text.charCodeAt(i) > 127) {
        return true
      }
    }
    return false
  }

  private static toUtf16BEHex(text: string): string {
    let hex = 'FEFF'
    for (let i = 0; i < text.length; i++) {
      const code = text.charCodeAt(i)
      hex += PdfGenerator.toHex4(code)
    }
    return hex
  }

  private static toHex4(n: number): string {
    let h = n.toString(16).toUpperCase()
    while (h.length < 4) {
      h = '0' + h
    }
    return h
  }

  private static wrapText(text: string, maxWidth: number): string[] {
    const rawLines = text.replace(/\r\n/g, '\n').split('\n')
    const wrapped: string[] = []
    for (const rawLine of rawLines) {
      if (rawLine.length <= maxWidth) {
        wrapped.push(rawLine)
      } else {
        let remaining = rawLine
        while (remaining.length > maxWidth) {
          wrapped.push(remaining.substring(0, maxWidth))
          remaining = remaining.substring(maxWidth)
        }
        wrapped.push(remaining)
      }
    }
    return wrapped
  }

  private static escapePdfString(text: string): string {
    let out = ''
    for (let i = 0; i < text.length; i++) {
      const ch = text.charAt(i)
      if (ch === '(' || ch === ')' || ch === '\\') {
        out += '\\' + ch
      } else {
        out += ch
      }
    }
    return out
  }

  private static padNumber(n: number): string {
    let s = n.toString()
    while (s.length < 10) {
      s = '0' + s
    }
    return s
  }

  private static encodeUtf8(str: string): Uint8Array {
    const arr: number[] = []
    for (let i = 0; i < str.length; i++) {
      const code = str.charCodeAt(i)
      if (code < 0x80) {
        arr.push(code)
      } else if (code < 0x800) {
        arr.push(0xC0 | (code >> 6))
        arr.push(0x80 | (code & 0x3F))
      } else {
        arr.push(0xE0 | (code >> 12))
        arr.push(0x80 | ((code >> 6) & 0x3F))
        arr.push(0x80 | (code & 0x3F))
      }
    }
    return new Uint8Array(arr)
  }

  private static encodeUtf8ToBuffer(str: string): ArrayBuffer {
    const bytes = PdfGenerator.encodeUtf8(str)
    return bytes.buffer as ArrayBuffer
  }

  /**
   * 将多张 JPEG 图片生成为 PDF（每张图片一页,A4 居中显示）
   * 采用二进制拼接方式正确嵌入 JPEG 流数据。
   */
  static generateFromImages(images: PdfImageData[]): ArrayBuffer {
    if (images.length === 0) {
      return PdfGenerator.generate('(空)')
    }

    const PAGE_W = 595
    const PAGE_H = 842
    const MARGIN = 36

    const segments: Uint8Array[] = []
    const offsets: number[] = []
    let totalLen = 0
    let objNum = 0

    const appendText = (text: string): void => {
      const bytes = PdfGenerator.encodeUtf8(text)
      segments.push(bytes)
      totalLen += bytes.length
    }

    const appendBinary = (data: Uint8Array): void => {
      segments.push(data)
      totalLen += data.length
    }

    const markOffset = (): void => {
      offsets.push(totalLen)
    }

    appendText('%PDF-1.4\n')

    // Obj 1: Catalog
    objNum = 1
    markOffset()
    appendText('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n')

    // Obj 2: Pages (kids are at obj 5, 8, 11... = 5 + i*3)
    objNum = 2
    markOffset()
    const kidsStr = images.map((_: PdfImageData, idx: number) => `${5 + idx * 3} 0 R`).join(' ')
    appendText(`2 0 obj\n<< /Type /Pages /Kids [${kidsStr}] /Count ${images.length} >>\nendobj\n`)

    for (let i = 0; i < images.length; i++) {
      const img = images[i]
      const imgData = new Uint8Array(img.jpegBytes)

      const maxW = PAGE_W - MARGIN * 2
      const maxH = PAGE_H - MARGIN * 2
      let displayW = img.width
      let displayH = img.height
      if (displayW > maxW) {
        displayH = displayH * maxW / displayW
        displayW = maxW
      }
      if (displayH > maxH) {
        displayW = displayW * maxH / displayH
        displayH = maxH
      }
      const x = (PAGE_W - displayW) / 2
      const y = (PAGE_H - displayH) / 2

      // Image XObject
      objNum++
      const imgObjNum = objNum
      markOffset()
      appendText(`${imgObjNum} 0 obj\n<< /Type /XObject /Subtype /Image /Width ${img.width} /Height ${img.height} ` +
        `/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${imgData.length} >>\nstream\n`)
      appendBinary(imgData)
      appendText('\nendstream\nendobj\n')

      // Page content stream
      objNum++
      const streamObjNum = objNum
      const streamContent = `q ${displayW.toFixed(1)} 0 0 ${displayH.toFixed(1)} ${x.toFixed(1)} ${y.toFixed(1)} cm /Img${i} Do Q`
      const streamLen = PdfGenerator.encodeUtf8(streamContent).length
      markOffset()
      appendText(`${streamObjNum} 0 obj\n<< /Length ${streamLen} >>\nstream\n${streamContent}\nendstream\nendobj\n`)

      // Page
      objNum++
      markOffset()
      appendText(`${objNum} 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${PAGE_W} ${PAGE_H}] ` +
        `/Contents ${streamObjNum} 0 R /Resources << /XObject << /Img${i} ${imgObjNum} 0 R >> >> >>\nendobj\n`)
    }

    // xref
    const xrefOffset = totalLen
    appendText(`xref\n0 ${objNum + 1}\n0000000000 65535 f \n`)
    for (const offset of offsets) {
      appendText(PdfGenerator.padNumber(offset) + ' 00000 n \n')
    }
    appendText(`trailer\n<< /Size ${objNum + 1} /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF\n`)

    const result = new Uint8Array(totalLen)
    let pos = 0
    for (const seg of segments) {
      result.set(seg, pos)
      pos += seg.length
    }
    return result.buffer as ArrayBuffer
  }
}
