import { DeviceControlBaseCell } from "./DeviceControlBaseCell"
import { promptAction } from '@kit.ArkUI'

@Component
export struct DeviceControlEnumCell {
  @Prop dpId: string = ""
  @Prop dpName: string = ""
  @Prop dpDesc: string = ""
  @Prop enumValues: string[] = []
  @Prop selectedValue: string = ""
  onValueChange?: (value: string) => void

  @State showPicker: boolean = false
  @State private currentValue: string = ""
  private lastPropValue: string = ""

  aboutToAppear() {
    this.currentValue = this.selectedValue
    this.lastPropValue = this.selectedValue
  }

  aboutToUpdate() {
    // 如果外部值发生变化且与当前值不同，说明是外部更新（如设备上报）
    if (this.selectedValue !== this.lastPropValue && this.selectedValue !== this.currentValue) {
      this.currentValue = this.selectedValue
    }
    this.lastPropValue = this.selectedValue
  }

  build() {
    Row() {
      DeviceControlBaseCell({
        dpId: this.dpId,
        dpName: this.dpName,
        dpDesc: this.dpDesc
      })
        .layoutWeight(1)

      Button(this.currentValue || "请选择")
        .type(ButtonType.Normal)
        .fontSize(14)
        .backgroundColor("#F0F0F0")
        .fontColor(Color.Black)
        .onClick(() => {
          this.showPicker = true
        })
        .margin({ right: 16 })
        .width(100)
        .height(45)
    }
    .width("100%")
    .height(70)
    .backgroundColor(Color.White)
    .bindSheet($$this.showPicker, this.buildPickerSheet(), {
      height: Math.min(this.enumValues.length * 60 + 100, 400),
      showClose: true,
      dragBar: true
    })
  }

  @Builder
  buildPickerSheet() {
    Column() {
      Text("请选择")
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width("100%")
        .textAlign(TextAlign.Center)
        .padding({ top: 16, bottom: 16 })

      List() {
        ForEach(this.enumValues, (value: string, index: number) => {
          ListItem() {
            Text(value)
              .fontSize(16)
              .width("100%")
              .height(50)
              .textAlign(TextAlign.Center)
          }
          .onClick(() => {
            // 用户操作时，立即更新本地状态
            this.currentValue = value
            this.lastPropValue = value
            if (this.onValueChange) {
              this.onValueChange(value)
            }
            this.showPicker = false
          })
        }, (value: string) => value)
      }
      .layoutWeight(1)
      .width("100%")
    }
    .width("100%")
    .height("100%")
    .backgroundColor(Color.White)
  }
}

