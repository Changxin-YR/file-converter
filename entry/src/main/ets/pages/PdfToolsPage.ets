/**
 * PDF 工具箱页面
 * 提供图片/文本/HTML 转 PDF 及受限的 PDF 文本导出功能。
 * 纯离线实现,不依赖网络。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction, router } from '@kit.ArkUI'
import { fileIo as fs } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { FilePickerService } from '../services/FilePickerService'
import { SaveService } from '../services/SaveService'
import { FileUtils } from '../common/Utils'
import { PdfGenerator, PdfImageData } from '../common/converters/PdfGenerator'
import { WordGenerator } from '../common/converters/WordGenerator'
import { TextCodec } from '../common/converters/TextCodec'
import { PdfTextExtractResult, PdfTextExtractor } from '../common/converters/PdfTextExtractor'
import { AppPageHeader } from '../components/AppPageHeader'
import { FilePickerPanel } from '../components/FilePickerPanel'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { StatusPanel } from '../components/StatusPanel'
import { ToolListData, ToolListItem } from '../components/ToolListItem'
import { UiConstants } from '../common/UiConstants'

interface PdfTool {
  id: string
  title: string
  description: string
  asset: Resource
  available: boolean
}

const PDF_TOOLS: PdfTool[] = [
  { id: 'jpg2pdf', title: '图片转 PDF', description: 'JPG、PNG、WEBP、BMP 图片合成 PDF', asset: $r('app.media.ui_pdf_image'), available: true },
  { id: 'word2pdf', title: '文本转PDF', description: 'TXT/MD转为PDF', asset: $r('app.media.ui_pdf_text'), available: true },
  { id: 'html2pdf', title: 'HTML 转 PDF', description: '提取 HTML 文本并生成 PDF', asset: $r('app.media.ui_pdf_html'), available: true },
  { id: 'pdf2word', title: 'PDF 转 Word', description: '项目自产文本PDF', asset: $r('app.media.ui_pdf_word'), available: true },
  { id: 'pdf2md', title: 'PDF 转 Markdown', description: '项目自产文本PDF', asset: $r('app.media.ui_pdf_markdown'), available: true }
]

@Entry
@Component
struct PdfToolsPage {
  @State currentTool: string = ''
  @State selectedFiles: string[] = []
  @State processing: boolean = false
  @State statusText: string = ''

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
        AppPageHeader({
          title: this.currentTool.length === 0 ? 'PDF 工具箱' : this.getToolTitle(),
          onBack: () => {
            if (this.currentTool.length > 0) {
              this.currentTool = ''
              this.selectedFiles = []
              this.statusText = ''
              return
            }
            router.back()
          }
        })
          .padding({ left: 4, right: 16 })
        Scroll() {
          Column({ space: UiConstants.SECTION_GAP }) {
            if (this.currentTool.length === 0) {
              this.ToolGridSection()
            } else {
              this.ToolDetailSection()
            }
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
  ToolGridSection() {
    Column({ space: 12 }) {
      Image($r('app.media.ui_hero_pdf'))
        .accessibilityText('PDF 工具插图')
        .width('100%')
        .height(132)
        .objectFit(ImageFit.Contain)
      Text('PDF 转换工具')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text('所有处理均在设备本地完成')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Column({ space: 10 }) {
        ForEach(PDF_TOOLS, (tool: PdfTool) => {
          ToolListItem({
            data: this.toToolListData(tool),
            onTap: (key: string) => this.selectTool(key)
          })
        }, (tool: PdfTool) => tool.id)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ToolDetailSection() {
    Column({ space: 16 }) {
      this.FilePickSection()
      this.ExecuteSection()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FilePickSection() {
    FilePickerPanel({
      title: '选择文件',
      description: this.getFileHint(),
      asset: this.getToolAsset(),
      buttonLabel: '选择文件',
      selectedName: this.selectedFileSummary(),
      isEnabled: !this.processing,
      onPick: () => this.pickFiles()
    })
  }

  @Builder
  ExecuteSection() {
    Column({ space: 12 }) {
      PrimaryActionButton({
        label: this.getActionLabel(),
        isEnabled: !this.processing && this.selectedFiles.length > 0,
        loading: this.processing,
        onTap: () => this.executeTool()
      })
      StatusPanel({
        message: this.statusText,
        success: this.statusText.startsWith('已'),
        error: this.statusText.length > 0 && !this.statusText.startsWith('已'),
        loading: false
      })
    }
    .width('100%')
  }

  private toToolListData(tool: PdfTool): ToolListData {
    return {
      key: tool.id,
      title: tool.title,
      description: tool.description,
      asset: tool.asset,
      enabled: tool.available
    }
  }

  private selectTool(key: string): void {
    this.currentTool = key
    this.selectedFiles = []
    this.statusText = ''
  }

  private getToolAsset(): Resource {
    for (const tool of PDF_TOOLS) {
      if (tool.id === this.currentTool) {
        return tool.asset
      }
    }
    return $r('app.media.ui_hero_pdf')
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

  private getToolTitle(): string {
    for (const tool of PDF_TOOLS) {
      if (tool.id === this.currentTool) {
        return tool.title
      }
    }
    return 'PDF 工具箱'
  }

  private getFileHint(): string {
    switch (this.currentTool) {
      case 'jpg2pdf':
        return '选择图片文件(JPG/PNG/WEBP/BMP)'
      case 'word2pdf':
        return '选择文本文档(.txt/.md)'
      case 'html2pdf':
        return '选择HTML文件'
      default:
        return '选择PDF文件'
    }
  }

  private getActionLabel(): string {
    switch (this.currentTool) {
      case 'jpg2pdf': return '转换为PDF并保存'
      case 'word2pdf': return '转换为PDF并保存'
      case 'html2pdf': return '转换为PDF并保存'
      case 'pdf2word': return '转换为Word并保存'
      case 'pdf2md': return '转换为Markdown并保存'
      default: return '转换并保存'
    }
  }

  private async pickFiles(): Promise<void> {
    if (!this.pickerService) {
      return
    }
    try {
      const isImage = this.currentTool === 'jpg2pdf'
      if (isImage) {
        const uris: string[] = await this.pickerService.pickImages(9)
        if (uris.length > 0) {
          this.selectedFiles = uris
          this.statusText = ''
        }
      } else {
        const suffixes = this.getSourceSuffixes()
        const uris: string[] = await this.pickerService.pickFiles(suffixes, 5)
        if (uris.length > 0) {
          this.selectedFiles = uris
          this.statusText = ''
        }
      }
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `选择文件失败:${err.message}`
    }
  }

  private getSourceSuffixes(): string[] {
    switch (this.currentTool) {
      case 'word2pdf': return ['.txt', '.md']
      case 'html2pdf': return ['.html', '.htm']
      default: return ['.pdf']
    }
  }

  private async executeTool(): Promise<void> {
    if (this.selectedFiles.length === 0 || !this.saveService) {
      return
    }
    this.processing = true
    this.statusText = ''

    try {
      switch (this.currentTool) {
        case 'jpg2pdf':
          await this.doJpgToPdf()
          break
        case 'word2pdf':
          await this.doTextToPdf()
          break
        case 'html2pdf':
          await this.doHtmlToPdf()
          break
        case 'pdf2word':
          await this.doPdfToText('doc')
          break
        case 'pdf2md':
          await this.doPdfToText('md')
          break
        default:
          this.statusText = '该功能暂未实现'
      }
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `处理失败:${err.message}`
    }

    this.processing = false
  }

  private async doJpgToPdf(): Promise<void> {
    const imageDataList: PdfImageData[] = []

    for (const uri of this.selectedFiles) {
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      try {
        const imgSource = image.createImageSource(file.fd)
        const imgInfo = await imgSource.getImageInfo()
        const pixelMap = await imgSource.createPixelMap()

        const packer = image.createImagePacker()
        const packOpts: image.PackingOption = {
          format: 'image/jpeg',
          quality: 85
        }
        const jpegBuffer: ArrayBuffer = await packer.packing(pixelMap, packOpts)

        imageDataList.push({
          jpegBytes: jpegBuffer,
          width: imgInfo.size.width,
          height: imgInfo.size.height
        })

        pixelMap.release().catch(() => {})
        imgSource.release()
        packer.release()
      } finally {
        fs.closeSync(file)
      }
    }

    const pdfData = PdfGenerator.generateFromImages(imageDataList)
    const targetUri = await this.saveService!.getSavePath('images_combined.pdf')
    const outFile = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY)
    try {
      fs.writeSync(outFile.fd, pdfData)
    } finally {
      fs.closeSync(outFile)
    }
    this.statusText = `已将 ${this.selectedFiles.length} 张图片转换为PDF并保存`
  }

  private async doTextToPdf(): Promise<void> {
    for (const uri of this.selectedFiles) {
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      let text = ''
      try {
        const stat = fs.statSync(file.fd)
        if (stat.size > 10 * 1024 * 1024) {
          this.statusText = '文件过大(超过10MB),请选择较小的文件'
          return
        }
        const buffer = new ArrayBuffer(stat.size)
        const bytesRead = fs.readSync(file.fd, buffer)
        text = TextCodec.decode(buffer.slice(0, bytesRead), 'utf-8')
      } finally {
        fs.closeSync(file)
      }
      const pdfData = PdfGenerator.generate(text)
      const baseName = FileUtils.getBaseName(uri)
      const targetUri = await this.saveService!.getSavePath(`${baseName}.pdf`)
      const outFile = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY)
      try {
        fs.writeSync(outFile.fd, pdfData)
      } finally {
        fs.closeSync(outFile)
      }
    }
    this.statusText = `已将 ${this.selectedFiles.length} 个文档转换为PDF`
  }

  private async doHtmlToPdf(): Promise<void> {
    for (const uri of this.selectedFiles) {
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      let html = ''
      try {
        const stat = fs.statSync(file.fd)
        if (stat.size > 10 * 1024 * 1024) {
          this.statusText = '文件过大(超过10MB),请选择较小的文件'
          return
        }
        const buffer = new ArrayBuffer(stat.size)
        const bytesRead = fs.readSync(file.fd, buffer)
        html = TextCodec.decode(buffer.slice(0, bytesRead), 'utf-8')
      } finally {
        fs.closeSync(file)
      }
      const text = html.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&')
      const pdfData = PdfGenerator.generate(text)
      const baseName = FileUtils.getBaseName(uri)
      const targetUri = await this.saveService!.getSavePath(`${baseName}.pdf`)
      const outFile = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY)
      try {
        fs.writeSync(outFile.fd, pdfData)
      } finally {
        fs.closeSync(outFile)
      }
    }
    this.statusText = `已将 ${this.selectedFiles.length} 个HTML转换为PDF`
  }

  private async doPdfToText(targetExt: string): Promise<void> {
    for (const uri of this.selectedFiles) {
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      let extracted: PdfTextExtractResult = { success: false, text: '', errorMsg: 'PDF 文本提取失败' }
      try {
        const stat = fs.statSync(file.fd)
        if (stat.size > 20 * 1024 * 1024) {
          this.statusText = '文件过大(超过20MB),请选择较小的文件'
          return
        }
        const buffer = new ArrayBuffer(stat.size)
        const bytesRead = fs.readSync(file.fd, buffer)
        extracted = PdfTextExtractor.extract(buffer.slice(0, bytesRead))
      } finally {
        fs.closeSync(file)
      }
      if (!extracted.success) {
        throw new Error(extracted.errorMsg ?? 'PDF 文本提取失败')
      }
      let output: string
      if (targetExt === 'doc') {
        output = WordGenerator.generate(extracted.text)
      } else {
        output = extracted.text
      }
      const baseName = FileUtils.getBaseName(uri)
      const targetUri = await this.saveService!.getSavePath(`${baseName}.${targetExt}`)
      const outFile = fs.openSync(targetUri, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY)
      try {
        const encoded = TextCodec.encode(output)
        fs.writeSync(outFile.fd, encoded)
      } finally {
        fs.closeSync(outFile)
      }
    }
    this.statusText = `已将 ${this.selectedFiles.length} 个PDF转换为 ${targetExt.toUpperCase()}`
  }

}
