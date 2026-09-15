import { UiConstants } from '../common/UiConstants'

export interface ChipItem {
  key: string
  label: string
  enabled: boolean
}

@Component
export struct OptionChipGroup {
  @Prop items: ChipItem[] = []
  @Prop selectedKey: string = ''
  @Prop disabled: boolean = false
  onSelect: (key: string) => void = (_key: string) => {}

  build() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.items, (item: ChipItem) => {
        Column() {
          Text(item.label)
            .fontSize(14)
            .fontWeight(this.isSelectedAndEnabled(item) ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.isSelectedAndEnabled(item) ? Color.White :
              (this.isEnabled(item) ? $r('app.color.text_primary') : $r('app.color.text_disabled')))
        }
        .constraintSize({ minHeight: UiConstants.TOUCH_MIN_HEIGHT })
        .justifyContent(FlexAlign.Center)
        .padding({ left: 14, right: 14, top: 5, bottom: 5 })
        .margin({ right: 8, bottom: 8 })
        .backgroundColor(this.isSelectedAndEnabled(item) ? $r('app.color.brand_primary') :
          (this.isEnabled(item) ? $r('app.color.control_selected') : $r('app.color.control_disabled')))
        .borderRadius(UiConstants.CONTROL_RADIUS)
        .onClick(() => {
          if (!this.isEnabled(item)) {
            return
          }
          this.onSelect(item.key)
        })
      }, (item: ChipItem) => item.key)
    }
    .width('100%')
  }

  private isEnabled(item: ChipItem): boolean {
    return !this.disabled && item.enabled
  }

  private isSelectedAndEnabled(item: ChipItem): boolean {
    return this.selectedKey === item.key && this.isEnabled(item)
  }
}
