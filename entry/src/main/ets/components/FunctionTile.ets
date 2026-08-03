import { UiConstants } from '../common/UiConstants'

@Component
export struct FunctionTile {
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop asset: Resource = $r('app.media.app_icon')
  @Prop isEnabled: boolean = true
  @Prop developing: boolean = false
  onTap: () => void = () => {}

  build() {
    Row({ space: 8 }) {
      Stack() {
        Image(this.asset)
          .width(44)
          .height(44)
          .objectFit(ImageFit.Contain)
          .opacity(this.isEnabled ? 1 : 0.45)
      }
      .width(56)
      .height(56)
      .backgroundColor(this.isEnabled ? $r('app.color.surface_secondary') : $r('app.color.control_disabled'))
      .borderRadius(28)

      Column({ space: 5 }) {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isEnabled ? $r('app.color.text_primary') : $r('app.color.text_disabled'))
          .maxLines(1)
        Text(this.developing || !this.isEnabled ? '功能正在开发' : this.description)
          .fontSize(10)
          .fontColor(this.isEnabled ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
          .maxLines(2)
          .lineHeight(15)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
    }
    .width('100%')
    .height(96)
    .padding({ left: 12, right: 8, top: 12, bottom: 12 })
    .backgroundColor(this.isEnabled ? $r('app.color.surface_primary') : $r('app.color.control_disabled'))
    .border({ width: 1, color: $r('app.color.border_subtle') })
    .borderRadius(UiConstants.CARD_RADIUS)
    .shadow({ radius: 12, color: $r('app.color.shadow_card'), offsetX: 0, offsetY: 4 })
    .onClick(() => {
      if (!this.isEnabled || this.developing) {
        return
      }
      this.onTap()
    })
  }
}
