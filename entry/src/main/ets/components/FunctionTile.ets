import { UiConstants } from '../common/UiConstants'

@Component
export struct FunctionTile {
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop asset: Resource = $r('app.media.app_icon')
  @Prop enabled: boolean = true
  @Prop developing: boolean = false
  onTap: () => void = () => {}

  build() {
    Row({ space: 10 }) {
      Image(this.asset)
        .width(46)
        .height(46)
        .objectFit(ImageFit.Contain)
        .opacity(this.enabled ? 1 : 0.45)
      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.enabled ? $r('app.color.text_primary') : $r('app.color.text_disabled'))
          .maxLines(1)
        Text(this.developing || !this.enabled ? '功能正在开发' : this.description)
          .fontSize(10)
          .fontColor(this.enabled ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height(74)
    .padding({ left: 12, right: 10, top: 8, bottom: 8 })
    .backgroundColor(this.enabled ? $r('app.color.surface_primary') : $r('app.color.control_disabled'))
    .border({ width: 1, color: $r('app.color.border_subtle') })
    .borderRadius(UiConstants.CONTROL_RADIUS)
    .onClick(() => {
      if (!this.enabled || this.developing) {
        return
      }
      this.onTap()
    })
  }
}
