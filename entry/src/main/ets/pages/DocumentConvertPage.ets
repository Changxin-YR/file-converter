/**
 * 文档转换页
 * 选择文档文件 → 选择目标格式(Word/PDF/TXT/MD) → 转换 → 保存
 * 输出统一 UTF-8 编码,离线完成。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction, router } from '@kit.ArkUI'
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
import { AppPageHeader } from '../components/AppPageHeader'
import { FilePickerPanel } from '../components/FilePickerPanel'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { StatusPanel } from '../components/StatusPanel'
import { ChipItem, OptionChipGroup } from '../components/OptionChipGroup'
import { UiConstants } from '../common/UiConstants'

const DOC_SOURCE_SUFFIXES: string[] = ['.txt', '.csv', '.json', '.xml', '.html', '.md', '.log']

const SOURCE_ENCODINGS: string[] = ['utf-8', 'gbk', 'utf-16le']

interface PendingDocumentOutput {
  fileName: string
  tempPath: string
  sourceIndex: number
}

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
      Column() {
        AppPageHeader({ title: '文档格式转换', onBack: () => router.back() })
          .padding({ left: 4, right: 16 })
        Scroll() {
          Column({ space: UiConstants.SECTION_GAP }) {
            this.FileSection()
            this.FormatSection()
            this.EncodingSection()
            this.ActionSection()
          }
          .width('100%')
          .constraintSize({ maxWidth: UiConstants.CONTENT_MAX_WIDTH })
          .padding({ left: UiConstants.PAGE_PADDING_PHONE, right: UiConstants.PAGE_PADDING_PHONE, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }

  @Builder
  FileSection() {
    FilePickerPanel({
      title: '选择文档',
      description: '支持 TXT、CSV、JSON、XML、HTML、MD、LOG',
      asset: $r('app.media.ui_picker_document'),
      buttonLabel: '选择文件',
      selectedName: this.selectedFileSummary(),
      isEnabled: !this.converting,
      onPick: () => this.pickFiles()
    })
  }

  @Builder
  FormatSection() {
    Column({ space: 8 }) {
      Text('目标格式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

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

      OptionChipGroup({
        items: this.getEncodingItems(),
        selectedKey: this.sourceEncoding,
        disabled: this.converting,
        onSelect: (encoding: string) => {
          this.sourceEncoding = encoding
        }
      })

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
      PrimaryActionButton({
        label: '开始转换',
        isEnabled: !this.converting && this.selectedFiles.length > 0,
        loading: this.converting,
        onTap: () => this.startConvert()
      })

      if (this.converting) {
        ConvertProgressBar({ progress: this.progress, total: 100, showText: true })
      }

      StatusPanel({
        message: this.statusText,
        success: this.successCount > 0,
        error: this.statusText.length > 0 && this.successCount === 0,
        loading: false
      })
    }
    .width('100%')
  }

  private selectedFileSummary(): string {
    if (this.selectedFiles.length === 0) {
      return ''
    }
    if (this.selectedFiles.length === 1) {
      return FileUtils.getFileName(this.selectedFiles[0])
    }
    return `${FileUtils.getFileName(this.selectedFiles[0])} 等 ${this.selectedFiles.length} 个文件`
  }

  private getEncodingItems(): ChipItem[] {
    const items: ChipItem[] = []
    for (const encoding of SOURCE_ENCODINGS) {
      items.push({ key: encoding, label: encoding.toUpperCase(), enabled: true, developing: false })
    }
    return items
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

    const context = getContext(this) as common.UIAbilityContext
    const total = this.selectedFiles.length
    const pendingOutputs: PendingDocumentOutput[] = []
    let failedCount = 0

    try {
      for (let i = 0; i < total; i++) {
        const uri: string = this.selectedFiles[i]
        const srcExt: string = FileUtils.getExtension(uri)
        const baseName: string = FileUtils.getBaseName(uri)

        try {
          const text = await this.readFileAsText(uri)
          this.progress = Math.round((i + 0.3) / total * 60)

          const converted = this.convertContent(text, srcExt, this.targetFormat)
          if (converted === null) {
            failedCount++
            this.statusText = `第 ${i + 1} 个文件不支持转为 ${this.targetFormat.toUpperCase()}`
            this.progress = Math.round((i + 1) / total * 60)
            continue
          }

          const fileName = `${baseName}.${this.targetFormat}`
          const tempPath = `${context.cacheDir}/${FileUtils.genTaskId()}.${this.targetFormat}`
          try {
            this.writeContent(tempPath, converted)
          } catch (e) {
            try { fs.unlinkSync(tempPath) } catch (_cleanupError) {}
            const writeError = e as BusinessError
            throw new Error(writeError.message)
          }
          pendingOutputs.push({ fileName: fileName, tempPath: tempPath, sourceIndex: i })
        } catch (e) {
          failedCount++
          const err = e as BusinessError
          this.statusText = `第 ${i + 1} 个文件失败:${err.message}`
        }
        this.progress = Math.round((i + 1) / total * 60)
      }

      if (pendingOutputs.length > 0) {
        const fileNames: string[] = []
        for (const output of pendingOutputs) {
          fileNames.push(output.fileName)
        }
        const targetUris: string[] = await this.saveService.getSavePaths(fileNames)
        for (let i = 0; i < pendingOutputs.length; i++) {
          const output = pendingOutputs[i]
          if (FileUtils.copyFile(output.tempPath, targetUris[i])) {
            this.successCount++
          } else {
            failedCount++
            try { fs.unlinkSync(targetUris[i]) } catch (_cleanupError) {}
            this.statusText = `第 ${output.sourceIndex + 1} 个文件保存失败`
          }
          this.progress = 60 + Math.round((i + 1) / pendingOutputs.length * 40)
        }
      }
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `批量保存未完成:${err.message}`
    } finally {
      for (const output of pendingOutputs) {
        try { fs.unlinkSync(output.tempPath) } catch (_e) {}
      }
      this.converting = false
    }

    if (this.successCount > 0) {
      this.statusText = failedCount > 0 ?
        `已保存 ${this.successCount} 个文件,${failedCount} 个失败` :
        `已成功转换并保存 ${this.successCount} 个文件`
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
