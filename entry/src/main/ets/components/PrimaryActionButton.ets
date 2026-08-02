import { UiConstants } from '../common/UiConstants'

@Component
export struct PrimaryActionButton {
  @Prop label: string = ''
  @Prop isEnabled: boolean = true
  @Prop loading: boolean = false
  onTap: () => void = () => {}

  build() {
    Button(this.loading ? '处理中...' : this.label)
      .width('100%')
      .height(UiConstants.ACTION_HEIGHT)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.isEnabled && !this.loading ? Color.White : $r('app.color.text_disabled'))
      .backgroundColor(this.isEnabled && !this.loading ? $r('app.color.brand_primary') : $r('app.color.control_disabled'))
      .borderRadius(UiConstants.CONTROL_RADIUS)
      .enabled(this.isEnabled && !this.loading)
      .onClick(() => {
        if (!this.isEnabled || this.loading) {
          return
        }
        this.onTap()
      })
  }
}
