/**
 * PDF 工具箱页面
 * 提供 PDF 合并、拆分、压缩、格式转换、水印、加密、页码、旋转等功能
 * 纯离线实现,不依赖网络。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import { fileIo as fs } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { FilePickerService } from '../services/FilePickerService'
import { SaveService } from '../services/SaveService'
import { FileUtils } from '../common/Utils'
import { PdfGenerator, PdfImageData } from '../common/converters/PdfGenerator'
import { WordGenerator } from '../common/converters/WordGenerator'
import { TextCodec } from '../common/converters/TextCodec'
import { PdfTextExtractResult, PdfTextExtractor } from '../common/converters/PdfTextExtractor'

interface PdfTool {
  id: string
  title: string
  description: string
  available: boolean
}

const PDF_TOOLS: PdfTool[] = [
  { id: 'jpg2pdf', title: 'JPG转PDF', description: '将图片转换为PDF文件', available: true },
  { id: 'word2pdf', title: '文本转PDF', description: 'TXT/MD转为PDF', available: true },
  { id: 'html2pdf', title: 'HTML转PDF', description: '将网页文件转为PDF', available: true },
  { id: 'pdf2word', title: 'PDF转Word', description: '项目自产文本PDF', available: true },
  { id: 'pdf2md', title: 'PDF转Markdown', description: '项目自产文本PDF', available: true }
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
      Scroll() {
        Column({ space: 16 }) {
          if (this.currentTool.length === 0) {
            this.ToolGridSection()
          } else {
            this.ToolDetailSection()
          }
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .title(this.currentTool.length === 0 ? 'PDF 工具箱' : this.getToolTitle())
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  ToolGridSection() {
    Column({ space: 12 }) {
      Text('可用工具')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(PDF_TOOLS, (tool: PdfTool) => {
          this.ToolChip(tool)
        }, (tool: PdfTool) => tool.id)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ToolChip(tool: PdfTool) {
    Column({ space: 4 }) {
      Text(tool.title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(tool.available ? $r('app.color.text_primary') : $r('app.color.text_tertiary'))
      Text(tool.description)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('47%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .margin({ right: '3%', bottom: 10 })
    .borderRadius(10)
    .backgroundColor($r('app.color.card_background'))
    .opacity(tool.available ? 1 : 0.5)
    .onClick(() => {
      if (!tool.available) {
        promptAction.showToast({ message: `${tool.title} 功能开发中` })
        return
      }
      this.currentTool = tool.id
      this.selectedFiles = []
      this.statusText = ''
    })
  }

  @Builder
  ToolDetailSection() {
    Column({ space: 16 }) {
      Button('< 返回工具列表')
        .fontSize(13)
        .type(ButtonType.Normal)
        .height(32)
        .backgroundColor($r('app.color.chip_background'))
        .fontColor($r('app.color.primary'))
        .onClick(() => { this.currentTool = '' })

      this.FilePickSection()
      this.ExecuteSection()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FilePickSection() {
    Column({ space: 8 }) {
      Row() {
        Text('选择文件')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button('选择')
          .height(34)
          .fontSize(13)
          .enabled(!this.processing)
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
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .borderRadius(8)
          .backgroundColor($r('app.color.card_background'))
        }, (file: string) => file)
      } else {
        Column() {
          Text(this.getFileHint())
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height(80)
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
  ExecuteSection() {
    Column({ space: 12 }) {
      Button(this.processing ? '处理中...' : this.getActionLabel())
        .width('100%')
        .height(44)
        .fontSize(16)
        .enabled(!this.processing && this.selectedFiles.length > 0)
        .onClick(() => this.executeTool())

      if (this.statusText.length > 0 && !this.processing) {
        Text(this.statusText)
          .fontSize(13)
          .fontColor(this.statusText.startsWith('已') ? $r('app.color.success') : $r('app.color.error'))
      }
    }
    .width('100%')
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
      let rawText = ''
      try {
        const stat = fs.statSync(file.fd)
        if (stat.size > 20 * 1024 * 1024) {
          this.statusText = '文件过大(超过20MB),请选择较小的文件'
          return
        }
        const buffer = new ArrayBuffer(stat.size)
        const bytesRead = fs.readSync(file.fd, buffer)
        rawText = TextCodec.decode(buffer.slice(0, bytesRead), 'utf-8')
      } finally {
        fs.closeSync(file)
      }
      const extracted: PdfTextExtractResult = PdfTextExtractor.extract(rawText)
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
