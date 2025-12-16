import { ZRouter } from "@hzw/zrouter"

@Component
export struct HMFamilyTitleView {
  @Prop title: string
  @Prop isSelect: boolean = false
  onClickFamily: ()=>void = ()=>{}

  build() {
    Column() {
      Row() {
        Row({ space: 16 }) {
          Image($r("app.media.home_manage_selected"))
            .width(20)
            .height(20)
            .visibility(this.isSelect ? Visibility.Visible: Visibility.Hidden)
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
        }

        Button("查看家庭").onClick(()=> {
          if (this.onClickFamily) {
            this.onClickFamily()
          }
        })
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