/**
 * 视频转换页
 * 支持视频格式转换:MP4转换器、Video到GIF、MOV到MP4等
 * 基于 AVTranscoder 离线完成。API 22 仅可靠支持 MP4 容器输出。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction, router } from '@kit.ArkUI'
import { media } from '@kit.MediaKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { FilePickerService } from '../services/FilePickerService'
import { SaveService } from '../services/SaveService'
import { VideoAudioExtractService } from '../services/VideoAudioExtractService'
import { VideoRemuxService } from '../services/VideoRemuxService'
import { ConvertResult } from '../common/ConvertTask'
import { ConvertType } from '../common/ConvertTask'
import { FormatInfo } from '../common/FormatTypes'
import { FileUtils } from '../common/Utils'
import { FormatSelector } from '../components/FormatSelector'
import { ConvertProgressBar } from '../components/ConvertProgressBar'
import { AppPageHeader } from '../components/AppPageHeader'
import { FilePickerPanel } from '../components/FilePickerPanel'
import { PrimaryActionButton } from '../components/PrimaryActionButton'
import { StatusPanel } from '../components/StatusPanel'
import { UiConstants } from '../common/UiConstants'

const VIDEO_SOURCE_SUFFIXES: string[] = ['.mp4', '.mov', '.avi', '.mkv', '.flv', '.wmv', '.3gp']

const VIDEO_TARGET_FORMATS: FormatInfo[] = [
  { extension: 'mp4', mimeType: 'video/mp4', displayName: 'MP4', category: ConvertType.VIDEO, nativeSupported: true },
  { extension: 'm4a', mimeType: 'audio/mp4', displayName: 'M4A(提取音频)', category: ConvertType.AUDIO, nativeSupported: true }
]

@Entry
@Component
struct VideoConvertPage {
  @State selectedFiles: string[] = []
  @State targetFormat: string = 'mp4'
  @State converting: boolean = false
  @State progress: number = 0
  @State statusText: string = ''
  @State successCount: number = 0

  private pickerService?: FilePickerService
  private saveService?: SaveService
  private audioExtractService: VideoAudioExtractService = new VideoAudioExtractService()
  private videoRemuxService: VideoRemuxService = new VideoRemuxService()

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    this.pickerService = new FilePickerService(context)
    this.saveService = new SaveService(context)
  }

  build() {
    Navigation() {
      Column() {
        AppPageHeader({ title: '视频格式转换', onBack: () => router.back() })
          .padding({ left: 4, right: 16 })
        Scroll() {
          Column({ space: UiConstants.SECTION_GAP }) {
            this.FileSection()
            this.FormatSection()
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
      title: '选择视频',
      description: '支持 MOV 转 MP4、MP4 提取 M4A',
      asset: $r('app.media.ui_tool_video'),
      buttonLabel: '选择视频',
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
        formats: VIDEO_TARGET_FORMATS,
        selected: this.targetFormat,
        disabled: this.converting,
        selectCallback: (ext: string) => {
          this.targetFormat = ext
          this.updateM4aInputStatus()
        }
      })

      Text('支持视频转 MP4；含 AAC 音轨的 MP4 可无损提取为 M4A')
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
        isEnabled: !this.converting && this.selectedFiles.length > 0 && this.supportsSelectedM4aInput(),
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

  private async pickFiles(): Promise<void> {
    if (!this.pickerService) {
      return
    }
    try {
      const uris: string[] = await this.pickerService.pickFiles(VIDEO_SOURCE_SUFFIXES, 5)
      if (uris.length > 0) {
        this.selectedFiles = uris
        this.progress = 0
        this.successCount = 0
        this.updateM4aInputStatus()
      }
    } catch (e) {
      const err = e as BusinessError
      this.statusText = `选择视频失败:${err.message}`
    }
  }

  private async startConvert(): Promise<void> {
    if (this.selectedFiles.length === 0 || !this.saveService) {
      return
    }
    const SUPPORTED: string[] = ['mp4', 'm4a']
    if (!SUPPORTED.includes(this.targetFormat)) {
      this.statusText = `${this.targetFormat.toUpperCase()} 格式暂不支持离线转换`
      return
    }
    if (!this.supportsSelectedM4aInput()) {
      this.statusText = 'M4A 提取仅支持 MP4 输入，请重新选择 MP4 文件'
      return
    }
    this.converting = true
    this.progress = 0
    this.statusText = ''
    this.successCount = 0

    const context = getContext(this) as common.UIAbilityContext
    const total = this.selectedFiles.length

    for (let i = 0; i < total; i++) {
      const uri: string = this.selectedFiles[i]
      const baseName: string = FileUtils.getBaseName(uri)
      const srcExt: string = FileUtils.getExtension(uri)

      if (srcExt === this.targetFormat) {
        this.progress = Math.round((i + 1) / total * 100)
        continue
      }

      const targetPath = `${context.filesDir}/${baseName}.${this.targetFormat}`
      try {
        if (this.targetFormat === 'm4a') {
          const result: ConvertResult = await this.audioExtractService.extract(uri, targetPath)
          if (!result.success) {
            throw new Error(result.errorMsg ?? 'M4A 音轨提取失败')
          }
        } else if (srcExt === 'mov') {
          const result: ConvertResult = await this.videoRemuxService.remux(uri, targetPath)
          if (!result.success) {
            throw new Error(result.errorMsg ?? 'MOV 无损重封装失败')
          }
        } else {
          await this.transcodeVideo(uri, targetPath)
        }
        const fileName = `${baseName}.${this.targetFormat}`
        const saveUri: string = await this.saveService.getSavePath(fileName)
        if (!FileUtils.copyFile(targetPath, saveUri)) {
          throw new Error('保存视频文件失败')
        }
        this.successCount++
        this.progress = Math.round((i + 1) / total * 100)
      } catch (e) {
        const err = e as BusinessError
        this.statusText = `第 ${i + 1} 个文件失败:${err.message}`
      } finally {
        try { fs.unlinkSync(targetPath) } catch (_e) {}
      }
    }

    this.converting = false
    if (this.successCount > 0) {
      this.statusText = `已成功转换并保存 ${this.successCount} 个文件`
      promptAction.showToast({ message: `已保存 ${this.successCount} 个文件` })
    } else if (this.statusText.length === 0) {
      this.statusText = '所选视频无需转换'
    }
  }

  private async transcodeVideo(sourceUri: string, targetPath: string): Promise<void> {
    const sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY)
    const srcStat = fs.statSync(sourceFile.fd)
    const outFile = fs.openSync(targetPath, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.READ_WRITE)
    let transcoder: media.AVTranscoder | null = null

    try {
      const activeTranscoder: media.AVTranscoder = await media.createAVTranscoder()
      transcoder = activeTranscoder
      activeTranscoder.fdSrc = { fd: sourceFile.fd, offset: 0, length: srcStat.size }
      activeTranscoder.fdDst = outFile.fd

      const config: media.AVTranscoderConfig = {
        audioBitrate: 128000,
        audioCodec: media.CodecMimeType.AUDIO_AAC,
        fileFormat: media.ContainerFormatType.CFT_MPEG_4
      }

      if (this.targetFormat === 'mp4') {
        config.videoBitrate = 2000000
        config.videoCodec = media.CodecMimeType.VIDEO_AVC
      }

      // Register listeners before prepare/start so fast conversions cannot
      // finish before the promise is observing the terminal event.
      const conversionFinished: Promise<void> = new Promise<void>((resolve: () => void, reject: (err: Error) => void) => {
        const onComplete = (): void => {
          activeTranscoder.off('error')
          resolve()
        }
        const onError = (err: BusinessError): void => {
          activeTranscoder.off('complete')
          reject(new Error(err.message))
        }
        activeTranscoder.on('complete', onComplete)
        activeTranscoder.on('error', onError)
      })
      await activeTranscoder.prepare(config)
      await activeTranscoder.start()
      await conversionFinished
    } catch (e) {
      const err = e as BusinessError
      throw new Error(`视频格式或当前设备的 MP4 编码器不支持:${err.message}`)
    } finally {
      if (transcoder) {
        try { await transcoder.release() } catch (_e) {}
      }
      fs.closeSync(sourceFile)
      fs.closeSync(outFile)
    }
  }

  private supportsSelectedM4aInput(): boolean {
    if (this.targetFormat !== 'm4a') {
      return true
    }
    for (const uri of this.selectedFiles) {
      if (FileUtils.getExtension(uri) !== 'mp4') {
        return false
      }
    }
    return true
  }

  private updateM4aInputStatus(): void {
    const unsupportedMessage = 'M4A 提取仅支持 MP4 输入，请重新选择 MP4 文件'
    if (!this.supportsSelectedM4aInput()) {
      this.statusText = unsupportedMessage
      return
    }
    if (this.statusText === unsupportedMessage) {
      this.statusText = ''
    }
  }
}
