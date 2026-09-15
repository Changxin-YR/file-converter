@Component
export struct PrivacyNoticeSection {
  build() {
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
        .accessibilityText(label)
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
