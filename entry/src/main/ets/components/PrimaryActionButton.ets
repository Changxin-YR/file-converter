import { UiConstants } from '../common/UiConstants'

@Component
export struct PrimaryActionButton {
  @Prop label: string = ''
  @Prop enabled: boolean = true
  @Prop loading: boolean = false
  onTap: () => void = () => {}

  build() {
    Button(this.loading ? '处理中...' : this.label)
      .width('100%')
      .height(UiConstants.ACTION_HEIGHT)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.enabled && !this.loading ? Color.White : $r('app.color.text_disabled'))
      .backgroundColor(this.enabled && !this.loading ? $r('app.color.brand_primary') : $r('app.color.control_disabled'))
      .borderRadius(UiConstants.CONTROL_RADIUS)
      .enabled(this.enabled && !this.loading)
      .onClick(() => {
        if (!this.enabled || this.loading) {
          return
        }
        this.onTap()
      })
  }
}
