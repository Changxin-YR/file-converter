/**
 * 档案&时间转换页
 * 支持 ZIP 压缩/解压 + 时区转换
 * 使用 @kit.BasicServicesKit 的 zlib 模块实现离线压缩。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import { zlib } from '@kit.BasicServicesKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { FilePickerService } from '../services/FilePickerService'
import { SaveService } from '../services/SaveService'
import { FileUtils } from '../common/Utils'
import { StorageConstants } from '../common/Constants'

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
      Scroll() {
        Column({ space: 16 }) {
          this.TabSelector()
          if (this.currentTab === 0) {
            this.ArchiveSection()
          } else {
            this.TimezoneSection()
          }
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .title('档案 & 时间')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  TabSelector() {
    Row({ space: 0 }) {
      Text('档案转换')
        .fontSize(15)
        .fontWeight(this.currentTab === 0 ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTab === 0 ? Color.White : $r('app.color.text_primary'))
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .backgroundColor(this.currentTab === 0 ? $r('app.color.primary') : $r('app.color.chip_background'))
        .borderRadius({ topLeft: 20, bottomLeft: 20 })
        .onClick(() => { this.currentTab = 0 })
      Text('时区转换')
        .fontSize(15)
        .fontWeight(this.currentTab === 1 ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTab === 1 ? Color.White : $r('app.color.text_primary'))
        .padding({ left: 20, right: 20, top: 10, bottom: 10 })
        .backgroundColor(this.currentTab === 1 ? $r('app.color.primary') : $r('app.color.chip_background'))
        .borderRadius({ topRight: 20, bottomRight: 20 })
        .onClick(() => { this.currentTab = 1 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ArchiveSection() {
    Column({ space: 16 }) {
      Row({ space: 0 }) {
        Text('压缩')
          .fontSize(14)
          .fontColor(this.archiveMode === 0 ? Color.White : $r('app.color.text_primary'))
          .padding({ left: 16, right: 16, top: 7, bottom: 7 })
          .backgroundColor(this.archiveMode === 0 ? $r('app.color.primary') : $r('app.color.chip_background'))
          .borderRadius({ topLeft: 16, bottomLeft: 16 })
          .onClick(() => {
            this.archiveMode = 0
            this.selectedFiles = []
            this.archiveStatus = ''
          })
        Text('解压')
          .fontSize(14)
          .fontColor(this.archiveMode === 1 ? Color.White : $r('app.color.text_primary'))
          .padding({ left: 16, right: 16, top: 7, bottom: 7 })
          .backgroundColor(this.archiveMode === 1 ? $r('app.color.primary') : $r('app.color.chip_background'))
          .borderRadius({ topRight: 16, bottomRight: 16 })
          .onClick(() => {
            this.archiveMode = 1
            this.selectedFiles = []
            this.archiveStatus = ''
          })
      }

      Row() {
        Text(this.archiveMode === 0 ? '选择要压缩的文件' : '选择ZIP文件')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button('选择文件')
          .height(34)
          .fontSize(13)
          .enabled(!this.processing)
          .onClick(() => this.pickArchiveFiles())
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
          Text(this.archiveMode === 0 ? '选择要压缩的文件' : '选择要解压的ZIP文件')
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

      Button(this.processing ? '处理中...' : (this.archiveMode === 0 ? '压缩为 ZIP 并保存' : '解压到指定位置'))
        .width('100%')
        .height(44)
        .fontSize(16)
        .enabled(!this.processing && this.selectedFiles.length > 0)
        .onClick(() => {
          if (this.archiveMode === 0) {
            this.compressToZip()
          } else {
            this.decompressZip()
          }
        })

      if (this.archiveStatus.length > 0) {
        Text(this.archiveStatus)
          .fontSize(13)
          .fontColor($r('app.color.success'))
      }

      Column({ space: 8 }) {
        Text('支持的格式')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        this.ArchiveRow('ZIP', '压缩', true)
        this.ArchiveRow('解压 ZIP', '解压到指定位置', true)
        this.ArchiveRow('7Z', '压缩/解压', false)
        this.ArchiveRow('TAR.GZ', '压缩/解压', false)
        this.ArchiveRow('RAR', '仅解压', false)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ArchiveRow(format: string, desc: string, supported: boolean) {
    Row() {
      Text(format)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      Text(desc)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(supported ? '可用' : '开发中')
        .fontSize(12)
        .fontColor(supported ? $r('app.color.success') : $r('app.color.text_tertiary'))
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .borderRadius(8)
    .backgroundColor($r('app.color.card_background'))
  }

  @Builder
  TimezoneSection() {
    Column({ space: 16 }) {
      Text('时区转换')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)

      Row({ space: 12 }) {
        TextInput({ placeholder: '时', text: this.inputHour })
          .type(InputType.Number)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.inputHour = value
            this.convertTime()
          })
        Text(':')
          .fontSize(20)
        TextInput({ placeholder: '分', text: this.inputMinute })
          .type(InputType.Number)
          .layoutWeight(1)
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
              .backgroundColor(this.fromTzIndex === index ? $r('app.color.primary') : $r('app.color.chip_background'))
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
              .backgroundColor(this.toTzIndex === index ? $r('app.color.primary') : $r('app.color.chip_background'))
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
            .fontColor($r('app.color.primary'))
        }
        .width('100%')
        .padding(16)
        .borderRadius(12)
        .backgroundColor($r('app.color.card_background'))
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
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
