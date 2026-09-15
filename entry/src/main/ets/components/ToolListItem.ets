import { UiConstants } from '../common/UiConstants'

export interface ToolListData {
  key: string
  title: string
  description: string
  asset: Resource
  enabled: boolean
}

@Component
export struct ToolListItem {
  @Prop data: ToolListData = {
    key: '', title: '', description: '', asset: $r('app.media.app_icon'), enabled: true
  }
  onTap: (key: string) => void = (_key: string) => {}

  build() {
    Row({ space: 12 }) {
      Image(this.data.asset)
        .accessibilityText(this.data.title + '图标')
        .width(44)
        .height(44)
        .objectFit(ImageFit.Contain)
        .opacity(this.data.enabled ? 1 : 0.45)
      Column({ space: 4 }) {
        Text(this.data.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.data.enabled ? $r('app.color.text_primary') : $r('app.color.text_disabled'))
        Text(this.data.description)
          .fontSize(12)
          .fontColor(this.data.enabled ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›')
        .fontSize(24)
        .fontColor(this.data.enabled ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
    }
    .width('100%')
    .constraintSize({ minHeight: 68 })
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.surface_primary'))
    .borderRadius(UiConstants.CONTROL_RADIUS)
    .onClick(() => {
      if (!this.data.enabled) {
        return
      }
      this.onTap(this.data.key)
    })
  }
}
