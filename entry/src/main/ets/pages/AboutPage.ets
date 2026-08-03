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
          Column({ space: 16 }) {
            Image($r('app.media.ui_about_app_icon'))
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
            this.PrivacySection()
            Text('版本 1.0.0 · HarmonyOS API 22 · 6.0.2')
              .fontSize(13)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ top: 24 })
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
      this.PrivacyRow('文件只在设备本地处理', $r('app.media.ui_privacy_local'))
      this.PrivacyRow('不联网、无后端、不上传', $r('app.media.ui_privacy_offline'))
      this.PrivacyRow('不收集、不存储用户文件', $r('app.media.ui_privacy_storage'))
      this.PrivacyRow('仅在使用时访问所选文件', $r('app.media.ui_privacy_access'))
    }
    .width('100%')
    .margin({ top: 24 })
    .backgroundColor($r('app.color.surface_primary'))
    .borderRadius(20)
    .shadow({ radius: 18, color: $r('app.color.shadow_panel'), offsetX: 0, offsetY: 8 })
  }

  @Builder
  PrivacyRow(label: string, asset: Resource) {
    Row({ space: 18 }) {
      Image(asset)
        .width(40)
        .height(40)
        .objectFit(ImageFit.Contain)
      Text(label)
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
    }
    .width('100%')
    .constraintSize({ minHeight: 58 })
    .padding({ left: 18, right: 18, top: 8, bottom: 8 })
    .border({ width: { bottom: 1 }, color: $r('app.color.border_subtle') })
  }
}
