@Component
export struct HomeActionCell {
  @Prop title: string
  build() {
    Row() {
      Text(this.title)
        .fontSize(20)
        .fontColor(Color.Red)
    }.justifyContent(FlexAlign.Center)
    .backgroundColor(Color.White)
    .width("100%")
    .height(50)
  }
}