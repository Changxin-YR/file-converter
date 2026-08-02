/**
 * 视频转换页
 * 支持视频格式转换:MP4转换器、Video到GIF、MOV到MP4等
 * 基于 AVTranscoder 离线完成。API 22 仅可靠支持 MP4 容器输出。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
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

const VIDEO_SOURCE_SUFFIXES: string[] = ['.mp4', '.mov', '.avi', '.mkv', '.flv', '.wmv', '.3gp']

const VIDEO_TARGET_FORMATS: FormatInfo[] = [
  { extension: 'mp4', mimeType: 'video/mp4', displayName: 'MP4', category: ConvertType.VIDEO, nativeSupported: true },
  { extension: 'm4a', mimeType: 'audio/mp4', displayName: 'M4A(提取音频)', category: ConvertType.AUDIO, nativeSupported: true },
  { extension: 'mp3', mimeType: 'audio/mpeg', displayName: 'MP3(提取音频)', category: ConvertType.AUDIO, nativeSupported: false }
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
      Scroll() {
        Column({ space: 16 }) {
          this.FileSection()
          this.FormatSection()
          this.ActionSection()
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .title('视频格式转换')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  FileSection() {
    Column({ space: 8 }) {
      Row() {
        Text('选择视频')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button('选择视频')
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
          Text('支持 MP4/MOV/AVI/MKV/FLV/WMV/3GP')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .height(120)
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
        formats: VIDEO_TARGET_FORMATS,
        selected: this.targetFormat,
        disabled: this.converting,
        selectCallback: (ext: string) => {
          this.targetFormat = ext
        }
      })

      Text('支持视频转 MP4；含 AAC 音轨的 MP4 可无损提取为 M4A，MP3 暂不支持')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
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
          .fontColor(this.successCount > 0 ? $r('app.color.success') : $r('app.color.error'))
      }
    }
    .width('100%')
  }

  private async pickFiles(): Promise<void> {
    if (!this.pickerService) {
      return
    }
    try {
      const uris: string[] = await this.pickerService.pickFiles(VIDEO_SOURCE_SUFFIXES, 5)
      if (uris.length > 0) {
        this.selectedFiles = uris
        this.statusText = ''
        this.progress = 0
        this.successCount = 0
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

      try {
        const targetPath = `${context.filesDir}/${baseName}.${this.targetFormat}`
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
        FileUtils.copyFile(targetPath, saveUri)
        // 清理临时文件
        try { fs.unlinkSync(targetPath) } catch (_e) {}
        this.successCount++
        this.progress = Math.round((i + 1) / total * 100)
      } catch (e) {
        const err = e as BusinessError
        this.statusText = `第 ${i + 1} 个文件失败:${err.message}`
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
    const srcStat = fs.statSync(sourceUri)
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

      await activeTranscoder.prepare(config)
      await activeTranscoder.start()

      // 等待转码完成
      await new Promise<void>((resolve: () => void, reject: (err: Error) => void) => {
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
}
