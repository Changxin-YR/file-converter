/**
 * 音频转换页
 * 常见音频格式转码（辅助能力）,支持码率/采样率预设。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction, router } from '@kit.ArkUI'
import { fileIo as fs } from '@kit.CoreFileKit'
import { FilePickerService } from '../services/FilePickerService'
import { SaveService } from '../services/SaveService'
import { AudioConvertService } from '../services/AudioConvertService'
import { AUDIO_FORMATS } from '../common/FormatTypes'
import { ConvertOptions, ConvertStatus, ConvertType, ConvertTask } from '../common/ConvertTask'
import { AudioPreset, StorageConstants } from '../common/Constants'
import { FileUtils } from '../common/Utils'
import { FormatSelector } from '../components/FormatSelector'
import { ConvertProgressBar } from '../components/ConvertProgressBar'
import { ConvertResultList } from '../components/ConvertResultList'
import { AppPageHeader } from '../components/AppPageHeader'
import { FilePickerPanel } from '../components/FilePickerPanel'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { StatusPanel } from '../components/StatusPanel'
import { UiConstants } from '../common/UiConstants'

@Entry
@Component
struct AudioConvertPage {
  @State selectedFiles: string[] = []
  @State targetFormat: string = 'm4a'
  @State bitrateIndex: number = 1
  @State converting: boolean = false
  @State progress: number = 0
  @State results: string[] = []
  @State statusText: string = ''

  private pickerService?: FilePickerService
  private saveService?: SaveService
  private audioService: AudioConvertService = new AudioConvertService()

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.pickerService = new FilePickerService(context)
    this.saveService = new SaveService(context)
  }

  build() {
    Navigation() {
      Column() {
        AppPageHeader({ title: '音频格式转换', onBack: () => router.back() })
          .padding({ left: 4, right: 16 })
        Scroll() {
          Column({ space: UiConstants.SECTION_GAP }) {
            this.FileSection()
            this.FormatSection()
            this.ParamSection()
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
      title: '选择音频',
      description: '支持 16-bit PCM WAV 转换为 M4A',
      asset: $r('app.media.ui_tool_audio'),
      buttonLabel: '选择音频',
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
        .fontWeight(FontWeight.Medium)

      FormatSelector({
        formats: AUDIO_FORMATS,
        selected: this.targetFormat,
        disabled: this.converting,
        selectCallback: (ext: string) => {
          this.targetFormat = ext
        }
      })

      Text('当前仅支持 16-bit PCM WAV 转为 M4A，其余输出功能正在开发')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ParamSection() {
    Column({ space: 12 }) {
      Column({ space: 8 }) {
        Text('码率')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(AudioPreset.BITRATES, (bitrate: number, index: number) => {
            Text(FileUtils.formatBitrate(bitrate))
              .fontSize(14)
              .fontColor(this.bitrateIndex === index ? Color.White : $r('app.color.text_primary'))
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .borderRadius(18)
              .backgroundColor(this.bitrateIndex === index ? $r('app.color.brand_primary') : $r('app.color.control_selected'))
              .margin({ top: 6, right: 8 })
              .onClick(() => {
                if (this.converting) {
                  return
                }
                this.bitrateIndex = index
              })
          }, (bitrate: number, index: number) => `${bitrate}_${index}`)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('采样率')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Text('跟随源文件')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .borderRadius(18)
          .backgroundColor($r('app.color.chip_background'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
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
        success: this.results.length > 0,
        error: this.statusText.length > 0 && this.results.length === 0,
        loading: false
      })

      if (this.results.length > 0) {
        Text(`转换完成 ${this.results.length} 个文件`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.success'))

        ConvertResultList({ results: this.results })

        PrimaryActionButton({
          label: '保存到指定位置',
          isEnabled: !this.converting,
          loading: false,
          onTap: () => this.saveResults()
        })
      }
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

  private async pickFiles(): Promise<void> {
    if (!this.pickerService) {
      return
    }
    try {
      const uris: string[] = await this.pickerService.pickFiles(StorageConstants.AUDIO_SUFFIXES, 9)
      if (uris.length > 0) {
        this.selectedFiles = uris
        this.results = []
        this.statusText = ''
        this.progress = 0
      }
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `选择音频失败:${err.message}`
    }
  }

  private async startConvert(): Promise<void> {
    if (this.selectedFiles.length === 0) {
      return
    }
    this.converting = true
    this.progress = 0
    this.results = []
    this.statusText = ''

    const context = getContext(this) as common.UIAbilityContext
    const total = this.selectedFiles.length
    const options: ConvertOptions = {
      audioBitrate: AudioPreset.BITRATES[this.bitrateIndex]
    }

    for (let i = 0; i < total; i++) {
      const uri: string = this.selectedFiles[i]
      const srcExt: string = FileUtils.getExtension(uri)
      if (srcExt === this.targetFormat) {
        continue
      }
      const baseName: string = FileUtils.getBaseName(uri)
      const task: ConvertTask = {
        id: FileUtils.genTaskId(),
        type: ConvertType.AUDIO,
        sourcePath: uri,
        sourceFormat: srcExt,
        targetFormat: this.targetFormat,
        targetPath: `${context.filesDir}/${baseName}.${this.targetFormat}`,
        status: ConvertStatus.PENDING,
        progress: 0,
        createTime: Date.now(),
        options: options
      }
      const result = await this.audioService.convertAudio(
        task.sourcePath,
        task.targetPath ?? '',
        task.targetFormat,
        task.options
      )
      if (result.success && result.targetPath) {
        this.results = [...this.results, result.targetPath]
      } else {
        this.statusText = `第 ${i + 1} 个文件失败:${result.errorMsg ?? '未知错误'}`
      }
      this.progress = Math.round((i + 1) / total * 100)
    }

    this.converting = false
    if (this.results.length > 0) {
      promptAction.showToast({ message: `转换完成 ${this.results.length} 个文件` })
    } else {
      this.statusText = this.statusText.length > 0 ? this.statusText : '所选文件无需转换'
    }
  }

  private async saveResults(): Promise<void> {
    if (this.results.length === 0 || !this.saveService) {
      return
    }
    let saved = 0
    for (const result of this.results) {
      const fileName: string = FileUtils.getFileName(result)
      try {
        const targetUri: string = await this.saveService.getSavePath(fileName)
        if (FileUtils.copyFile(result, targetUri)) {
          saved++
        }
      } catch (_e) {
        // 用户取消保存,跳过
      }
    }
    // 清理临时文件
    for (const result of this.results) {
      try { fs.unlinkSync(result) } catch (_e) {}
    }
    if (saved > 0) {
      promptAction.showToast({ message: `已保存 ${saved} 个文件` })
    }
  }
}
