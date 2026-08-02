/**
 * Word 文档生成器
 * 离线生成 Word 兼容文件。采用 HTML 格式保存为 .doc,
 * Word / WPS / LibreOffice 均可正常打开。
 * 这是离线环境下最可靠的 Word 兼容方案（无需 ZIP 打包）。
 */
export class WordGenerator {
  /**
   * 将文本内容生成 Word 兼容的 HTML .doc 文件
   * 返回 UTF-8 编码的 ArrayBuffer
   */
  static generate(text: string, title: string = ''): string {
    const docTitle = title.length > 0 ? title : '文档'
    const bodyHtml = WordGenerator.textToHtml(text)
    return WordGenerator.wrapInWordHtml(bodyHtml, docTitle)
  }

  /**
   * 将 Markdown 内容生成 Word 兼容文件
   */
  static generateFromHtml(html: string, title: string = ''): string {
    const docTitle = title.length > 0 ? title : '文档'
    return WordGenerator.wrapInWordHtml(html, docTitle)
  }

  private static textToHtml(text: string): string {
    const paragraphs = text.replace(/\r\n/g, '\n').split(/\n\s*\n/)
    const parts: string[] = []
    for (const para of paragraphs) {
      const escaped = WordGenerator.escapeHtml(para.trim())
      if (escaped.length > 0) {
        const withBreaks = escaped.replace(/\n/g, '<br/>')
        parts.push(`<p style="font-size:12pt;line-height:1.6;">${withBreaks}</p>`)
      }
    }
    if (parts.length === 0) {
      parts.push('<p></p>')
    }
    return parts.join('\n')
  }

  private static wrapInWordHtml(bodyHtml: string, title: string): string {
    return `<html xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:w="urn:schemas-microsoft-com:office:word"
  xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta charset="utf-8">
<title>${WordGenerator.escapeHtml(title)}</title>
<!--[if gte mso 9]>
<xml>
  <w:WordDocument>
    <w:View>Print</w:View>
    <w:Zoom>100</w:Zoom>
  </w:WordDocument>
</xml>
<![endif]-->
<style>
body { font-family: '宋体', SimSun, serif; margin: 2.54cm; }
p { margin: 0 0 6pt 0; font-size: 12pt; line-height: 1.6; }
h1 { font-size: 22pt; font-weight: bold; }
h2 { font-size: 16pt; font-weight: bold; }
h3 { font-size: 14pt; font-weight: bold; }
table { border-collapse: collapse; width: 100%; }
td, th { border: 1px solid #000; padding: 4pt 8pt; font-size: 12pt; }
</style>
</head>
<body>
${bodyHtml}
</body>
</html>`
  }

  private static escapeHtml(text: string): string {
    let out = text
    out = out.replace(/&/g, '&amp;')
    out = out.replace(/</g, '&lt;')
    out = out.replace(/>/g, '&gt;')
    out = out.replace(/"/g, '&quot;')
    return out
  }
}
