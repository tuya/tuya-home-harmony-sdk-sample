@Component
export struct DeviceControlBaseCell {
  @Prop dpId: string = ""
  @Prop dpName: string = ""
  @Prop dpDesc: string = ""

  build() {
    Column() {
      Row() {
        // DP ID标签
        Text(this.dpId)
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor("#FF9500")
          .textAlign(TextAlign.Center)
          .width(20)
          .height(20)
          .borderRadius(10)

        // DP名称
        Text(this.dpName)
          .fontSize(15)
          .fontColor(Color.Black)
          .margin({ left: 5 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width("100%")
      .alignItems(VerticalAlign.Top)
      .padding({ left: 16, top: 16 })

      // DP描述
      Text(this.dpDesc)
        .fontSize(11)
        .fontColor("#808080")
        .margin({ left: 16, top: 5 })
        .width("100%")
    }
    .width("100%")
    .backgroundColor(Color.White)
  }
}

