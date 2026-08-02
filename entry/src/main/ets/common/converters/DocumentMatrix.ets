/**
 * 文档转换矩阵
 * 统一的格式支持判断与转换调度入口。所有转换在本地完成,无网络依赖。
 *
 * 支持的转换关系：
 * - TXT/LOG → {txt, md, html}
 * - CSV      → {json, xml, md, html, txt}
 * - JSON     → {csv, xml, md, html, txt}
 * - XML      → {json, csv, txt, md, html}
 * - MD       → {html, txt}
 * - HTML     → {txt, md}
 */
import { CsvConverter } from './CsvConverter'
import { JsonConverter } from './JsonConverter'
import { XmlConverter } from './XmlConverter'
import { MarkdownConverter } from './MarkdownConverter'
import { HtmlConverter } from './HtmlConverter'
import { TableModel } from './TableModel'

export interface ConvertOutcome {
  success: boolean
  text?: string
  error?: string
}

const TEXT_LIKE: string[] = ['txt', 'log']
const ALL_EXT: string[] = ['txt', 'log', 'csv', 'json', 'xml', 'html', 'md']

export class DocumentMatrix {
  /** 判断 srcExt → dstExt 是否受支持 */
  static supports(srcExt: string, dstExt: string): boolean {
    const src = srcExt.toLowerCase()
    const dst = dstExt.toLowerCase()
    if (src === dst) {
      return true
    }
    if (TEXT_LIKE.includes(src)) {
      return ['txt', 'md', 'html'].includes(dst)
    }
    switch (src) {
      case 'csv':
        return ['json', 'xml', 'md', 'html', 'txt'].includes(dst)
      case 'json':
        return ['csv', 'xml', 'md', 'html', 'txt'].includes(dst)
      case 'xml':
        return ['json', 'csv', 'txt', 'md', 'html'].includes(dst)
      case 'md':
        return ['html', 'txt'].includes(dst)
      case 'html':
        return ['txt', 'md'].includes(dst)
      default:
        return false
    }
  }

  /** 当前是否可原生转换（两个格式都在能力矩阵内且源!=目标） */
  static isConvertible(srcExt: string, dstExt: string): boolean {
    return srcExt.toLowerCase() !== dstExt.toLowerCase() && DocumentMatrix.supports(srcExt, dstExt)
  }

  static convert(srcExt: string, dstExt: string, text: string): ConvertOutcome {
    const src = srcExt.toLowerCase()
    const dst = dstExt.toLowerCase()
    if (!ALL_EXT.includes(src) || !ALL_EXT.includes(dst)) {
      return { success: false, error: `不支持 ${srcExt} → ${dstExt}` }
    }
    if (!DocumentMatrix.supports(src, dst)) {
      return { success: false, error: `暂不支持 ${srcExt} → ${dstExt}` }
    }
    if (src === dst) {
      return { success: true, text: text }
    }
    try {
      if (TEXT_LIKE.includes(src)) {
        return DocumentMatrix.fromText(dst, text)
      }
      switch (src) {
        case 'csv':
          return DocumentMatrix.fromCsv(dst, text)
        case 'json':
          return DocumentMatrix.fromJson(dst, text)
        case 'xml':
          return DocumentMatrix.fromXml(dst, text)
        case 'md':
          return { success: true, text: dst === 'html' ? MarkdownConverter.toHtml(text) : MarkdownConverter.toText(text) }
        case 'html':
          return { success: true, text: dst === 'txt' ? HtmlConverter.toText(text) : HtmlConverter.toMarkdown(text) }
        default:
          return { success: false, error: `不支持 ${srcExt}` }
      }
    } catch (e) {
      return { success: false, error: `${srcExt} → ${dstExt} 转换失败:${e instanceof Error ? e.message : '解析错误'}` }
    }
  }

  private static fromText(dst: string, text: string): ConvertOutcome {
    if (dst === 'txt' || dst === 'log' || dst === 'md') {
      return { success: true, text: text }
    }
    if (dst === 'html') {
      const paragraphs = text.replace(/\r\n/g, '\n').split(/\n\s*\n/)
      const html: string[] = []
      for (const para of paragraphs) {
        const trimmed = para.trim()
        if (trimmed.length > 0) {
          const lines = trimmed.split('\n')
          const escapedLines: string[] = []
          for (const line of lines) {
            escapedLines.push(DocumentMatrix.escapeHtml(line))
          }
          html.push(`<p>${escapedLines.join('<br/>')}</p>`)
        }
      }
      return { success: true, text: html.join('\n') }
    }
    return { success: false, error: `暂不支持 txt → ${dst}` }
  }

  private static fromCsv(dst: string, text: string): ConvertOutcome {
    const model = CsvConverter.parse(text)
    switch (dst) {
      case 'json':
        return { success: true, text: DocumentMatrix.tableToJson(model) }
      case 'xml':
        return { success: true, text: DocumentMatrix.tableToXml(model) }
      case 'md':
        return { success: true, text: DocumentMatrix.renderTableMd(model) }
      case 'html':
        return { success: true, text: DocumentMatrix.renderTableHtml(model) }
      case 'txt':
        return { success: true, text: CsvConverter.serialize(model) }
      default:
        return { success: false, error: `暂不支持 csv → ${dst}` }
    }
  }

