/**
 * 档案&时间转换页
 * 支持 ZIP 压缩/解压 + 时区转换
 * 使用 @kit.BasicServicesKit 的 zlib 模块实现离线压缩。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction, router } from '@kit.ArkUI'
import { zlib } from '@kit.BasicServicesKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { FilePickerService } from '../services/FilePickerService'
import { SaveService } from '../services/SaveService'
import { FileUtils } from '../common/Utils'
import { StorageConstants } from '../common/Constants'
import { AppPageHeader } from '../components/AppPageHeader'
import { FilePickerPanel } from '../components/FilePickerPanel'
import { ChipItem, OptionChipGroup } from '../components/OptionChipGroup'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { SegmentItem, SegmentedControl } from '../components/SegmentedControl'
import { StatusPanel } from '../components/StatusPanel'
import { UiConstants } from '../common/UiConstants'

interface TimezoneInfo {
  key: string
  label: string
  offsetHours: number
}

const TIMEZONES: TimezoneInfo[] = [
  { key: 'utc', label: 'UTC', offsetHours: 0 },
  { key: 'cst', label: 'CST (北京时间)', offsetHours: 8 },
  { key: 'est', label: 'EST (美东)', offsetHours: -5 },
  { key: 'pst', label: 'PST (美西)', offsetHours: -8 },
  { key: 'jst', label: 'JST (日本)', offsetHours: 9 },
  { key: 'gmt', label: 'GMT (格林威治)', offsetHours: 0 },
  { key: 'cet', label: 'CET (中欧)', offsetHours: 1 },
  { key: 'ist', label: 'IST (印度)', offsetHours: 5.5 },
  { key: 'kst', label: 'KST (韩国)', offsetHours: 9 },
  { key: 'aest', label: 'AEST (澳东)', offsetHours: 10 }
]

const PAGE_TABS: SegmentItem[] = [
  { key: 'archive', label: '档案转换', enabled: true },
  { key: 'timezone', label: '时区转换', enabled: true }
]

const ARCHIVE_MODES: SegmentItem[] = [
  { key: 'compress', label: '压缩', enabled: true },
  { key: 'extract', label: '解压', enabled: true }
]

const ARCHIVE_FORMATS: ChipItem[] = [
  { key: 'zip', label: 'ZIP', enabled: true, developing: false },
  { key: '7z', label: '7Z', enabled: false, developing: true },
  { key: 'tar.gz', label: 'TAR.GZ', enabled: false, developing: true },
  { key: 'rar', label: 'RAR', enabled: false, developing: true }
]

@Entry
@Component
struct ArchiveTimePage {
  @State currentTab: number = 0
  @State fromTzIndex: number = 1
  @State toTzIndex: number = 2
  @State inputHour: string = ''
  @State inputMinute: string = ''
  @State timeResult: string = ''
  @State archiveMode: number = 0
  @State selectedFiles: string[] = []
  @State processing: boolean = false
  @State archiveStatus: string = ''

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
        AppPageHeader({ title: '档案与时间', onBack: () => router.back() })
          .padding({ left: 4, right: 16 })
        Scroll() {
          Column({ space: UiConstants.SECTION_GAP }) {
            this.TabSelector()
            if (this.currentTab === 0) {
              this.ArchiveSection()
            } else {
              this.TimezoneSection()
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
  TabSelector() {
    SegmentedControl({
      items: PAGE_TABS,
      selectedKey: this.currentTab === 0 ? 'archive' : 'timezone',
      onSelect: (key: string) => {
        this.currentTab = key === 'archive' ? 0 : 1
      }
    })
  }

  @Builder
  ArchiveSection() {
    Column({ space: 16 }) {
      SegmentedControl({
        items: ARCHIVE_MODES,
        selectedKey: this.archiveMode === 0 ? 'compress' : 'extract',
        onSelect: (key: string) => {
          this.archiveMode = key === 'compress' ? 0 : 1
          this.selectedFiles = []
          this.archiveStatus = ''
        }
      })

      FilePickerPanel({
        title: this.archiveMode === 0 ? '选择待压缩文件' : '选择 ZIP 文件',
        description: this.archiveMode === 0 ? '最多选择 20 个文件' : '选择一个 ZIP 档案进行解压',
        asset: $r('app.media.ui_tool_archive'),
        buttonLabel: '选择文件',
        selectedName: this.selectedArchiveSummary(),
        isEnabled: !this.processing,
        onPick: () => this.pickArchiveFiles()
      })

      Text('档案格式')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      OptionChipGroup({
        items: ARCHIVE_FORMATS,
        selectedKey: 'zip',
        disabled: this.processing,
        onSelect: (_key: string) => {}
      })

      PrimaryActionButton({
        label: this.archiveMode === 0 ? '压缩为 ZIP 并保存' : '解压到指定位置',
        isEnabled: !this.processing && this.selectedFiles.length > 0,
        loading: this.processing,
        onTap: () => {
          if (this.archiveMode === 0) {
            this.compressToZip()
          } else {
            this.decompressZip()
          }
        }
      })
      StatusPanel({
        message: this.archiveStatus,
        success: this.archiveStatus.startsWith('已'),
        error: this.archiveStatus.length > 0 && !this.archiveStatus.startsWith('已'),
        loading: false
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  TimezoneSection() {
    Column({ space: 16 }) {
      Image($r('app.media.ui_globe'))
        .width('100%')
        .height(132)
        .objectFit(ImageFit.Contain)
      Text('输入时间')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Row({ space: 12 }) {
        TextInput({ placeholder: '时', text: this.inputHour })
          .type(InputType.Number)
          .layoutWeight(1)
          .height(UiConstants.TOUCH_MIN_HEIGHT)
          .backgroundColor($r('app.color.surface_primary'))
          .borderRadius(UiConstants.CONTROL_RADIUS)
          .onChange((value: string) => {
            this.inputHour = value
            this.convertTime()
          })
        Text(':')
          .fontSize(20)
        TextInput({ placeholder: '分', text: this.inputMinute })
          .type(InputType.Number)
          .layoutWeight(1)
          .height(UiConstants.TOUCH_MIN_HEIGHT)
          .backgroundColor($r('app.color.surface_primary'))
          .borderRadius(UiConstants.CONTROL_RADIUS)
          .onChange((value: string) => {
            this.inputMinute = value
            this.convertTime()
          })
      }
      .width('100%')

      Column({ space: 6 }) {
        Text('从时区')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(TIMEZONES, (tz: TimezoneInfo, index: number) => {
            Text(tz.label)
              .fontSize(12)
              .fontColor(this.fromTzIndex === index ? Color.White : $r('app.color.text_primary'))
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(14)
              .backgroundColor(this.fromTzIndex === index ? $r('app.color.brand_primary') : $r('app.color.control_selected'))
              .margin({ top: 6, right: 6 })
              .onClick(() => {
                this.fromTzIndex = index
                this.convertTime()
              })
          }, (tz: TimezoneInfo, index: number) => `from_${tz.key}_${index}`)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 6 }) {
        Text('转为时区')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(TIMEZONES, (tz: TimezoneInfo, index: number) => {
            Text(tz.label)
              .fontSize(12)
              .fontColor(this.toTzIndex === index ? Color.White : $r('app.color.text_primary'))
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(14)
              .backgroundColor(this.toTzIndex === index ? $r('app.color.brand_primary') : $r('app.color.control_selected'))
              .margin({ top: 6, right: 6 })
              .onClick(() => {
                this.toTzIndex = index
                this.convertTime()
              })
          }, (tz: TimezoneInfo, index: number) => `to_${tz.key}_${index}`)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.timeResult.length > 0) {
        Row() {
          Text(this.timeResult)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.timeResult.startsWith('分钟') ? $r('app.color.error') : $r('app.color.brand_primary'))
        }
        .width('100%')
        .padding(16)
        .borderRadius(UiConstants.CARD_RADIUS)
        .backgroundColor($r('app.color.surface_primary'))
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private selectedArchiveSummary(): string {
    if (this.selectedFiles.length === 0) {
      return ''
    }
    if (this.selectedFiles.length === 1) {
      return FileUtils.getFileName(this.selectedFiles[0])
    }
    return `${FileUtils.getFileName(this.selectedFiles[0])} 等 ${this.selectedFiles.length} 个文件`
  }

  private async pickArchiveFiles(): Promise<void> {
    if (!this.pickerService) {
      return
    }
    try {
      const suffixes: string[] = this.archiveMode === 1 ? ['.zip'] : StorageConstants.ARCHIVE_SOURCE_SUFFIXES
      const maxCount = this.archiveMode === 1 ? 1 : 20
      const uris: string[] = await this.pickerService.pickFiles(suffixes, maxCount)
      if (uris.length > 0) {
        this.selectedFiles = uris
        this.archiveStatus = ''
      }
    } catch (e) {
      const err = e as BusinessError
      this.archiveStatus = `选择文件失败:${err.message}`
    }
  }

  private async compressToZip(): Promise<void> {
    if (this.selectedFiles.length === 0 || !this.saveService) {
      return
    }
    this.processing = true
    this.archiveStatus = ''

    try {
      const context = getContext(this) as common.UIAbilityContext
      const tempDir = `${context.tempDir}/zip_src_${Date.now()}`
      fs.mkdirSync(tempDir)

      for (const uri of this.selectedFiles) {
        const fileName = FileUtils.getFileName(uri)
        const destPath = `${tempDir}/${fileName}`
        FileUtils.copyFile(uri, destPath)
      }

      const zipPath = `${context.tempDir}/output_${Date.now()}.zip`
      const options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION
      }
      await zlib.compressFile(tempDir, zipPath, options)

      const targetUri = await this.saveService.getSavePath('archive.zip')
      FileUtils.copyFile(zipPath, targetUri)

      // 清理临时文件
      this.removeDirRecursive(tempDir)
      try { fs.unlinkSync(zipPath) } catch (_e) {}

      this.archiveStatus = `已将 ${this.selectedFiles.length} 个文件压缩为 ZIP 并保存`
      promptAction.showToast({ message: 'ZIP 压缩完成' })
    } catch (e) {
      const err = e as BusinessError
      this.archiveStatus = `压缩失败:${err.message}`
    }

    this.processing = false
  }

  private async decompressZip(): Promise<void> {
    if (this.selectedFiles.length === 0 || !this.saveService) {
      return
    }
    this.processing = true
    this.archiveStatus = ''

    try {
      const context = getContext(this) as common.UIAbilityContext
      const zipUri = this.selectedFiles[0]

      // picker URI 需要先复制到沙箱才能用于 zlib
      const tempZip = `${context.tempDir}/src_${Date.now()}.zip`
      FileUtils.copyFile(zipUri, tempZip)

      const outDir = `${context.tempDir}/unzip_${Date.now()}`
      fs.mkdirSync(outDir)

      await zlib.decompressFile(tempZip, outDir)

      // 递归保存解压出的所有文件(包括子目录)
      let savedCount = 0
      savedCount = await this.saveExtractedFiles(outDir, '')

      // 清理临时文件
      this.removeDirRecursive(outDir)
      try { fs.unlinkSync(tempZip) } catch (_e) {}

      this.archiveStatus = `已解压并保存 ${savedCount} 个文件`
      promptAction.showToast({ message: '解压完成' })
    } catch (e) {
      const err = e as BusinessError
      this.archiveStatus = `解压失败:${err.message}`
    }

    this.processing = false
  }

  private removeDirRecursive(dirPath: string): void {
    try {
      const entries = fs.listFileSync(dirPath)
      for (const entry of entries) {
        const fullPath = `${dirPath}/${entry}`
        const stat = fs.statSync(fullPath)
        if (stat.isDirectory()) {
          this.removeDirRecursive(fullPath)
        } else {
          fs.unlinkSync(fullPath)
        }
      }
      fs.rmdirSync(dirPath)
    } catch (_e) {
      // 清理失败不影响主流程
    }
  }

  private async saveExtractedFiles(baseDir: string, relativePath: string): Promise<number> {
    let count = 0
    const currentDir = relativePath.length > 0 ? `${baseDir}/${relativePath}` : baseDir
    const entries = fs.listFileSync(currentDir)
    for (const entry of entries) {
      const fullPath = `${currentDir}/${entry}`
      const stat = fs.statSync(fullPath)
      if (stat.isDirectory()) {
        const subPath = relativePath.length > 0 ? `${relativePath}/${entry}` : entry
        count += await this.saveExtractedFiles(baseDir, subPath)
      } else if (stat.isFile()) {
        const displayName = relativePath.length > 0 ? `${relativePath}_${entry}` : entry
        const targetUri = await this.saveService!.getSavePath(displayName)
        FileUtils.copyFile(fullPath, targetUri)
        count++
      }
    }
    return count
  }

  private convertTime(): void {
    const hour = parseInt(this.inputHour, 10)
    const minute = parseInt(this.inputMinute, 10) || 0
    if (isNaN(hour) || hour < 0 || hour > 23) {
      this.timeResult = ''
      return
    }
    if (minute < 0 || minute > 59) {
      this.timeResult = '分钟需在 0-59 之间'
      return
    }
    const fromTz = TIMEZONES[this.fromTzIndex]
    const toTz = TIMEZONES[this.toTzIndex]
    const diff = toTz.offsetHours - fromTz.offsetHours
    const totalMinutes = hour * 60 + minute + Math.round(diff * 60)
    let finalMin = ((totalMinutes % 1440) + 1440) % 1440
    let dayShift = ''
    if (totalMinutes >= 1440) {
      dayShift = ' (+1天)'
    } else if (totalMinutes < 0) {
      dayShift = ' (-1天)'
    }
    const finalHour = Math.floor(finalMin / 60)
    finalMin = finalMin % 60
    const fh = finalHour.toString().padStart(2, '0')
    const fm = finalMin.toString().padStart(2, '0')
    this.timeResult = `${fromTz.label} ${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')} = ${toTz.label} ${fh}:${fm}${dayShift}`
  }
}
