import { UiConstants } from '../common/UiConstants'

@Component
export struct AppPageHeader {
  @Prop title: string = ''
  @Prop subtitle: string = ''
  @Prop showBack: boolean = true
  onBack: () => void = () => {}

  build() {
    Row({ space: 10 }) {
      if (this.showBack) {
        Button() {
          Text('‹')
            .fontSize(30)
            .fontColor($r('app.color.text_primary'))
        }
        .width(UiConstants.TOUCH_MIN_HEIGHT)
        .height(UiConstants.TOUCH_MIN_HEIGHT)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.onBack())
      }
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.subtitle.length > 0) {
          Text(this.subtitle)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height(UiConstants.HEADER_HEIGHT)
  }
}
