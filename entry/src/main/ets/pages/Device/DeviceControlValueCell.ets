import { DeviceControlBaseCell } from "./DeviceControlBaseCell"

@Component
export struct DeviceControlValueCell {
  @Prop dpId: string = ""
  @Prop dpName: string = ""
  @Prop dpDesc: string = ""
  @Prop value: number = 0
  @Prop min: number = 0
  @Prop max: number = 100
  @Prop step: number = 1
  onValueChange?: (value: number) => void

  @State inputValue: string = ""

  aboutToAppear() {
    this.inputValue = this.value.toString()
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
        // 减号按钮
        Button("-")
          .type(ButtonType.Circle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .backgroundColor("#F0F0F0")
          .fontColor(Color.Black)
          .width(45)
          .height(45)
          .onClick(() => {
            let newValue = parseFloat(this.inputValue) - this.step
            newValue = newValue < this.min ? this.min : newValue
            this.inputValue = newValue.toString()
          })

        // 数值输入框
        TextInput({ placeholder: "0", text: this.inputValue })
          .width(60)
          .height(45)
          .backgroundColor("#F0F0F0")
          .textAlign(TextAlign.Center)
          .fontSize(12)
          .onChange((value: string) => {
            this.inputValue = value
          })

        // 加号按钮
        Button("+")
          .type(ButtonType.Circle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .backgroundColor("#F0F0F0")
          .fontColor(Color.Black)
          .width(45)
          .height(45)
          .onClick(() => {
            let newValue = parseFloat(this.inputValue) + this.step
            newValue = newValue > this.max ? this.max : newValue
            this.inputValue = newValue.toString()
          })

        // 发送按钮
        Button("发送")
          .type(ButtonType.Normal)
          .fontSize(14)
          .backgroundColor("#007DFF")
          .fontColor(Color.White)
          .margin({ left: 3 })
          .onClick(() => {
            const numValue = parseFloat(this.inputValue)
            if (!isNaN(numValue) && this.onValueChange) {
              this.onValueChange(numValue)
            }
          })
          .width(60)
          .height(45)
      }
      .margin({ right: 16 })
    }
    .width("100%")
    .height(70)
    .backgroundColor(Color.White)
  }
}

