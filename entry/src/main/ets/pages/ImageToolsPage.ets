/**
 * 图片工具页
 * 提供图像调整(缩放)、裁剪、拼贴制作、颜色选择器功能
 * 基于 @kit.ImageKit PixelMap 离线完成。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { router } from '@kit.ArkUI'
import { FilePickerService } from '../services/FilePickerService'
import { FileUtils } from '../common/Utils'
import { AppPageHeader } from '../components/AppPageHeader'
import { FilePickerPanel } from '../components/FilePickerPanel'
import { MetricInputField } from '../components/MetricInputField'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { SegmentItem, SegmentedControl } from '../components/SegmentedControl'
import { StatusPanel } from '../components/StatusPanel'
import { UiConstants } from '../common/UiConstants'

const IMAGE_TOOL_ITEMS: SegmentItem[] = [
  { key: 'resize', label: '图像调整', enabled: true },
  { key: 'crop', label: '裁剪图片', enabled: true },
  { key: 'color', label: '颜色提取', enabled: true }
]

@Entry
@Component
struct ImageToolsPage {
  @State currentTool: number = 0
  @State selectedFile: string = ''
  @State widthText: string = ''
  @State heightText: string = ''
  @State keepRatio: boolean = true
  @State cropX: string = '0'
  @State cropY: string = '0'
  @State cropW: string = ''
  @State cropH: string = ''
  @State processing: boolean = false
  @State statusText: string = ''
  @State pickedColor: string = ''

  private pickerService?: FilePickerService
  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.pickerService = new FilePickerService(context)
  }

  build() {
    Navigation() {
      Column() {
        AppPageHeader({ title: '图片工具', onBack: () => router.back() })
          .padding({ left: 4, right: 16 })
        Scroll() {
          Column({ space: UiConstants.SECTION_GAP }) {
            this.ToolSelector()
            this.FileSection()
            if (this.currentTool === 0) {
              this.ResizeSection()
            } else if (this.currentTool === 1) {
              this.CropSection()
            } else if (this.currentTool === 2) {
              this.ColorPickerSection()
            }
            this.StatusSection()
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
  ToolSelector() {
    SegmentedControl({
      items: IMAGE_TOOL_ITEMS,
      selectedKey: this.getToolKey(),
      onSelect: (key: string) => {
        if (key === 'resize') {
          this.currentTool = 0
        } else if (key === 'crop') {
          this.currentTool = 1
        } else {
          this.currentTool = 2
        }
        this.statusText = ''
      }
    })
  }

  @Builder
  FileSection() {
    FilePickerPanel({
      title: '选择图片',
      description: '选择一张图片进行本地处理',
      asset: $r('app.media.ui_tool_image_edit'),
      buttonLabel: '选择图片',
      selectedName: this.selectedFile.length > 0 ? FileUtils.getFileName(this.selectedFile) : '',
      isEnabled: !this.processing,
      onPick: () => this.pickFile()
    })
  }

  @Builder
  ResizeSection() {
    Column({ space: 12 }) {
      Text('调整尺寸')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Row({ space: 12 }) {
        MetricInputField({
          label: '宽度', value: this.widthText, placeholder: '宽度', suffix: 'px', isEnabled: !this.processing,
          onChange: (value: string) => { this.widthText = value }
        })
          .layoutWeight(1)
        MetricInputField({
          label: '高度', value: this.heightText, placeholder: '高度', suffix: 'px', isEnabled: !this.processing,
          onChange: (value: string) => { this.heightText = value }
        })
          .layoutWeight(1)
      }
      .width('100%')

      Row() {
        Text('保持宽高比')
          .fontSize(14)
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.keepRatio })
          .onChange((isOn: boolean) => {
            this.keepRatio = isOn
          })
      }
      .width('100%')

      PrimaryActionButton({
        label: '调整并保存',
        isEnabled: !this.processing && this.selectedFile.length > 0,
        loading: this.processing,
        onTap: () => this.doResize()
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  CropSection() {
    Column({ space: 12 }) {
      Text('裁剪区域')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Row({ space: 12 }) {
        MetricInputField({
          label: 'X 起点', value: this.cropX, placeholder: '0', suffix: 'px', isEnabled: !this.processing,
          onChange: (value: string) => { this.cropX = value }
        })
          .layoutWeight(1)
        MetricInputField({
          label: 'Y 起点', value: this.cropY, placeholder: '0', suffix: 'px', isEnabled: !this.processing,
          onChange: (value: string) => { this.cropY = value }
        })
          .layoutWeight(1)
      }
      .width('100%')

      Row({ space: 12 }) {
        MetricInputField({
          label: '宽度', value: this.cropW, placeholder: '宽度', suffix: 'px', isEnabled: !this.processing,
          onChange: (value: string) => { this.cropW = value }
        })
          .layoutWeight(1)
        MetricInputField({
          label: '高度', value: this.cropH, placeholder: '高度', suffix: 'px', isEnabled: !this.processing,
          onChange: (value: string) => { this.cropH = value }
        })
          .layoutWeight(1)
      }
      .width('100%')

      Text('从(X,Y)坐标开始,裁剪指定宽高区域')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))

      PrimaryActionButton({
        label: '裁剪并保存',
        isEnabled: !this.processing && this.selectedFile.length > 0,
        loading: this.processing,
        onTap: () => this.doCrop()
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ColorPickerSection() {
    Column({ space: 12 }) {
      Text('提取图片主色调')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text('从图片中央区域采样获取主色调')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))

      PrimaryActionButton({
        label: '提取颜色',
        isEnabled: !this.processing && this.selectedFile.length > 0,
        loading: this.processing,
        onTap: () => this.doColorPick()
      })

      if (this.pickedColor.length > 0) {
        Row({ space: 12 }) {
          Row()
            .width(48)
            .height(48)
            .borderRadius(8)
            .backgroundColor(this.pickedColor)
            .borderWidth(1)
            .borderColor($r('app.color.border'))
          Column({ space: 4 }) {
            Text(this.pickedColor)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.brand_primary'))
            Text('中央区域平均颜色')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(12)
        .borderRadius(UiConstants.CARD_RADIUS)
        .backgroundColor($r('app.color.surface_primary'))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  StatusSection() {
    StatusPanel({
      message: this.statusText,
      success: this.statusText.startsWith('已'),
      error: this.statusText.length > 0 && !this.statusText.startsWith('已'),
      loading: false
    })
  }

  private getToolKey(): string {
    if (this.currentTool === 0) {
      return 'resize'
    }
    if (this.currentTool === 1) {
      return 'crop'
    }
    return 'color'
  }

  private async pickFile(): Promise<void> {
    if (!this.pickerService) {
      return
    }
    try {
      const uris: string[] = await this.pickerService.pickImages(1)
      if (uris.length > 0) {
        this.selectedFile = uris[0]
        this.statusText = ''
        this.pickedColor = ''
      }
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `选择图片失败:${err.message}`
    }
  }

  private async doResize(): Promise<void> {
    const width = parseInt(this.widthText, 10)
    const height = parseInt(this.heightText, 10)
    if ((!Number.isInteger(width) || width <= 0) && (!Number.isInteger(height) || height <= 0)) {
      this.statusText = '请输入有效的宽度或高度'
      return
    }
    this.processing = true
    this.statusText = ''
    try {
      const context = getContext(this) as common.UIAbilityContext
      const pixelMap = await this.decodeImage(this.selectedFile)
      const info: image.ImageInfo = await pixelMap.getImageInfo()
      const srcW = info.size.width
      const srcH = info.size.height
      let targetW = width > 0 ? width : srcW
      let targetH = height > 0 ? height : srcH
      if (this.keepRatio) {
        if (width > 0 && height <= 0) {
          targetH = Math.round(width / (srcW / srcH))
        } else if (height > 0 && width <= 0) {
          targetW = Math.round(height * (srcW / srcH))
        }
      }
      await pixelMap.scale(targetW / srcW, targetH / srcH)
      await this.savePixelMap(context, pixelMap, 'resized')
      pixelMap.release()
      this.statusText = `已调整为 ${targetW}x${targetH} 并保存`
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `调整失败:${err.message}`
    }
    this.processing = false
  }

  private async doCrop(): Promise<void> {
    const x = parseInt(this.cropX, 10) || 0
    const y = parseInt(this.cropY, 10) || 0
    const w = parseInt(this.cropW, 10)
    const h = parseInt(this.cropH, 10)
    if (!Number.isInteger(w) || w <= 0 || !Number.isInteger(h) || h <= 0) {
      this.statusText = '请输入有效的裁剪宽高'
      return
    }
    this.processing = true
    this.statusText = ''
    try {
      const context = getContext(this) as common.UIAbilityContext
      const pixelMap = await this.decodeImage(this.selectedFile)
      await pixelMap.crop({ x: x, y: y, size: { width: w, height: h } })
      await this.savePixelMap(context, pixelMap, 'cropped')
      pixelMap.release()
      this.statusText = `已裁剪 ${w}x${h} 区域并保存`
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `裁剪失败:${err.message}`
    }
    this.processing = false
  }

  private async doColorPick(): Promise<void> {
    this.processing = true
    this.statusText = ''
    this.pickedColor = ''
    try {
      const pixelMap = await this.decodeImage(this.selectedFile)
      const info: image.ImageInfo = await pixelMap.getImageInfo()
      const totalPixels = info.size.width * info.size.height
      const buffer = new ArrayBuffer(totalPixels * 4)
      await pixelMap.readPixelsToBuffer(buffer)
      const view = new Uint8Array(buffer)
      // 从中心 5x5 区域采样取平均色
      const cx = Math.floor(info.size.width / 2)
      const cy = Math.floor(info.size.height / 2)
      const sampleRadius = 2
      let r = 0, g = 0, b = 0, count = 0
      for (let dy = -sampleRadius; dy <= sampleRadius; dy++) {
        for (let dx = -sampleRadius; dx <= sampleRadius; dx++) {
          const px = cx + dx
          const py = cy + dy
          if (px >= 0 && px < info.size.width && py >= 0 && py < info.size.height) {
            const idx = (py * info.size.width + px) * 4
            r += view[idx]
            g += view[idx + 1]
            b += view[idx + 2]
            count++
          }
        }
      }
      r = Math.round(r / count)
      g = Math.round(g / count)
      b = Math.round(b / count)
      this.pickedColor = `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`
      pixelMap.release()
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `提取颜色失败:${err.message}`
    }
    this.processing = false
  }

  private async decodeImage(uri: string): Promise<image.PixelMap> {
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
    try {
      const imageSource = image.createImageSource(file.fd)
      const pixelMap = await imageSource.createPixelMap({
        editable: true,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      })
      imageSource.release()
      return pixelMap
    } finally {
      fs.closeSync(file)
    }
  }

  private async savePixelMap(context: common.UIAbilityContext, pixelMap: image.PixelMap, prefix: string): Promise<void> {
    const packer = image.createImagePacker()
    const data: ArrayBuffer = await packer.packing(pixelMap, { format: 'image/png', quality: 95 })
    packer.release()

    const tmpPath = `${context.filesDir}/${prefix}_${Date.now()}.png`
    const outFile = fs.openSync(tmpPath, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY)
    fs.writeSync(outFile.fd, data)
    fs.closeSync(outFile)

    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context)
    const config: photoAccessHelper.PhotoCreationConfig = {
      title: `${prefix}_${Date.now()}`,
      fileNameExtension: 'png',
      photoType: photoAccessHelper.PhotoType.IMAGE
    }
    const destUris: string[] = await phAccessHelper.showAssetsCreationDialog([tmpPath], [config])
    if (destUris.length > 0) {
      FileUtils.copyFile(tmpPath, destUris[0])
    }
    try {
      fs.unlinkSync(tmpPath)
    } catch (_e) {
      // ignore
    }
  }
}
