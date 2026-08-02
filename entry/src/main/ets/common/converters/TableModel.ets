/**
 * 表格中间模型
 * 供 CSV / JSON / XML / Markdown / HTML 转换共享的二维表结构。
 */
export class TableModel {
  headers: string[] = []
  rows: string[][] = []

  isEmpty(): boolean {
    return this.headers.length === 0 && this.rows.length === 0
  }
}
