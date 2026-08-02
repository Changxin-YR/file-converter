/**
 * HTML → 纯文本 / Markdown（尽力而为）
 * 去除脚本/样式,块级标签转换行,常用标签转 MD 标记。
 * 注意：避免 String.replace 回调与多捕获组 exec（ArkTS 限制）,
 * 统一用单捕获组 split 交替处理。
 */
export class HtmlConverter {
  /** HTML → 纯文本 */
  static toText(html: string): string {
    let out = html
    // 移除 script / style / 注释
    out = out.replace(/<script[\s\S]*?<\/script>/gi, '')
    out = out.replace(/<style[\s\S]*?<\/style>/gi, '')
    out = out.replace(/<!--[\s\S]*?-->/g, '')
    // 块级结束/换行标签 → 换行
    out = out.replace(/<\/(p|div|h[1-6]|li|tr|table|blockquote|pre)>/gi, '\n')
    out = out.replace(/<br\s*\/?>/gi, '\n')
    // 单元格分隔
    out = out.replace(/<\/(td|th)>/gi, '\t')
    // 去掉剩余所有标签
    out = out.replace(/<[^>]*>/g, '')
    // 解码实体
    out = HtmlConverter.decodeEntities(out)
    // 清理多余空行
    out = out.replace(/[ \t]+\n/g, '\n')
    out = out.replace(/\n{3,}/g, '\n\n')
    return out.trim()
  }

  /** HTML → Markdown（尽力而为:标题/粗斜体/链接/列表/行内代码） */
  static toMarkdown(html: string): string {
    let out = html
    out = out.replace(/<script[\s\S]*?<\/script>/gi, '')
    out = out.replace(/<style[\s\S]*?<\/style>/gi, '')
    out = out.replace(/<!--[\s\S]*?-->/g, '')
    // 标题（h1-h6 逐个处理,单捕获组）
    for (let level = 1; level <= 6; level++) {
      const re = new RegExp(`<h${level}[^>]*>([\\s\\S]*?)</h${level}>`, 'gi')
      out = HtmlConverter.splitTransform(out, re, (content: string): string => {
        const hashes = '#'.repeat(level)
        return `\n${hashes} ${HtmlConverter.inlineMd(content.trim())}\n`
      })
    }
    // 表格简化 → 制表符分隔行
    out = HtmlConverter.splitTransform(
      out,
      /<tr[^>]*>([\s\S]*?)<\/tr>/gi,
      (content: string): string => {
        const cells = content.replace(/<\/t[hd]>/gi, '\t').replace(/<t[hd][^>]*>/gi, '')
        return `\n${cells.trim()}\n`
      }
    )
    // 列表
    out = HtmlConverter.splitTransform(
      out,
      /<li[^>]*>([\s\S]*?)<\/li>/gi,
      (content: string): string => `\n- ${HtmlConverter.inlineMd(content.trim())}`
    )
    // 换行与段落
    out = out.replace(/<\/p>/gi, '\n\n')
    out = out.replace(/<br\s*\/?>/gi, '\n')
    // 移除其余标签
    out = out.replace(/<[^>]*>/g, '')
    out = HtmlConverter.decodeEntities(out)
    out = out.replace(/\n{3,}/g, '\n\n')
    return out.trim()
  }

  /**
   * 单捕获组正则变换：split(regex) 保留捕获组,结果按 [文本,捕获,文本,捕获,...] 交替,
   * 每个捕获内容交给 transform。
   */
  private static splitTransform(text: string, regex: RegExp, transform: (capture: string) => string): string {
    const parts = text.split(regex)
    const out: string[] = []
    let i = 0
    while (i < parts.length) {
      out.push(parts[i])
      if (i + 1 < parts.length) {
        out.push(transform(parts[i + 1]))
      }
      i += 2
    }
    return out.join('')
  }

  private static inlineMd(text: string): string {
    let out = text
    out = out.replace(/<strong[^>]*>([\s\S]*?)<\/strong>/gi, '**$1**')
    out = out.replace(/<b[^>]*>([\s\S]*?)<\/b>/gi, '**$1**')
    out = out.replace(/<em[^>]*>([\s\S]*?)<\/em>/gi, '*$1*')
    out = out.replace(/<i[^>]*>([\s\S]*?)<\/i>/gi, '*$1*')
    out = out.replace(/<code[^>]*>([\s\S]*?)<\/code>/gi, '`$1`')
    out = out.replace(/<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/gi, '[$2]($1)')
    return out
  }

  private static decodeEntities(text: string): string {
    let out = text
    const map: Record<string, string> = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
      '&copy;': '(c)',
      '&reg;': '(r)'
    }
    for (const key of Object.keys(map)) {
      out = out.split(key).join(map[key])
    }
    // 数字实体：split 保留单捕获组,奇数索引为数字
    const parts = out.split(/&#(\d+);/g)
    const result: string[] = []
    for (let i = 0; i < parts.length; i++) {
      if (i % 2 === 1) {
        const n = parseInt(parts[i], 10)
        result.push(n > 0 && n < 0xFFFF ? String.fromCharCode(n) : '')
      } else {
        result.push(parts[i])
      }
    }
    return result.join('')
  }
}
