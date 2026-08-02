/**
 * 首页
 * Tab 导航:首页（功能卡片）+ 关于（隐私声明）。
 */
import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'

interface FunctionCard {
  title: string
  iconText: string
  description: string
  route: string
  comingSoon: boolean
}

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0

  private functionCards: FunctionCard[] = [
    {
      title: '图片转换',
      iconText: '🖼',
      description: 'PNG/JPG/WEBP/BMP 格式互转',
      route: 'pages/ImageConvertPage',
      comingSoon: false
    },
    {
      title: '文档转换',
      iconText: '📄',
      description: 'TXT/CSV/JSON/XML/HTML/MD 互转,可导出PDF',
      route: 'pages/DocumentConvertPage',
      comingSoon: false
    },
    {
      title: '视频转换',
      iconText: '🎬',
      description: '视频转 MP4 / 提取 M4A',
      route: 'pages/VideoConvertPage',
      comingSoon: false
    },
    {
      title: '音频转换',
      iconText: '🎵',
      description: 'M4A 音频转码',
      route: 'pages/AudioConvertPage',
      comingSoon: false
    },
    {
      title: '图片工具',
      iconText: '✂️',
      description: '调整尺寸/裁剪/颜色选择器',
      route: 'pages/ImageToolsPage',
      comingSoon: false
    },
    {
      title: '档案 & 时间',
      iconText: '📦',
      description: 'ZIP 压缩解压/时区转换',
      route: 'pages/ArchiveTimePage',
      comingSoon: false
    },
    {
      title: '单位换算器',
      iconText: '⚖️',
      description: '重量/长度/温度/面积/体积',
      route: 'pages/UnitConverterPage',
      comingSoon: false
    },
    {
      title: 'PDF 工具箱',
      iconText: '📑',
      description: 'JPG/文本/HTML 转 PDF，文本PDF导出',
      route: 'pages/PdfToolsPage',
      comingSoon: false
    }
  ]

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentTabIndex }) {
        TabContent() {
          this.HomeContent()
        }
        .tabBar(this.TabBarBuilder($r('app.string.tab_home'), 0))

        TabContent() {
          this.AboutContent()
        }
        .tabBar(this.TabBarBuilder($r('app.string.tab_about'), 1))
      }
      .barHeight(56)
      .onChange((index: number) => {
        this.currentTabIndex = index
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  HomeContent() {
    Column() {
      Text($r('app.string.app_name'))
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24, bottom: 4 })

      Text('单机离线 · 格式转换 & 实用工具')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 20 })

      Grid() {
        ForEach(this.functionCards, (card: FunctionCard) => {
          GridItem() {
            this.FunctionCardBuilder(card)
          }
        }, (card: FunctionCard) => card.title)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .padding({ left: 16, right: 16 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  AboutContent() {
    Column({ space: 12 }) {
      Text('🔒')
        .fontSize(52)
        .margin({ top: 72 })

      Text('单机离线,数据不出设备')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      Text('本应用不联网、无后端,所有格式转换均在设备本地完成。\n不上传、不收集、不存储您的任何文件。')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .lineHeight(22)
        .padding({ left: 32, right: 32 })

      Text('版本 1.0.0 · HarmonyOS API 22')
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  FunctionCardBuilder(card: FunctionCard) {
    Column() {
      Text(card.iconText)
        .fontSize(32)
        .margin({ bottom: 6 })

      Text(card.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)

      Text(card.description)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ top: 4 })
        .maxLines(2)

      if (card.comingSoon) {
        Text('即将支持')
          .fontSize(11)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(10)
          .backgroundColor($r('app.color.text_tertiary'))
          .margin({ top: 6 })
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(14)
    .backgroundColor($r('app.color.card_background'))
    .borderWidth(card.comingSoon ? 1 : 0)
    .borderColor($r('app.color.border'))
    .opacity(card.comingSoon ? 0.72 : 1)
    .onClick(() => {
      if (card.comingSoon) {
        promptAction.showToast({ message: '该功能即将支持' })
        return
      }
      router.pushUrl({ url: card.route })
    })
  }

  @Builder
  TabBarBuilder(title: Resource, index: number) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? $r('app.color.primary') : $r('app.color.text_tertiary'))
        .margin({ top: 10 })
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
  }
}
