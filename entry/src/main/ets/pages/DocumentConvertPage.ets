/**
 * 文档转换页
 * 选择文档文件 → 选择目标格式(Word/PDF/TXT/MD) → 转换 → 保存
 * 输出统一 UTF-8 编码,离线完成。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import { fileIo as fs } from '@kit.CoreFileKit'
import { FilePickerService } from '../services/FilePickerService'
import { SaveService } from '../services/SaveService'
import { FormatInfo } from '../common/FormatTypes'
import { FileUtils } from '../common/Utils'
import { FormatSelector } from '../components/FormatSelector'
import { ConvertProgressBar } from '../components/ConvertProgressBar'
import { DocumentMatrix } from '../common/converters/DocumentMatrix'
import { MarkdownConverter } from '../common/converters/MarkdownConverter'
import { PdfGenerator } from '../common/converters/PdfGenerator'
import { WordGenerator } from '../common/converters/WordGenerator'
import { TextCodec } from '../common/converters/TextCodec'
import { DocumentTargetResolver } from '../common/converters/DocumentTargetResolver'

const DOC_SOURCE_SUFFIXES: string[] = ['.txt', '.csv', '.json', '.xml', '.html', '.md', '.log']

const SOURCE_ENCODINGS: string[] = ['utf-8', 'gbk', 'utf-16le']

@Entry
@Component
struct DocumentConvertPage {
  @State selectedFiles: string[] = []
  @State targetFormat: string = 'pdf'
  @State converting: boolean = false
  @State progress: number = 0
  @State statusText: string = ''
  @State successCount: number = 0
  @State sourceEncoding: string = 'utf-8'

  private pickerService?: FilePickerService
  private saveService?: SaveService

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.pickerService = new FilePickerService(context)
    this.saveService = new SaveService(context)
  }

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 16 }) {
          this.FileSection()
          this.FormatSection()
          this.EncodingSection()
          this.ActionSection()
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .title('文档格式转换')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  FileSection() {
    Column({ space: 8 }) {
      Row() {
        Text('选择文档')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button('选择文件')
          .height(34)
          .fontSize(13)
          .enabled(!this.converting)
          .onClick(() => this.pickFiles())
      }
      .width('100%')

      if (this.selectedFiles.length > 0) {
        ForEach(this.selectedFiles, (file: string) => {
          Row() {
            Text(FileUtils.getFileName(file))
              .fontSize(14)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(`.${FileUtils.getExtension(file)}`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .borderRadius(8)
          .backgroundColor($r('app.color.card_background'))
        }, (file: string) => file)
      } else {
        Column() {
          Text('支持 TXT/CSV/JSON/XML/HTML/MD/LOG')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .borderRadius(12)
        .borderWidth(1)
        .borderStyle(BorderStyle.Dashed)
        .borderColor($r('app.color.border'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FormatSection() {
    Column({ space: 8 }) {
      Text('目标格式')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)

      FormatSelector({
        formats: this.getTargetFormats(),
        selected: this.targetFormat,
        disabled: this.converting,
        selectCallback: (ext: string) => {
          this.targetFormat = ext
        }
      })

      Text('目标格式会根据所选源文件动态过滤')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EncodingSection() {
    Column({ space: 8 }) {
      Text('源文件编码')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(SOURCE_ENCODINGS, (encoding: string) => {
          Row() {
            Text(encoding.toUpperCase())
              .fontSize(14)
              .fontColor(this.sourceEncoding === encoding ? Color.White : $r('app.color.text_primary'))
          }
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .borderRadius(18)
          .backgroundColor(this.sourceEncoding === encoding ? $r('app.color.primary') : $r('app.color.chip_background'))
          .opacity(this.converting ? 0.4 : 1)
          .margin({ top: 6, right: 8 })
          .onClick(() => {
            if (!this.converting) {
              this.sourceEncoding = encoding
            }
          })
        }, (encoding: string) => encoding)
      }
      .width('100%')

      Text('输出统一采用 UTF-8 编码')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ActionSection() {
    Column({ space: 12 }) {
      Button(this.converting ? '转换中...' : '开始转换')
        .width('100%')
        .height(44)
        .fontSize(16)
        .enabled(!this.converting && this.selectedFiles.length > 0)
        .onClick(() => this.startConvert())

      if (this.converting) {
        ConvertProgressBar({ progress: this.progress, total: 100, showText: true })
      }

      if (this.statusText.length > 0 && !this.converting) {
        Text(this.statusText)
          .fontSize(13)
          .fontColor(this.successCount > 0 ? $r('app.color.success') : $r('app.color.error'))
      }
    }
    .width('100%')
  }

  private async pickFiles(): Promise<void> {
    if (!this.pickerService) {
      return
    }
    try {
      const uris: string[] = await this.pickerService.pickFiles(DOC_SOURCE_SUFFIXES, 9)
      if (uris.length > 0) {
        this.selectedFiles = uris
        const targets = this.getTargetFormats()
        if (!targets.some((format: FormatInfo) => format.extension === this.targetFormat)) {
          this.targetFormat = targets[0].extension
        }
        this.statusText = ''
        this.progress = 0
        this.successCount = 0
      }
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `选择文件失败:${err.message}`
    }
  }

  private async startConvert(): Promise<void> {
    if (this.selectedFiles.length === 0 || !this.saveService) {
      return
    }
    this.converting = true
    this.progress = 0
    this.statusText = ''
    this.successCount = 0

    const total = this.selectedFiles.length

    for (let i = 0; i < total; i++) {
      const uri: string = this.selectedFiles[i]
      const srcExt: string = FileUtils.getExtension(uri)
      const baseName: string = FileUtils.getBaseName(uri)

      try {
        // 1. 读取源文件为文本 (UTF-8)
        const text = await this.readFileAsText(uri)
        this.progress = Math.round((i + 0.3) / total * 100)

        // 2. 转换为目标格式内容
        const converted = this.convertContent(text, srcExt, this.targetFormat)
        if (converted === null) {
          this.statusText = `第 ${i + 1} 个文件不支持转为 ${this.targetFormat.toUpperCase()}`
          continue
        }
        this.progress = Math.round((i + 0.6) / total * 100)

        // 3. 保存文件
        const fileName = `${baseName}.${this.targetFormat}`
        const targetUri: string = await this.saveService.getSavePath(fileName)
        this.writeContent(targetUri, converted)
        this.successCount++
        this.progress = Math.round((i + 1) / total * 100)
      } catch (e) {
        const err = e as BusinessError
        this.statusText = `第 ${i + 1} 个文件失败:${err.message}`
      }
    }

    this.converting = false
    if (this.successCount > 0) {
      this.statusText = `已成功转换并保存 ${this.successCount} 个文件`
      promptAction.showToast({ message: `已保存 ${this.successCount} 个文件` })
    } else if (this.statusText.length === 0) {
      this.statusText = '转换失败'
    }
  }

  private async readFileAsText(uri: string): Promise<string> {
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
    try {
      const stat = fs.statSync(file.fd)
      if (stat.size > 10 * 1024 * 1024) {
        throw new Error('文件过大(超过10MB),请选择较小的文件')
      }
      const buffer = new ArrayBuffer(stat.size)
      const bytesRead = fs.readSync(file.fd, buffer)
      return TextCodec.decode(buffer.slice(0, bytesRead), this.sourceEncoding)
    } finally {
      fs.closeSync(file)
    }
  }

  /**
   * 将源文本转换为目标格式
   * 返回 ArrayBuffer(PDF) 或 string(TXT/MD/Word)
   */
  private convertContent(text: string, srcExt: string, targetExt: string): ArrayBuffer | string | null {
    // 源格式与目标格式相同（txt→txt 等）
    if (srcExt === targetExt) {
      return text
    }

    switch (targetExt) {
      case 'txt':
        return this.toPlainText(text, srcExt)
      case 'pdf':
        return this.toPdf(text, srcExt)
      case 'doc':
        return this.toWord(text, srcExt)
      default:
        if (DocumentMatrix.isConvertible(srcExt, targetExt)) {
          const result = DocumentMatrix.convert(srcExt, targetExt, text)
          return result.success && result.text !== undefined ? result.text : null
        }
        return null
    }
  }

  private toPlainText(text: string, srcExt: string): string {
    if (srcExt === 'txt' || srcExt === 'log') {
      return text
    }
    if (srcExt === 'md') {
      return MarkdownConverter.toText(text)
    }
    if (DocumentMatrix.isConvertible(srcExt, 'txt')) {
      const result = DocumentMatrix.convert(srcExt, 'txt', text)
      return result.success && result.text ? result.text : text
    }
    return text
  }

  private toPdf(text: string, srcExt: string): ArrayBuffer {
    const plain = this.toPlainText(text, srcExt)
    return PdfGenerator.generate(plain)
  }

  private toWord(text: string, srcExt: string): string {
    // 如果源是 HTML 或可转为 HTML,利用 HTML 结构
    if (srcExt === 'html') {
      return WordGenerator.generateFromHtml(text)
    }
    if (srcExt === 'md') {
      const html = MarkdownConverter.toHtml(text)
      return WordGenerator.generateFromHtml(html)
    }
    if (DocumentMatrix.isConvertible(srcExt, 'html')) {
      const result = DocumentMatrix.convert(srcExt, 'html', text)
      if (result.success && result.text) {
        return WordGenerator.generateFromHtml(result.text)
      }
    }
    return WordGenerator.generate(text)
  }

  private writeContent(targetUri: string, content: ArrayBuffer | string): void {
    const file = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY)
    try {
      if (content instanceof ArrayBuffer) {
        fs.writeSync(file.fd, content)
      } else {
        const encoded = TextCodec.encode(content)
        fs.writeSync(file.fd, encoded)
      }
    } finally {
      fs.closeSync(file)
    }
  }

  private getTargetFormats(): FormatInfo[] {
    const sourceExtensions: string[] = []
    for (const uri of this.selectedFiles) {
      sourceExtensions.push(FileUtils.getExtension(uri))
    }
    return DocumentTargetResolver.resolve(sourceExtensions)
  }
}
