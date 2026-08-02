import { router } from '@kit.ArkUI'
import { AppPageHeader } from '../components/AppPageHeader'
import { UiConstants } from '../common/UiConstants'

@Entry
@Component
struct AboutPage {
  build() {
    Navigation() {
      Column() {
        AppPageHeader({ title: '关于', onBack: () => router.back() })
          .padding({ left: 4, right: 16 })
        Scroll() {
          Column({ space: 18 }) {
            Image($r('app.media.app_icon'))
              .width(112)
              .height(112)
              .objectFit(ImageFit.Contain)
              .margin({ top: 24 })
            Text($r('app.string.app_name'))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text('单机离线，数据不出设备')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.brand_primary'))
            this.PrivacySection()
            Text('版本 1.0.0 · HarmonyOS API 22 · 6.0.2')
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ top: 8 })
          }
          .width('100%')
          .constraintSize({ maxWidth: UiConstants.CONTENT_MAX_WIDTH })
          .padding({ left: UiConstants.PAGE_PADDING_PHONE, right: UiConstants.PAGE_PADDING_PHONE, bottom: 24 })
          .alignItems(HorizontalAlign.Center)
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
  PrivacySection() {
    Column({ space: 0 }) {
      this.PrivacyRow('文件只在设备本地处理')
      this.PrivacyRow('不联网、无后端、不上传')
      this.PrivacyRow('不收集、不存储用户文件')
      this.PrivacyRow('仅在使用时访问所选文件')
    }
    .width('100%')
    .backgroundColor($r('app.color.surface_primary'))
    .borderRadius(UiConstants.CARD_RADIUS)
  }

  @Builder
  PrivacyRow(label: string) {
    Row({ space: 12 }) {
      Text('✓')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.success'))
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
    }
    .width('100%')
    .constraintSize({ minHeight: UiConstants.TOUCH_MIN_HEIGHT })
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: $r('app.color.border_subtle') })
  }
}
