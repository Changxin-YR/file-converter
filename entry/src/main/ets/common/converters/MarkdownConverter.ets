/**
 * Markdown → HTML / 纯文本
 * 支持标题、段落、粗体、斜体、行内代码、链接、列表、引用、水平线、代码块、表格。
 */
export class MarkdownConverter {
  static toHtml(md: string): string {
    const lines = md.replace(/\r\n/g, '\n').split('\n')
    const html: string[] = []
    let i = 0
    let inCodeBlock = false
    let codeBuffer: string[] = []
    let listType = '' // '', 'ul', 'ol'
    let inTable = false
    let tableLines: string[] = []

    const flushList = (): void => {
      if (listType.length > 0) {
        html.push(`</${listType}>`)
        listType = ''
      }
    }

    const flushTable = (): void => {
      if (inTable) {
        html.push(MarkdownConverter.renderTable(tableLines))
        tableLines = []
        inTable = false
      }
    }

    while (i < lines.length) {
      const line = lines[i]
      const trimmed = line.trim()

      // 代码块
      if (trimmed.startsWith('```')) {
        if (!inCodeBlock) {
          flushList()
          flushTable()
          inCodeBlock = true
          codeBuffer = []
        } else {
          html.push('<pre><code>' + MarkdownConverter.escapeHtml(codeBuffer.join('\n')) + '</code></pre>')
          inCodeBlock = false
          codeBuffer = []
        }
        i++
        continue
      }
      if (inCodeBlock) {
        codeBuffer.push(line)
        i++
        continue
      }

      // 表格
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        flushList()
        if (!inTable) {
          inTable = true
          tableLines = []
        }
        tableLines.push(trimmed)
        i++
        continue
      }
      if (inTable) {
        flushTable()
      }

      // 标题
      const headingMatch = /^(#{1,6})\s+(.*)$/.exec(trimmed)
      if (headingMatch) {
        flushList()
        const level = headingMatch[1].length
        html.push(`<h${level}>${MarkdownConverter.inline(headingMatch[2])}</h${level}>`)
        i++
        continue
      }

      // 水平线
      if (/^(-{3,}|\*{3,}|_{3,})$/.test(trimmed)) {
        flushList()
        html.push('<hr/>')
        i++
        continue
      }

      // 无序列表
      const ulMatch = /^[-*+]\s+(.*)$/.exec(trimmed)
      if (ulMatch) {
        if (listType !== 'ul') {
          flushList()
          html.push('<ul>')
          listType = 'ul'
        }
        html.push(`<li>${MarkdownConverter.inline(ulMatch[1])}</li>`)
        i++
        continue
      }

      // 有序列表
      const olMatch = /^\d+\.\s+(.*)$/.exec(trimmed)
      if (olMatch) {
        if (listType !== 'ol') {
          flushList()
          html.push('<ol>')
          listType = 'ol'
        }
        html.push(`<li>${MarkdownConverter.inline(olMatch[1])}</li>`)
        i++
        continue
      }

      // 引用
      if (trimmed.startsWith('>')) {
        flushList()
        const quote = trimmed.replace(/^>\s?/, '')
        html.push(`<blockquote>${MarkdownConverter.inline(quote)}</blockquote>`)
        i++
        continue
      }

      // 空行
      if (trimmed.length === 0) {
        flushList()
        i++
        continue
      }

      // 普通段落
      flushList()
      html.push(`<p>${MarkdownConverter.inline(trimmed)}</p>`)
      i++
    }

    flushList()
    flushTable()
    if (inCodeBlock) {
      html.push('<pre><code>' + MarkdownConverter.escapeHtml(codeBuffer.join('\n')) + '</code></pre>')
    }
    return html.join('\n')
  }

  /** Markdown → 纯文本（去除标记符号,保留可读内容） */
  static toText(md: string): string {
    const lines = md.replace(/\r\n/g, '\n').split('\n')
    const out: string[] = []
    for (const rawLine of lines) {
      let line = rawLine
      // 代码块围栏
      line = line.replace(/^```/, '')
      // 标题
      line = line.replace(/^(#{1,6})\s+/, '')
      // 列表
      line = line.replace(/^[-*+]\s+/, '- ')
      line = line.replace(/^\d+\.\s+/, '')
      // 引用
      line = line.replace(/^>\s?/, '')
      // 表格分隔
      if (/^[|\s:]+-+[|\s:]+$/.test(line)) {
        continue
      }
      // 行内:链接保留文本
      line = line.replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
      line = line.replace(/\*\*(.+?)\*\*/g, '$1')
      line = line.replace(/(^|[^*])\*([^*]+)\*(?!\*)/g, '$1$2')
      line = line.replace(/`([^`]+)`/g, '$1')
      line = line.replace(/^\|/, '').replace(/\|$/, '').replace(/\|/g, '\t')
      out.push(line)
    }
    return out.join('\n')
  }

  /** 行内格式转换 */
  private static inline(text: string): string {
    let out = text
    // 行内代码
    out = out.replace(/`([^`]+)`/g, '<code>$1</code>')
    // 链接
    out = out.replace(/\[([^\]]*)\]\(([^)]*)\)/g, '<a href="$2">$1</a>')
    // 粗体
    out = out.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    // 斜体
    out = out.replace(/(^|[^*])\*([^*]+)\*(?!\*)/g, '$1<em>$2</em>')
    // 下划线斜体
    out = out.replace(/_([^_]+)_/g, '<em>$1</em>')
    return out
  }

  private static renderTable(lines: string[]): string {
    // 首行表头,第二行分隔,后续为行
    const rows: string[][] = []
    for (const line of lines) {
      const cells = line.replace(/^\|/, '').replace(/\|$/, '').split('|')
      const clean: string[] = []
      for (const cell of cells) {
        clean.push(cell.trim())
      }
      rows.push(clean)
    }
    if (rows.length < 2) {
      return ''
    }
    const headers = rows[0]
    let html = '<table><thead><tr>'
    for (const h of headers) {
      html += `<th>${MarkdownConverter.inline(h)}</th>`
    }
    html += '</tr></thead><tbody>'
    for (let r = 1; r < rows.length; r++) {
      if (rows[r].length === 1 && /^[-:\s]+$/.test(rows[r][0])) {
        continue
      }
      html += '<tr>'
      for (const cell of rows[r]) {
        html += `<td>${MarkdownConverter.inline(cell)}</td>`
      }
      html += '</tr>'
    }
    html += '</tbody></table>'
    return html
  }

  private static escapeHtml(text: string): string {
    let out = text
    out = out.replace(/&/g, '&amp;')
    out = out.replace(/</g, '&lt;')
    out = out.replace(/>/g, '&gt;')
    return out
  }
}
