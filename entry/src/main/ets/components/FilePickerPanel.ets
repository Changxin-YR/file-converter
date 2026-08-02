import { UiConstants } from '../common/UiConstants'
import { PrimaryActionButton } from './PrimaryActionButton'

@Component
export struct FilePickerPanel {
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop asset: Resource = $r('app.media.app_icon')
  @Prop buttonLabel: string = ''
  @Prop selectedName: string = ''
  @Prop isEnabled: boolean = true
  onPick: () => void = () => {}

  build() {
    Row({ space: 16 }) {
      Image(this.asset)
        .width(80)
        .height(80)
        .objectFit(ImageFit.Contain)
        .opacity(this.isEnabled ? 1 : 0.55)
      Column({ space: 8 }) {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isEnabled ? $r('app.color.text_primary') : $r('app.color.text_disabled'))
        Text(this.selectedName.length > 0 ? this.selectedName : this.description)
          .fontSize(12)
          .fontColor(this.isEnabled ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
          .maxLines(2)
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          PrimaryActionButton({
            label: this.buttonLabel,
            isEnabled: this.isEnabled,
            loading: false,
            onTap: () => {
              if (!this.isEnabled) {
                return
              }
              this.onPick()
            }
          })
        }
        .width(150)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(156)
    .alignItems(VerticalAlign.Center)
    .padding(16)
    .backgroundColor($r('app.color.surface_secondary'))
    .borderRadius(UiConstants.CARD_RADIUS)
    .border({ width: 1, color: $r('app.color.border_subtle'), style: BorderStyle.Dashed })
  }
}
