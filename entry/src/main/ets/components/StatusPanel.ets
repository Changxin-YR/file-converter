import { UiConstants } from '../common/UiConstants'

@Component
export struct StatusPanel {
  @Prop message: string = ''
  @Prop success: boolean = false
  @Prop error: boolean = false
  @Prop loading: boolean = false

  build() {
    if (this.message.length > 0 || this.loading) {
      Row({ space: 10 }) {
        if (this.loading) {
          LoadingProgress()
            .width(22)
            .height(22)
            .color($r('app.color.brand_primary'))
        }
        Text(this.message)
          .fontSize(13)
          .fontColor(this.statusColor())
          .layoutWeight(1)
      }
      .width('100%')
      .constraintSize({ minHeight: UiConstants.TOUCH_MIN_HEIGHT })
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor($r('app.color.surface_secondary'))
      .borderRadius(UiConstants.CONTROL_RADIUS)
    }
  }

  private statusColor(): ResourceColor {
    if (this.error) {
      return $r('app.color.error')
    }
    if (this.success) {
      return $r('app.color.success')
    }
    return $r('app.color.text_secondary')
  }
}
