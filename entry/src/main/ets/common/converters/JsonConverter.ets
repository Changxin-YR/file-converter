/**
 * JSON 解析与派生转换
 * 统一以 Object 表示 JSON 值,递归转换为 CSV/XML/Markdown/HTML/文本。
 */
import { TableModel } from './TableModel'

export class JsonConverter {
  static tryParse(text: string): Object | null {
    try {
      return JSON.parse(text) as Object
    } catch (e) {
      return null
    }
  }

  static isArray(v: Object): boolean {
    return v instanceof Array
  }

  static isRecord(v: Object): boolean {
    return typeof v === 'object' && v !== null && !(v instanceof Array)
  }

  static asRecord(v: Object): Record<string, Object> {
    return v as Record<string, Object>
  }

  static asArray(v: Object): Object[] {
    return v as Object[]
  }

  /** 值 → 文本（嵌套对象/数组转为紧凑 JSON） */
  static toText(v: Object): string {
    if (v === null || v === undefined) {
      return ''
    }
    if (typeof v === 'string') {
      return v
    }
    if (typeof v === 'number' || typeof v === 'boolean') {
      return String(v)
    }
    return JSON.stringify(v)
  }

  /** 美化打印 JSON */
  static toPretty(v: Object): string {
    return JSON.stringify(v, null, 2)
  }

  /** JSON → 表格模型（对象数组或单对象;非表结构返回 null） */
  static toTable(v: Object): TableModel | null {
    const model = new TableModel()
    const rows: Object[] = []
    if (JsonConverter.isArray(v)) {
      for (const item of JsonConverter.asArray(v)) {
        if (JsonConverter.isRecord(item)) {
          rows.push(item)
        }
      }
    } else if (JsonConverter.isRecord(v)) {
      rows.push(v)
    }
    if (rows.length === 0) {
      return null
    }
    const first = JsonConverter.asRecord(rows[0])
    const headers: string[] = []
    for (const key of Object.keys(first)) {
      headers.push(key)
    }
    model.headers = headers
    for (const rowObj of rows) {
      const row: string[] = []
      const rec = JsonConverter.asRecord(rowObj)
      for (const header of headers) {
        const value = rec[header]
        row.push(value !== undefined ? JsonConverter.toText(value) : '')
      }
      model.rows.push(row)
    }
    return model
  }

  /** JSON → XML（简化映射:对象→标签,数组→重复标签,原始值→文本） */
  static toXml(v: Object, rootName: string = 'root'): string {
    if (JsonConverter.isArray(v)) {
      const parts: string[] = []
      for (const item of JsonConverter.asArray(v)) {
        parts.push(JsonConverter.toXml(item, JsonConverter.singular(rootName)))
      }
      return parts.join('')
    }
    if (JsonConverter.isRecord(v)) {
      const rec = JsonConverter.asRecord(v)
      let inner = ''
      for (const key of Object.keys(rec)) {
        inner += JsonConverter.toXml(rec[key], key)
      }
      return `<${rootName}>${inner}</${rootName}>`
    }
    return `<${rootName}>${JsonConverter.escapeXml(JsonConverter.toText(v))}</${rootName}>`
  }

  /** 标签名规范化（去非法字符,转小写） */
  private static singular(name: string): string {
    const norm = name.replace(/[^a-zA-Z0-9_-]/g, '_')
    if (norm.endsWith('s') && norm.length > 1) {
      return norm.substring(0, norm.length - 1)
    }
    return norm
  }

  private static escapeXml(text: string): string {
    let out = text
    out = out.replace(/&/g, '&amp;')
    out = out.replace(/</g, '&lt;')
    out = out.replace(/>/g, '&gt;')
    return out
  }
}
