/**
 * 轻量 XML 解析与派生转换
 * 手写递归下降解析器,支持标签、属性、文本、嵌套、自闭合、CDATA 文本、注释跳过。
 */
import { TableModel } from './TableModel'

export class XmlNode {
  name: string = ''
  attrs: Record<string, string> = {}
  children: XmlNode[] = []
  text: string = ''
}

export class XmlConverter {
  static parse(text: string): XmlNode | null {
    try {
      const parser = new XmlParser(text)
      return parser.parseRoot()
    } catch (e) {
      return null
    }
  }

  /** XML 树 → 表格模型（根的直接子元素为行,后代同名元素为列） */
  static toTable(root: XmlNode): TableModel | null {
    const model = new TableModel()
    const rowsNodes: XmlNode[] = XmlConverter.collectRepeatChildren(root)
    if (rowsNodes.length === 0) {
      return null
    }
    // 收集列（所有行节点的直接子元素名并集,保持顺序）
    const columnNames: string[] = []
    for (const rowNode of rowsNodes) {
      for (const child of rowNode.children) {
        if (!columnNames.includes(child.name)) {
          columnNames.push(child.name)
        }
      }
    }
    model.headers = columnNames
    for (const rowNode of rowsNodes) {
      const row: string[] = []
      for (const col of columnNames) {
        let value = ''
        for (const child of rowNode.children) {
          if (child.name === col) {
            value = XmlConverter.textOf(child)
            break
          }
        }
        row.push(value)
      }
      model.rows.push(row)
    }
    return model
  }

  /** XML 树 → JSON（简化映射:唯一子元素→属性,重复子元素→数组,文本→字符串） */
  static toJson(root: XmlNode): Object {
    return XmlConverter.nodeToJson(root)
  }

  /** XML 树 → 纯文本（提取全部文本节点） */
  static toText(root: XmlNode): string {
    return XmlConverter.textOf(root)
  }

  static serialize(root: XmlNode): string {
    return XmlConverter.serializeNode(root)
  }

  private static serializeNode(node: XmlNode): string {
    if (node.children.length === 0 && node.text.length === 0) {
      return `<${node.name}/>`
    }
    let attrStr = ''
    for (const key of Object.keys(node.attrs)) {
      attrStr += ` ${key}="${node.attrs[key]}"`
    }
    let inner = node.text
    for (const child of node.children) {
      inner += XmlConverter.serializeNode(child)
    }
    return `<${node.name}${attrStr}>${inner}</${node.name}>`
  }

  private static textOf(node: XmlNode): string {
    let text = node.text
    for (const child of node.children) {
      text += XmlConverter.textOf(child)
    }
    return text.trim()
  }

  private static collectRepeatChildren(node: XmlNode): XmlNode[] {
    if (node.children.length === 0) {
      return []
    }
    // 找出出现次数最多的直接子元素名
    const counts: Record<string, number> = {}
    for (const child of node.children) {
      counts[child.name] = (counts[child.name] ?? 0) + 1
    }
    let maxName = ''
    let maxCount = 0
    for (const key of Object.keys(counts)) {
      if (counts[key] > maxCount) {
        maxCount = counts[key]
        maxName = key
      }
    }
    if (maxCount < 2) {
      return []
    }
    const result: XmlNode[] = []
    for (const child of node.children) {
      if (child.name === maxName) {
        result.push(child)
      }
    }
    return result
  }

  private static nodeToJson(node: XmlNode): Object {
    // 收集子元素分组
    const groups: Record<string, Object[]> = {}
    for (const child of node.children) {
      const arr = groups[child.name]
      if (arr === undefined) {
        groups[child.name] = [XmlConverter.nodeToJson(child)]
      } else {
        arr.push(XmlConverter.nodeToJson(child))
      }
    }
    const result: Record<string, Object> = {}
    for (const key of Object.keys(groups)) {
      const items = groups[key]
      if (items.length === 1) {
        result[key] = items[0]
      } else {
        result[key] = items
      }
    }
    const t = node.text.trim()
    if (t.length > 0) {
      result['#text'] = t
    }
    if (Object.keys(result).length === 0) {
      return ''
    }
    return result
  }
}

/** 递归下降 XML 解析器（容错:跳过声明/注释/DOCTYPE） */
class XmlParser {
  private text: string
  private pos: number = 0

  constructor(text: string) {
    this.text = text
  }

  parseRoot(): XmlNode | null {
    this.skipMisc()
    if (this.pos >= this.text.length) {
      return null
    }
    const node = this.parseElement()
    return node
  }

  private skipMisc(): void {
    // 跳过空白、XML 声明、注释、DOCTYPE
    while (this.pos < this.text.length) {
      if (this.startsWith('<?')) {
        this.skipUntil('?>')
      } else if (this.startsWith('<!--')) {
        this.skipUntil('-->')
      } else if (this.startsWith('<!')) {
        this.skipUntil('>')
      } else if (this.isWhitespace(this.current())) {
        this.pos++
      } else {
        break
      }
    }
  }

  private parseElement(): XmlNode {
    const node = new XmlNode()
    if (this.current() !== '<') {
      throw new Error('expected <')
    }
    this.pos++
    // 属性区可能以问号开头(声明已跳过)
    node.name = this.readName()
    // 属性
    while (true) {
      this.skipWhitespace()
      const ch = this.current()
      if (ch === '>') {
        this.pos++
        break
      }
      if (ch === '/' && this.text.charAt(this.pos + 1) === '>') {
        this.pos += 2
        return node
      }
      // 读取属性名=值
      const attrName = this.readName()
      this.skipWhitespace()
      if (this.current() === '=') {
        this.pos++
        this.skipWhitespace()
        const quote = this.current()
        if (quote === '"' || quote === '\'') {
          this.pos++
          let value = ''
          while (this.pos < this.text.length && this.current() !== quote) {
            value += this.current()
            this.pos++
          }
          if (this.current() === quote) {
            this.pos++
          }
          node.attrs[attrName] = value
        }
      }
    }
    // 内容:文本与子元素
    let content = ''
    while (this.pos < this.text.length) {
      if (this.startsWith('</')) {
        this.pos += 2
        this.readName()
        this.skipWhitespace()
        if (this.current() === '>') {
          this.pos++
        }
        break
      }
      if (this.startsWith('<!--')) {
        this.skipUntil('-->')
        continue
      }
      if (this.current() === '<') {
        if (content.length > 0) {
          node.text += content
          content = ''
        }
        const child = this.parseElement()
        node.children.push(child)
        continue
      }
      content += this.current()
      this.pos++
    }
    if (content.length > 0) {
      node.text += content
    }
    return node
  }

  private readName(): string {
    this.skipWhitespace()
    let name = ''
    while (this.pos < this.text.length) {
      const ch = this.current()
      if (/[a-zA-Z0-9_\-.:]/.test(ch)) {
        name += ch
        this.pos++
      } else {
        break
      }
    }
    return name
  }

  private skipWhitespace(): void {
    while (this.pos < this.text.length && this.isWhitespace(this.current())) {
      this.pos++
    }
  }

  private skipUntil(marker: string): void {
    while (this.pos < this.text.length && !this.startsWith(marker)) {
      this.pos++
    }
    if (this.pos < this.text.length) {
      this.pos += marker.length
    }
  }

  private startsWith(s: string): boolean {
    return this.text.startsWith(s, this.pos)
  }

  private current(): string {
    return this.text.charAt(this.pos)
  }

  private isWhitespace(ch: string): boolean {
    return ch === ' ' || ch === '\t' || ch === '\n' || ch === '\r'
  }
}
