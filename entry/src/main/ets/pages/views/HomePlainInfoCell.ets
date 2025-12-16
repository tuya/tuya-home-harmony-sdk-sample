import { ZRouter } from "@hzw/zrouter"

@Component
export struct HomePlainInfoCell {
  @Prop title: string
  @Prop showArrow: boolean = true
  @Prop isOnline: boolean | undefined = undefined

  build() {
    Column() {
      Row() {
        Row() {
          // 在线状态指示器
          if (this.isOnline !== undefined) {
            Circle({ width: 8, height: 8 })
              .fill(this.isOnline ? "#4CAF50" : "#9E9E9E")
              .margin({ right: 8 })
          }
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        if (this.showArrow) {
          Image($r("app.media.arrow"))
            .objectFit(ImageFit.Contain)
            .width(25)
            .height(25)
        }
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width("100%")
      .height(56)
      .padding({ left: 12, right: 12 })

      Divider()
        .width("100%")
        .height(px2vp(1))
    }.width("100%")
    .backgroundColor(Color.White)
  }
}