import { UiConstants } from '../common/UiConstants'
import { PrimaryActionButton } from './PrimaryActionButton'

@Component
export struct FilePickerPanel {
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop asset: Resource = $r('app.media.app_icon')
  @Prop buttonLabel: string = ''
  @Prop selectedName: string = ''
  @Prop enabled: boolean = true
  onPick: () => void = () => {}

  build() {
    Column({ space: 10 }) {
      Image(this.asset)
        .width(92)
        .height(92)
        .objectFit(ImageFit.Contain)
        .opacity(this.enabled ? 1 : 0.55)
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.enabled ? $r('app.color.text_primary') : $r('app.color.text_disabled'))
      Text(this.selectedName.length > 0 ? this.selectedName : this.description)
        .fontSize(12)
        .fontColor(this.enabled ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Row() {
        PrimaryActionButton({
          label: this.buttonLabel,
          enabled: this.enabled,
          loading: false,
          onTap: () => {
            if (!this.enabled) {
              return
            }
            this.onPick()
          }
        })
      }
      .width(150)
    }
    .width('100%')
    .height(184)
    .justifyContent(FlexAlign.Center)
    .padding(16)
    .backgroundColor($r('app.color.surface_secondary'))
    .borderRadius(UiConstants.CARD_RADIUS)
    .border({ width: 1, color: $r('app.color.border_subtle'), style: BorderStyle.Dashed })
  }
}
