/**
 * 转换进度条组件
 * 线性进度 + 百分比文本。
 */
@Component
export struct ConvertProgressBar {
  @Prop progress: number = 0
  @Prop total: number = 100
  @Prop showText: boolean = true

  build() {
    Column({ space: 6 }) {
      Progress({ value: this.progress, total: this.total, type: ProgressType.Linear })
        .width('100%')
        .color($r('app.color.primary'))
      if (this.showText) {
        Row() {
          Text(`${this.progress}%`)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
  }
}
