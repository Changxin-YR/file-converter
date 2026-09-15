import { router } from '@kit.ArkUI'
import { AppPageHeader } from '../components/AppPageHeader'
import { PrivacyNoticeSection } from '../components/PrivacyNoticeSection'
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
}
