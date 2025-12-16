import { DeviceControlBaseCell } from "./DeviceControlBaseCell"

@Component
export struct DeviceControlBoolCell {
  @Prop dpId: string = ""
  @Prop dpName: string = ""
  @Prop dpDesc: string = ""
  @Prop isOn: boolean = false
  onValueChange?: (value: boolean) => void

  @State private currentValue: boolean = false
  private lastPropValue: boolean = false

  aboutToAppear() {
    this.currentValue = this.isOn
    this.lastPropValue = this.isOn
  }

  aboutToUpdate() {
    // 如果外部值发生变化且与当前值不同，说明是外部更新（如设备上报）
    if (this.isOn !== this.lastPropValue && this.isOn !== this.currentValue) {
      this.currentValue = this.isOn
    }
    this.lastPropValue = this.isOn
  }

  build() {
    Row() {
      DeviceControlBaseCell({
        dpId: this.dpId,
        dpName: this.dpName,
        dpDesc: this.dpDesc
      })
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.currentValue })
        .selectedColor("#007DFF")
        .onChange((isOn: boolean) => {
          // 用户操作时，立即更新本地状态
          this.currentValue = isOn
          this.lastPropValue = isOn
          if (this.onValueChange) {
            this.onValueChange(isOn)
          }
        })
        .margin({ right: 16 })
    }
    .width("100%")
    .height(70)
    .backgroundColor(Color.White)
  }
}

