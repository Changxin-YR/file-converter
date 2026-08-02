/**
 * 图片格式转换页
 * 选择图片 → 选择目标格式 → 转换 → 保存到相册
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction, router } from '@kit.ArkUI'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { FilePickerService } from '../services/FilePickerService'
import { ImageConvertService } from '../services/ImageConvertService'
import { FormatInfo } from '../common/FormatTypes'
import { ConvertOptions, ConvertStatus, ConvertType, ConvertTask } from '../common/ConvertTask'
import { FileUtils } from '../common/Utils'
import { FormatSelector } from '../components/FormatSelector'
import { ConvertProgressBar } from '../components/ConvertProgressBar'
import { AppPageHeader } from '../components/AppPageHeader'
import { FilePickerPanel } from '../components/FilePickerPanel'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { StatusPanel } from '../components/StatusPanel'
import { UiConstants } from '../common/UiConstants'

const IMAGE_TARGET_FORMATS: FormatInfo[] = [
  { extension: 'png', mimeType: 'image/png', displayName: 'PNG', category: ConvertType.IMAGE, nativeSupported: true },
  { extension: 'jpg', mimeType: 'image/jpeg', displayName: 'JPG', category: ConvertType.IMAGE, nativeSupported: true },
  { extension: 'jpeg', mimeType: 'image/jpeg', displayName: 'JPEG', category: ConvertType.IMAGE, nativeSupported: true },
  { extension: 'webp', mimeType: 'image/webp', displayName: 'WEBP', category: ConvertType.IMAGE, nativeSupported: true },
  { extension: 'bmp', mimeType: 'image/bmp', displayName: 'BMP', category: ConvertType.IMAGE, nativeSupported: true },
  { extension: 'heif', mimeType: 'image/heif', displayName: 'HEIF', category: ConvertType.IMAGE, nativeSupported: false }
]

@Entry
@Component
struct ImageConvertPage {
  @State selectedFiles: string[] = []
  @State targetFormat: string = 'png'
  @State quality: number = 90
  @State converting: boolean = false
  @State progress: number = 0
  @State statusText: string = ''
  @State successCount: number = 0

  private pickerService?: FilePickerService
  private imageService: ImageConvertService = new ImageConvertService()

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.pickerService = new FilePickerService(context)
  }

  build() {
    Navigation() {
      Column() {
        AppPageHeader({ title: '图片格式转换', onBack: () => router.back() })
          .padding({ left: 4, right: 16 })
        Scroll() {
          Column({ space: UiConstants.SECTION_GAP }) {
            this.FileSection()
            this.FormatSection()
            this.QualitySection()
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
      title: '选择图片',
      description: '支持 PNG、JPG、JPEG、WEBP、BMP',
      asset: $r('app.media.ui_picker_image'),
      buttonLabel: '选择图片',
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
        formats: IMAGE_TARGET_FORMATS,
        selected: this.targetFormat,
        disabled: this.converting,
        selectCallback: (ext: string) => {
          this.targetFormat = ext
        }
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  QualitySection() {
    Column({ space: 8 }) {
      Row() {
        Text('输出质量')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${this.quality}%`)
          .fontSize(14)
          .fontColor($r('app.color.brand_primary'))
      }
      .width('100%')

      Slider({ value: this.quality, min: 10, max: 100, step: 5 })
        .selectedColor($r('app.color.brand_primary'))
        .trackColor($r('app.color.border_subtle'))
        .onChange((value: number) => {
          this.quality = value
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ActionSection() {
    Column({ space: 12 }) {
      PrimaryActionButton({
        label: '开始转换并保存到相册',
        isEnabled: !this.converting && this.selectedFiles.length > 0,
        loading: this.converting,
        onTap: () => this.startConvertAndSave()
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
    return `${FileUtils.getFileName(this.selectedFiles[0])} 等 ${this.selectedFiles.length} 张图片`
  }

  private async pickFiles(): Promise<void> {
    if (!this.pickerService) {
      return
    }
    try {
      const uris: string[] = await this.pickerService.pickImages(9)
      if (uris.length > 0) {
        this.selectedFiles = uris
        this.statusText = ''
        this.progress = 0
        this.successCount = 0
      }
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `选择图片失败:${err.message}`
    }
  }

  private async startConvertAndSave(): Promise<void> {
    if (this.selectedFiles.length === 0) {
      return
    }
    const NATIVE_FORMATS: string[] = ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'heif']
    if (!NATIVE_FORMATS.includes(this.targetFormat)) {
      this.statusText = `${this.targetFormat.toUpperCase()} 格式暂不支持离线转换`
      return
    }
    this.converting = true
    this.progress = 0
    this.statusText = ''
    this.successCount = 0

    const context = getContext(this) as common.UIAbilityContext
    const total = this.selectedFiles.length
    const convertedPaths: string[] = []
    const options: ConvertOptions = { quality: this.quality }

    // 1. 转换所有图片到应用沙箱
    for (let i = 0; i < total; i++) {
      const uri: string = this.selectedFiles[i]
      const srcExt: string = FileUtils.getExtension(uri)
      if (srcExt === this.targetFormat) {
        this.progress = Math.round((i + 1) / total * 50)
        continue
      }
      const baseName: string = FileUtils.getBaseName(uri)
      const targetPath = `${context.filesDir}/${baseName}.${this.targetFormat}`
      const result = await this.imageService.convertFormat(
        uri,
        targetPath,
        this.targetFormat,
        options
      )
      if (result.success && result.targetPath) {
        convertedPaths.push(result.targetPath)
      } else {
        this.statusText = `第 ${i + 1} 个文件转换失败:${result.errorMsg ?? '未知错误'}`
      }
      this.progress = Math.round((i + 1) / total * 50)
    }

    if (convertedPaths.length === 0) {
      this.converting = false
      if (this.statusText.length === 0) {
        this.statusText = '所选图片均与目标格式相同,无需转换'
      }
      return
    }

    // 2. 通过系统弹窗保存到相册
    try {
      await this.saveToAlbum(context, convertedPaths)
      this.successCount = convertedPaths.length
      this.statusText = `已成功保存 ${convertedPaths.length} 张图片到相册`
      promptAction.showToast({ message: `已保存 ${convertedPaths.length} 张图片到相册` })
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `保存到相册失败:${err.message}`
    }

    // 3. 清理沙箱临时文件
    for (const path of convertedPaths) {
      try {
        fs.unlinkSync(path)
      } catch (_e) {
        // 忽略清理失败
      }
    }

    this.progress = 100
    this.converting = false
  }

  private async saveToAlbum(context: common.UIAbilityContext, filePaths: string[]): Promise<void> {
    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context)
    const photoType = photoAccessHelper.PhotoType.IMAGE
    const configs: photoAccessHelper.PhotoCreationConfig[] = []
    for (const filePath of filePaths) {
      const baseName = FileUtils.getBaseName(filePath)
      configs.push({
        title: baseName,
        fileNameExtension: this.targetFormat,
        photoType: photoType
      })
    }

    const destUris: string[] = await phAccessHelper.showAssetsCreationDialog(filePaths, configs)

    for (let i = 0; i < destUris.length; i++) {
      const srcPath = filePaths[i]
      const destUri = destUris[i]
      const srcFile = fs.openSync(srcPath, fs.OpenMode.READ_ONLY)
      const dstFile = fs.openSync(destUri, fs.OpenMode.WRITE_ONLY)
      try {
        const stat = fs.statSync(srcPath)
        const buffer = new ArrayBuffer(stat.size)
        fs.readSync(srcFile.fd, buffer)
        fs.writeSync(dstFile.fd, buffer)
      } finally {
        fs.closeSync(srcFile)
        fs.closeSync(dstFile)
      }
      this.progress = 50 + Math.round((i + 1) / destUris.length * 50)
    }
  }
}
