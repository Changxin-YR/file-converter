/**
 * 格式选择器
 * 胶囊式格式选择,支持禁用态（非原生支持灰置）。
 */
import { FormatInfo } from '../common/FormatTypes'

@Component
export struct FormatSelector {
  @Prop formats: FormatInfo[] = []
  @Prop selected: string = ''
  @Prop disabled: boolean = false
  selectCallback: (extension: string) => void = (_ext: string) => {}

  build() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.formats, (format: FormatInfo) => {
        Row({ space: 4 }) {
          Text(format.displayName)
            .fontSize(14)
            .fontColor(this.isSelected(format) ? Color.White : $r('app.color.text_primary'))
            .fontWeight(this.isSelected(format) ? FontWeight.Medium : FontWeight.Normal)
          if (!format.nativeSupported) {
            Text('功能正在开发')
              .fontSize(10)
              .fontColor($r('app.color.text_tertiary'))
          }
        }
        .padding({ left: 16, right: 16, top: 6, bottom: 6 })
        .borderRadius(18)
        .backgroundColor(this.isSelected(format) ? $r('app.color.primary') : $r('app.color.chip_background'))
        .opacity(this.isEnabled(format) ? 1 : 0.4)
        .margin({ top: 6, right: 8 })
        .onClick(() => {
          if (!this.isEnabled(format)) {
            return
          }
          this.selectCallback(format.extension)
        })
      }, (format: FormatInfo) => format.extension)
    }
    .width('100%')
  }

  private isSelected(format: FormatInfo): boolean {
    return this.selected === format.extension
  }

  private isEnabled(format: FormatInfo): boolean {
    if (this.disabled) {
      return false
    }
    return format.nativeSupported
  }
}
