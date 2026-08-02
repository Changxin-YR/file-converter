/**
 * 关于页
 * 应用信息与隐私声明（单机离线、无后端）。
 */
@Entry
@Component
struct AboutPage {
  build() {
    Navigation() {
      Scroll() {
        Column({ space: 16 }) {
          Text('🔒')
            .fontSize(56)
            .margin({ top: 40 })

          Text($r('app.string.app_name'))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)

          Text('版本 1.0.0')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))

          Column({ space: 8 }) {
            Text('隐私声明')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Text('本应用为单机离线应用:\n· 不联网、无后端、不上传任何数据\n· 所有格式转换在设备本地完成\n· 不收集、不存储您的个人文件\n· 权限最小化,仅在使用时访问所选文件')
              .fontSize(14)
              .lineHeight(24)
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')
          .padding(16)
          .borderRadius(12)
          .backgroundColor($r('app.color.card_background'))
          .margin({ top: 8 })
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            Text('开发者信息')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)

            Text('开发者: MaxTools Studio')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
            Text('联系邮箱: support@maxtools.com')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
            Text('隐私政策: https://maxtools.com/privacy')
              .fontSize(14)
              .fontColor($r('app.color.primary'))
              .decoration({ type: TextDecorationType.Underline })
          }
          .width('100%')
          .padding(16)
          .borderRadius(12)
          .backgroundColor($r('app.color.card_background'))
          .margin({ top: 8 })
          .alignItems(HorizontalAlign.Start)

          Text('HarmonyOS API 22 · 6.0.2')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(20)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .title('关于')
    .titleMode(NavigationTitleMode.Mini)
  }
}
