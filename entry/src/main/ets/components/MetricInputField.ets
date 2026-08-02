import { UiConstants } from '../common/UiConstants'

@Component
export struct MetricInputField {
  @Prop label: string = ''
  @Prop value: string = ''
  @Prop placeholder: string = ''
  @Prop suffix: string = ''
  @Prop isEnabled: boolean = true
  onChange: (value: string) => void = (_value: string) => {}

  build() {
    Column({ space: 6 }) {
      Text(this.label)
        .fontSize(12)
        .fontColor(this.isEnabled ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
      Row({ space: 6 }) {
        TextInput({ text: this.value, placeholder: this.placeholder })
          .layoutWeight(1)
          .height(UiConstants.TOUCH_MIN_HEIGHT)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .backgroundColor(Color.Transparent)
          .enabled(this.isEnabled)
          .onChange((value: string) => this.onChange(value))
        if (this.suffix.length > 0) {
          Text(this.suffix)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 72 })
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(this.isEnabled ? $r('app.color.surface_primary') : $r('app.color.control_disabled'))
    .border({ width: 1, color: $r('app.color.border_subtle') })
    .borderRadius(UiConstants.CONTROL_RADIUS)
    .alignItems(HorizontalAlign.Start)
  }
}
