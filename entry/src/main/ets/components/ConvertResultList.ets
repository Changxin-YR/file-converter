/**
 * 转换结果列表组件
 * 展示转换产物路径列表。
 */
@Component
export struct ConvertResultList {
  @Prop results: string[] = []

  build() {
    Column({ space: 8 }) {
      ForEach(this.results, (path: string) => {
        Row() {
          Text('✓')
            .fontSize(14)
            .fontColor($r('app.color.success'))
            .margin({ right: 8 })
          Text(path)
            .fontSize(12)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .borderRadius(8)
        .backgroundColor($r('app.color.card_background'))
      }, (path: string) => path)
    }
    .width('100%')
  }
}
