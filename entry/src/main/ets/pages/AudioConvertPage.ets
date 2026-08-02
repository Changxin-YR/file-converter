/**
 * 音频转换页
 * 常见音频格式转码（辅助能力）,支持码率/采样率预设。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
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
      Scroll() {
        Column({ space: 16 }) {
          this.FileSection()
          this.FormatSection()
          this.ParamSection()
          this.ActionSection()
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .title('音频格式转换')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  FileSection() {
    Column({ space: 8 }) {
      Row() {
        Text('选择音频')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button('选择音频')
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
          Text('🎵')
            .fontSize(40)
          Text('点击上方按钮选择音频文件')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .height(140)
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
        formats: AUDIO_FORMATS,
        selected: this.targetFormat,
        disabled: this.converting,
        selectCallback: (ext: string) => {
          this.targetFormat = ext
        }
      })

      Text('FLAC/WAV/OGG 路径需真机验证编码器,暂不可选')
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
              .backgroundColor(this.bitrateIndex === index ? $r('app.color.primary') : $r('app.color.chip_background'))
              .margin({ top: 6, right: 8 })
              .onClick(() => {
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
          .fontColor($r('app.color.error'))
      }

      if (this.results.length > 0) {
        Text(`转换完成 ${this.results.length} 个文件`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.success'))

        ConvertResultList({ results: this.results })

        Button('保存到指定位置')
          .width('100%')
          .height(40)
          .fontSize(15)
          .type(ButtonType.Normal)
          .onClick(() => this.saveResults())
      }
    }
    .width('100%')
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
