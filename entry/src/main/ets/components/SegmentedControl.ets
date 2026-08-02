import { UiConstants } from '../common/UiConstants'

export interface SegmentItem {
  key: string
  label: string
  enabled: boolean
}

@Component
export struct SegmentedControl {
  @Prop items: SegmentItem[] = []
  @Prop selectedKey: string = ''
  onSelect: (key: string) => void = (_key: string) => {}

  build() {
    Row() {
      ForEach(this.items, (item: SegmentItem) => {
        Button(item.label)
          .layoutWeight(1)
          .height(UiConstants.TOUCH_MIN_HEIGHT)
          .fontSize(14)
          .fontColor(this.selectedKey === item.key ? $r('app.color.brand_primary') :
            (item.enabled ? $r('app.color.text_secondary') : $r('app.color.text_disabled')))
          .backgroundColor(this.selectedKey === item.key ? $r('app.color.surface_primary') : Color.Transparent)
          .borderRadius(UiConstants.CONTROL_RADIUS)
          .enabled(item.enabled)
          .onClick(() => {
            if (!item.enabled) {
              return
            }
            this.onSelect(item.key)
          })
      }, (item: SegmentItem) => item.key)
    }
    .width('100%')
    .height(UiConstants.TOUCH_MIN_HEIGHT + 4)
    .padding(2)
    .backgroundColor($r('app.color.control_disabled'))
    .borderRadius(UiConstants.CONTROL_RADIUS + 2)
  }
}