  private static fromJson(dst: string, text: string): ConvertOutcome {
    const obj = JsonConverter.tryParse(text)
    if (obj === null) {
      return { success: false, error: 'JSON 解析失败' }
    }
    switch (dst) {
      case 'csv': {
        const table = JsonConverter.toTable(obj)
        if (table === null) {
          return { success: false, error: 'JSON 不是可转为表格的对象数组结构' }
        }
        return { success: true, text: CsvConverter.serialize(table) }
      }
      case 'xml':
        return { success: true, text: JsonConverter.toXml(obj) }
      case 'md': {
        const table = JsonConverter.toTable(obj)
        return table === null
          ? { success: true, text: '```json\n' + JsonConverter.toPretty(obj) + '\n```' }
          : { success: true, text: DocumentMatrix.renderTableMd(table) }
      }
      case 'html': {
        const table = JsonConverter.toTable(obj)
        return table === null
          ? { success: true, text: '<pre>' + DocumentMatrix.escapeHtml(JsonConverter.toPretty(obj)) + '</pre>' }
          : { success: true, text: DocumentMatrix.renderTableHtml(table) }
      }
      case 'txt':
        return { success: true, text: JsonConverter.toPretty(obj) }
      default:
        return { success: false, error: `暂不支持 json → ${dst}` }
    }
  }

  private static fromXml(dst: string, text: string): ConvertOutcome {
    const root = XmlConverter.parse(text)
    if (root === null) {
      return { success: false, error: 'XML 解析失败' }
    }
    switch (dst) {
      case 'json': {
        const jsonObj = XmlConverter.toJson(root)
        return { success: true, text: JsonConverter.toPretty(jsonObj) }
      }
      case 'csv': {
        const table = XmlConverter.toTable(root)
        if (table === null) {
          return { success: false, error: 'XML 无重复元素可转为表格' }
        }
        return { success: true, text: CsvConverter.serialize(table) }
      }
      case 'txt':
        return { success: true, text: XmlConverter.toText(root) }
      case 'md': {
        const table = XmlConverter.toTable(root)
        return table === null
          ? { success: true, text: XmlConverter.toText(root) }
          : { success: true, text: DocumentMatrix.renderTableMd(table) }
      }
      case 'html': {
        const table = XmlConverter.toTable(root)
        return table === null
          ? { success: true, text: '<pre>' + DocumentMatrix.escapeHtml(XmlConverter.toText(root)) + '</pre>' }
          : { success: true, text: DocumentMatrix.renderTableHtml(table) }
      }
      default:
        return { success: false, error: `暂不支持 xml → ${dst}` }
    }
  }

  /** TableModel → JSON 对象数组文本 */
  private static tableToJson(model: TableModel): string {
    const records: Record<string, Object>[] = []
    for (const row of model.rows) {
      const rec: Record<string, Object> = {}
      for (let c = 0; c < model.headers.length; c++) {
        const key = model.headers[c]
        const value = row[c]
        if (key.length > 0) {
          rec[key] = value !== undefined ? value : ''
        }
      }
      records.push(rec)
    }
    return JSON.stringify(records, null, 2)
  }

  /** TableModel → XML（每行为 <item><col>..</col>...</item>） */
  private static tableToXml(model: TableModel): string {
    const parts: string[] = []
    for (const row of model.rows) {
      let inner = ''
      for (let c = 0; c < model.headers.length; c++) {
        const col = DocumentMatrix.normalizeTag(model.headers[c])
        if (col.length === 0) {
          continue
        }
        const value = row[c] !== undefined ? row[c] : ''
        inner += `<${col}>${DocumentMatrix.escapeXml(value)}</${col}>`
      }
      parts.push(`<item>${inner}</item>`)
    }
    return `<root>${parts.join('')}</root>`
  }

  private static renderTableMd(model: TableModel): string {
    if (model.headers.length === 0) {
      return ''
    }
    const lines: string[] = []
    lines.push(`| ${model.headers.join(' | ')} |`)
    const seps: string[] = []
    for (let i = 0; i < model.headers.length; i++) {
      seps.push('---')
    }
    lines.push(`| ${seps.join(' | ')} |`)
    for (const row of model.rows) {
      lines.push(`| ${row.join(' | ')} |`)
    }
    return lines.join('\n')
  }

  private static renderTableHtml(model: TableModel): string {
    if (model.headers.length === 0) {
      return ''
    }
    let html = '<table><thead><tr>'
    for (const h of model.headers) {
      html += `<th>${DocumentMatrix.escapeHtml(h)}</th>`
    }
    html += '</tr></thead><tbody>'
    for (const row of model.rows) {
      html += '<tr>'
      for (const cell of row) {
        html += `<td>${DocumentMatrix.escapeHtml(cell)}</td>`
      }
      html += '</tr>'
    }
    html += '</tbody></table>'
    return html
  }

  private static normalizeTag(name: string): string {
    let out = name.trim().replace(/[^a-zA-Z0-9_-]/g, '_')
    if (out.length === 0) {
      out = 'col'
    }
    return out
  }

  private static escapeXml(text: string): string {
    let out = text
    out = out.replace(/&/g, '&amp;')
    out = out.replace(/</g, '&lt;')
    out = out.replace(/>/g, '&gt;')
    return out
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
