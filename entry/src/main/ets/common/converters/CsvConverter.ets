/**
 * CSV 解析与序列化
 * 支持引号包裹字段、逗号/换行在引号内、双引号转义、CRLF/LF。
 */
import { TableModel } from './TableModel'

export class CsvConverter {
  /** 解析 CSV 文本为表格模型（首行为表头） */
  static parse(text: string): TableModel {
    const model = new TableModel()
    const rows: string[][] = CsvConverter.parseRows(text)
    if (rows.length === 0) {
      return model
    }
    model.headers = rows[0]
    for (let i = 1; i < rows.length; i++) {
      model.rows.push(rows[i])
    }
    return model
  }

  /** 表格模型序列化为 CSV 文本 */
  static serialize(model: TableModel): string {
    const lines: string[] = []
    if (model.headers.length > 0) {
      lines.push(CsvConverter.formatRow(model.headers))
    }
    for (const row of model.rows) {
      lines.push(CsvConverter.formatRow(row))
    }
    return lines.join('\r\n')
  }

  private static parseRows(text: string): string[][] {
    const rows: string[][] = []
    let current: string[] = []
    let field = ''
    let inQuotes = false
    let i = 0
    const len = text.length
    while (i < len) {
      const ch = text.charAt(i)
      if (inQuotes) {
        if (ch === '"') {
          if (i + 1 < len && text.charAt(i + 1) === '"') {
            field += '"'
            i += 2
          } else {
            inQuotes = false
            i++
          }
        } else {
          field += ch
          i++
        }
      } else {
        if (ch === '"' && field.length === 0) {
          inQuotes = true
          i++
        } else if (ch === ',') {
          current.push(field)
          field = ''
          i++
        } else if (ch === '\n') {
          current.push(field)
          field = ''
          rows.push(current)
          current = []
          i++
        } else if (ch === '\r') {
          i++
        } else {
          field += ch
          i++
        }
      }
    }
    if (field.length > 0 || current.length > 0) {
      current.push(field)
      rows.push(current)
    }
    return rows
  }

  private static formatRow(fields: string[]): string {
    const parts: string[] = []
    for (const field of fields) {
      parts.push(CsvConverter.escapeField(field))
    }
    return parts.join(',')
  }

  private static escapeField(field: string): string {
    if (field.includes(',') || field.includes('"') || field.includes('\n') || field.includes('\r')) {
      return `"${field.replace(/"/g, '""')}"`
    }
    return field
  }
}
