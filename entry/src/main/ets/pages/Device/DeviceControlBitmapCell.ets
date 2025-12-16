import { DeviceControlBaseCell } from "./DeviceControlBaseCell"

@Component
export struct DeviceControlBitmapCell {
  @Prop dpId: string = ""
  @Prop dpName: string = ""
  @Prop dpDesc: string = ""
  @Prop stringValue: string = ""
  onValueChange?: (value: string) => void

  @State inputValue: string = ""

  aboutToAppear() {
    this.inputValue = this.stringValue
  }

  build() {
    Row() {
      DeviceControlBaseCell({
        dpId: this.dpId,
        dpName: this.dpName,
        dpDesc: this.dpDesc
      })
        .layoutWeight(1)

      Row() {
        TextInput({ placeholder: "请输入", text: this.inputValue })
          .width(160)
          .height(45)
          .backgroundColor("#F0F0F0")
          .borderRadius(10)
          .fontSize(12)
          .onChange((value: string) => {
            this.inputValue = value
          })

        Button("发送")
          .type(ButtonType.Normal)
          .fontSize(14)
          .backgroundColor("#007DFF")
          .fontColor(Color.White)
          .margin({ left: 3 })
          .onClick(() => {
            if (this.onValueChange) {
              this.onValueChange(this.inputValue)
            }
          })
          .width(40)
          .height(45)
      }
      .margin({ right: 16 })
    }
    .width("100%")
    .height(70)
    .backgroundColor(Color.White)
  }
}

