import { router } from '@kit.ArkUI'
import { FunctionTile } from '../components/FunctionTile'
import { UiConstants } from '../common/UiConstants'

interface FunctionCard {
  title: string
  description: string
  route: string
  asset: Resource
  enabled: boolean
}

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0
  @State gridColumns: string = '1fr 1fr'
  @State pagePadding: number = UiConstants.PAGE_PADDING_PHONE

  private functionCards: FunctionCard[] = [
    {
      title: '图片转换', description: 'PNG/JPG/WEBP/BMP 格式互转', route: 'pages/ImageConvertPage',
      asset: $r('app.media.ui_tool_image'), enabled: true
    },
    {
      title: '文档转换', description: 'TXT/CSV/JSON/XML/HTML/MD', route: 'pages/DocumentConvertPage',
      asset: $r('app.media.ui_tool_document'), enabled: true
    },
    {
      title: '视频转换', description: 'MOV 转 MP4 / 提取 M4A', route: 'pages/VideoConvertPage',
      asset: $r('app.media.ui_tool_video'), enabled: true
    },
    {
      title: '音频转换', description: 'PCM WAV 转 M4A', route: 'pages/AudioConvertPage',
      asset: $r('app.media.ui_tool_audio'), enabled: true
    },
    {
      title: '图片工具', description: '调整尺寸/裁剪/颜色提取', route: 'pages/ImageToolsPage',
      asset: $r('app.media.ui_tool_image_edit'), enabled: true
    },
    {
      title: '档案 & 时间', description: 'ZIP 压缩解压/时区转换', route: 'pages/ArchiveTimePage',
      asset: $r('app.media.ui_tool_archive'), enabled: true
    },
    {
      title: '单位换算器', description: '重量/长度/温度/面积/体积', route: 'pages/UnitConverterPage',
      asset: $r('app.media.ui_tool_unit'), enabled: true
    },
    {
      title: 'PDF 工具箱', description: '图片转 PDF / 文本PDF导出', route: 'pages/PdfToolsPage',
      asset: $r('app.media.ui_tool_pdf'), enabled: true
    }
  ]

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentTabIndex }) {
        TabContent() {
          this.HomeContent()
        }
        .tabBar(this.TabBarBuilder($r('app.string.tab_home'), '⌂', 0))

        TabContent() {
          this.AboutContent()
        }
        .tabBar(this.TabBarBuilder($r('app.string.tab_about'), 'i', 1))
      }
      .barHeight(56)
      .onChange((index: number) => {
        this.currentTabIndex = index
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.updateResponsiveLayout(Number(newValue.width))
    })
  }

  @Builder
  HomeContent() {
    Scroll() {
      Column({ space: 14 }) {
        Column({ space: 4 }) {
          Text($r('app.string.app_name'))
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text('多种格式 · 快速转换 · 安全可靠')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Image($r('app.media.ui_hero_home'))
          .width('100%')
          .height(154)
          .objectFit(ImageFit.Contain)

        Grid() {
          ForEach(this.functionCards, (card: FunctionCard) => {
            GridItem() {
              FunctionTile({
                title: card.title,
                description: card.description,
                asset: card.asset,
                isEnabled: card.enabled,
                developing: !card.enabled,
                onTap: () => this.openFunction(card)
              })
            }
          }, (card: FunctionCard) => card.route)
        }
        .columnsTemplate(this.gridColumns)
        .columnsGap(10)
        .rowsGap(10)
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxWidth: UiConstants.CONTENT_MAX_WIDTH })
      .padding({ left: this.pagePadding, right: this.pagePadding, top: 18, bottom: 18 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
  }

  @Builder
  AboutContent() {
    Scroll() {
      Column({ space: 14 }) {
        Image($r('app.media.app_icon'))
          .width(104)
          .height(104)
          .objectFit(ImageFit.Contain)
          .margin({ top: 48 })
        Text($r('app.string.app_name'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('单机离线，数据不出设备')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.brand_primary'))
        Column({ space: 10 }) {
          Text('文件只在设备本地处理')
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
          Text('不联网、无后端、不上传')
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
          Text('不收集、不存储用户文件')
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
          Text('仅在使用时访问所选文件')
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .padding(18)
        .backgroundColor($r('app.color.surface_primary'))
        .borderRadius(UiConstants.CARD_RADIUS)
        Text('版本 1.0.0 · HarmonyOS API 22 · 6.0.2')
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 8 })
      }
      .width('100%')
      .constraintSize({ maxWidth: UiConstants.CONTENT_MAX_WIDTH })
      .padding({ left: this.pagePadding, right: this.pagePadding, bottom: 24 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
  }

  @Builder
  TabBarBuilder(title: Resource, icon: string, index: number) {
    Column({ space: 1 }) {
      Text(icon)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTabIndex === index ? $r('app.color.brand_primary') : $r('app.color.text_tertiary'))
      Text(title)
        .fontSize(11)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? $r('app.color.brand_primary') : $r('app.color.text_tertiary'))
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
  }

  private updateResponsiveLayout(width: number): void {
    if (width >= UiConstants.BREAKPOINT_LARGE) {
      this.gridColumns = '1fr 1fr 1fr 1fr'
      this.pagePadding = UiConstants.PAGE_PADDING_LARGE
      return
    }
    this.gridColumns = '1fr 1fr'
    this.pagePadding = UiConstants.PAGE_PADDING_PHONE
  }

  private openFunction(card: FunctionCard): void {
    if (!card.enabled) {
      return
    }
    router.pushUrl({ url: card.route })
  }
}
