import { router } from '@kit.ArkUI'
import { FunctionTile } from '../components/FunctionTile'
import { PrivacyNoticeSection } from '../components/PrivacyNoticeSection'
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
      .barHeight(72)
      .barBackgroundColor($r('app.color.surface_primary'))
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
      Column({ space: 8 }) {
        Column({ space: 6 }) {
          Text($r('app.string.app_name'))
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text('多种格式 · 快速转换 · 安全可靠')
            .fontSize(15)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Image($r('app.media.ui_hero_home'))
          .accessibilityText('格式转换功能插图')
          .width('100%')
          .height(156)
          .objectFit(ImageFit.Contain)

        Grid() {
          ForEach(this.functionCards, (card: FunctionCard) => {
            GridItem() {
              FunctionTile({
                title: card.title,
                description: card.description,
                asset: card.asset,
                isEnabled: card.enabled,
                onTap: () => this.openFunction(card)
              })
            }
          }, (card: FunctionCard) => card.route)
        }
        .columnsTemplate(this.gridColumns)
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
      }
      .width('100%')
      .constraintSize({ maxWidth: UiConstants.CONTENT_MAX_WIDTH })
      .padding({ left: this.pagePadding, right: this.pagePadding, top: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
  }

  @Builder
  AboutContent() {
    Scroll() {
      Column({ space: 16 }) {
        Image($r('app.media.ui_about_app_icon'))
          .accessibilityText('文件格式盒应用图标')
          .width(128)
          .height(128)
          .objectFit(ImageFit.Contain)
          .margin({ top: 72 })
        Text($r('app.string.app_name'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Text('单机离线，数据不出设备')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.brand_primary'))
        PrivacyNoticeSection()
        Text('版本 1.0.0 · HarmonyOS API 22 · 6.0.2')
          .fontSize(13)
          .fontColor($r('app.color.text_tertiary'))
          .margin({ top: 24 })
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
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.currentTabIndex === index ? $r('app.color.brand_primary') : $r('app.color.text_tertiary'))
      Text(title)
        .fontSize(13)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? $r('app.color.brand_primary') : $r('app.color.text_tertiary'))
      this.TabSelectionLine(index)
    }
    .width('100%')
    .height(72)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  TabSelectionLine(index: number) {
    Row()
      .width(28)
      .height(3)
      .borderRadius(2)
      .backgroundColor($r('app.color.brand_primary'))
      .opacity(this.currentTabIndex === index ? 1 : 0)
  }

  private updateResponsiveLayout(width: number): void {
    if (width >= UiConstants.BREAKPOINT_LARGE) {
      this.gridColumns = '1fr 1fr 1fr 1fr'
      this.pagePadding = UiConstants.PAGE_PADDING_LARGE
      return
    }
    if (width >= UiConstants.BREAKPOINT_MEDIUM) {
      this.gridColumns = '1fr 1fr 1fr'
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
