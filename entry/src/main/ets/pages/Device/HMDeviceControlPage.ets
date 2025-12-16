import { Route, ZRouter } from "@hzw/zrouter"
import { TSmartDevice, TSmartDeviceModel, TSmartDeviceListener, DpsType, DpType } from "@thingsmart/device"
import { TSmartSchemaModel, TSmartSchemaPropertyModel } from "@thingsmart/channel"
import { TSmartPublishResult } from "@thingsmart/channel"
import { promptAction } from '@kit.ArkUI'
import { DeviceControlBoolCell } from "./DeviceControlBoolCell"
import { DeviceControlEnumCell } from "./DeviceControlEnumCell"
import { DeviceControlStringCell } from "./DeviceControlStringCell"
import { DeviceControlValueCell } from "./DeviceControlValueCell"
import { DeviceControlBitmapCell } from "./DeviceControlBitmapCell"
import { HomeActionCell } from "../views/HomeActionCell"
import { HomePlainInfoCell } from "../views/HomePlainInfoCell"

@Route({ name: "HMDeviceControlPage" })
@Component
export struct HMDeviceControlPage {
  deviceId: string = ""
  @State device: TSmartDevice | undefined = undefined
  @State deviceModel: TSmartDeviceModel | undefined = undefined
  @State schemaArray: TSmartSchemaModel[] = []
  @State dps: DpsType = {}
  @State deviceName: string = "设备控制"

  private deviceListener?: TSmartDeviceListener
  private isRefreshing: boolean = false // 防止循环调用的标志位

  async aboutToAppear() {
    const param = ZRouter.getInstance().getParam() as Record<string, Object>
    this.deviceId = param["deviceId"] as string

    // 创建设备实例
    this.device = TSmartDevice.create(this.deviceId)
    if (this.device) {
      // 同步设备信息
      this.deviceModel = await this.device.syncDeviceInfo()
      if (this.deviceModel) {
        this.deviceName = this.deviceModel.name
        this.schemaArray = this.deviceModel.schemaArray || []
        this.dps = this.deviceModel.dps || {}
      }

      // 注册监听器
      this.deviceListener = {
        onDpsChanged: (devId: string, dps: DpsType, dpsTime: Record<string, Object>) => {
          if (devId === this.deviceId) {
            this.dps = dps
            if (this.deviceModel) {
              this.deviceModel.dps = dps
            }
          }
        },
        onOnlineChanged: (devId: string) => {
          if (devId === this.deviceId && !this.isRefreshing) {
            this.refreshDeviceInfo()
          }
        },
        onDeviceInfoUpdated: (devId: string) => {
          if (devId === this.deviceId && !this.isRefreshing) {
            this.refreshDeviceInfo()
          }
        },
        onDeviceRemoved: (devId: string) => {
          if (devId === this.deviceId) {
            promptAction.showToast({
              message: "设备已被移除",
              duration: 1500
            })
            ZRouter.getInstance().pop()
          }
        },
        onWarningInfoUpdate: (devId: string, info: Record<string, Object>) => {
          // 警告信息更新
        },
        onSignalQuery: (devId: string, signal: number) => {
          // 信号强度查询
        }
      }
      this.device.registerListener(this.deviceListener)
    }
  }

  aboutToDisappear() {
    if (this.device && this.deviceListener) {
      this.device.unregisterListener()
    }
  }

  private async refreshDeviceInfo() {
    if (this.device && !this.isRefreshing) {
      this.isRefreshing = true
      try {
        this.deviceModel = await this.device.syncDeviceInfo()
        if (this.deviceModel) {
          this.deviceName = this.deviceModel.name
          this.schemaArray = this.deviceModel.schemaArray || []
          this.dps = this.deviceModel.dps || {}
        }
      } finally {
        // 延迟重置标志位，防止短时间内重复调用
        setTimeout(() => {
          this.isRefreshing = false
        }, 1000)
      }
    }
  }

  private getDpDesc(schemaModel: TSmartSchemaModel): string {
    let rwMode = ""
    if (schemaModel.mode === "rw") {
      rwMode = "可下发 可上报"
    } else if (schemaModel.mode === "ro") {
      rwMode = "仅上报"
    } else if (schemaModel.mode === "wr") {
      rwMode = "仅下发"
    }

    let type = ""
    if (schemaModel.type === "obj") {
      const property = schemaModel.property
      if (property) {
        if (property.type === "bool") {
          type = "布尔型"
        } else if (property.type === "enum") {
          type = "枚举型"
        } else if (property.type === "value") {
          type = "数值型"
        } else if (property.type === "bitmap") {
          type = "故障型"
        } else if (property.type === "string") {
          type = "字符串型"
        } else if (property.type === "struct") {
          type = "结构体"
        } else if (property.type === "array") {
          type = "数组"
        } else {
          type = property.type
        }
      }
    } else if (schemaModel.type === "raw") {
      type = "透传型"
    }

    return `${rwMode} | ${type}`
  }

  private handleStructOrArrayValue(dpId: string, value: string) {
    try {
      let parsed: string | number | boolean | null | Record<string, Object> | Object[] = JSON.parse(value) as (string | number | boolean | null | Record<string, Object> | Object[])
      // 对于结构体或数组类型，需要转换为字符串或保持为对象
      // 但 DpType 只支持基本类型，所以这里转换为字符串
      if (typeof parsed === 'string' || typeof parsed === 'number' || typeof parsed === 'boolean' || parsed === null) {
        this.triggerPublishDp(dpId, parsed as DpType)
      } else {
        // 如果是对象或数组，转换为字符串
        this.triggerPublishDp(dpId, value)
      }
    } catch {
      this.triggerPublishDp(dpId, value)
    }
  }

  private async triggerPublishDp(dpId: string, dpValue: DpType) {
    if (!this.device) {
      return
    }

    // 检查设备是否在线
    if (!this.deviceModel || !this.deviceModel.isOnline()) {
      promptAction.showToast({
        message: "设备已离线",
        duration: 2000
      })
      return
    }

    const dps: DpsType = {}
    dps[dpId] = dpValue

    try {
      const dpsString = JSON.stringify(dps)
      const result: TSmartPublishResult | undefined = await this.device.publishDps(dpsString)
      if (result) {
        promptAction.showToast({
          message: "下发成功",
          duration: 1500
        })
      } else {
        promptAction.showToast({
          message: "下发失败",
          duration: 1500
        })
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error) || "未知错误"
      promptAction.showToast({
        message: `下发失败: ${errorMsg}`,
        duration: 2000
      })
    }
  }

  @State showRemoveDialog: boolean = false

  private async clickRemove() {
    this.showRemoveDialog = true
  }

  @Builder
  buildRemoveDialog() {
    Column() {
      Text("移除 or 重置")
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width("100%")
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 20 })

      Button("移除")
        .type(ButtonType.Normal)
        .width("90%")
        .height(50)
        .margin({ bottom: 10 })
        .onClick(() => {
          this.showRemoveDialog = false
          this.doRemoveAction()
        })

      Button("重置")
        .type(ButtonType.Normal)
        .width("90%")
        .height(50)
        .margin({ bottom: 20 })
        .onClick(() => {
          this.showRemoveDialog = false
          this.doResetAction()
        })
    }
    .width("100%")
    .backgroundColor(Color.White)
    .borderRadius(10)
  }

  private async doRemoveAction() {
    if (!this.device) {
      return
    }

    try {
      promptAction.showToast({
        message: "正在移除",
        duration: 1000
      })
      await this.device.remove(false)
      promptAction.showToast({
        message: "移除成功",
        duration: 1500
      })
      ZRouter.getInstance().pop()
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error) || "未知错误"
      promptAction.showToast({
        message: `移除失败: ${errorMsg}`,
        duration: 2000
      })
    }
  }

  private async doResetAction() {
    if (!this.device) {
      return
    }

    try {
      promptAction.showToast({
        message: "正在重置",
        duration: 1000
      })
      await this.device.remove(true)
      promptAction.showToast({
        message: "重置成功",
        duration: 1500
      })
      ZRouter.getInstance().pop()
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error) || "未知错误"
      promptAction.showToast({
        message: `重置失败: ${errorMsg}`,
        duration: 2000
      })
    }
  }

  build() {
    NavDestination() {
      List({ space: 16 }) {
        // 操作设备区域
        ListItemGroup() {
          ListItem() {
            HomeActionCell({ title: "移除/恢复出厂" })
          }
          .onClick(() => {
            this.clickRemove()
          })
        }
        .clip(true)
        .borderRadius(8)

        // 控制设备区域
        ListItemGroup() {
          ForEach(this.schemaArray, (schema: TSmartSchemaModel, index: number) => {
            ListItem() {
              this.buildControlCell(schema)
            }
          }, (schema: TSmartSchemaModel) => schema.dpId || `${schema.code}_${schema.type}`)
        }
        .clip(true)
        .borderRadius(8)
      }
      .padding({ left: 16, right: 16 })
    }
    .title(this.deviceName)
    .backgroundColor("#efefef")
    .bindSheet($$this.showRemoveDialog, this.buildRemoveDialog(), {
      height: 200,
      showClose: true,
      dragBar: true
    })
  }

  @Builder
  buildControlCell(schemaModel: TSmartSchemaModel) {
    if (schemaModel.type === "obj") {
      if (schemaModel.property) {
        if (schemaModel.property.type === "bool") {
          // 布尔型
          DeviceControlBoolCell({
            dpId: schemaModel.dpId || "",
            dpName: schemaModel.name || "",
            dpDesc: this.getDpDesc(schemaModel),
            isOn: this.dps[schemaModel.dpId || ""] ? Boolean(this.dps[schemaModel.dpId || ""]) : false,
            onValueChange: (value: boolean) => {
              this.triggerPublishDp(schemaModel.dpId || "", value)
            }
          })
        } else if (schemaModel.property.type === "enum") {
          // 枚举型
          DeviceControlEnumCell({
            dpId: schemaModel.dpId || "",
            dpName: schemaModel.name || "",
            dpDesc: this.getDpDesc(schemaModel),
            enumValues: schemaModel.property.range || [],
            selectedValue: this.dps[schemaModel.dpId || ""] ? String(this.dps[schemaModel.dpId || ""]) : "",
            onValueChange: (value: string) => {
              this.triggerPublishDp(schemaModel.dpId || "", value)
            }
          })
        } else if (schemaModel.property.type === "value") {
          // 数值型
          DeviceControlValueCell({
            dpId: schemaModel.dpId || "",
            dpName: schemaModel.name || "",
            dpDesc: this.getDpDesc(schemaModel),
            value: this.dps[schemaModel.dpId || ""] ? Number(this.dps[schemaModel.dpId || ""]) : 0,
            min: schemaModel.property.min || 0,
            max: schemaModel.property.max || 100,
            step: schemaModel.property.step || 1,
            onValueChange: (value: number) => {
              this.triggerPublishDp(schemaModel.dpId || "", value)
            }
          })
        } else if (schemaModel.property.type === "bitmap") {
          // bitmap型
          DeviceControlBitmapCell({
            dpId: schemaModel.dpId || "",
            dpName: schemaModel.name || "",
            dpDesc: this.getDpDesc(schemaModel),
            stringValue: this.dps[schemaModel.dpId || ""] ? String(this.dps[schemaModel.dpId || ""]) : "",
            onValueChange: (value: string) => {
              this.triggerPublishDp(schemaModel.dpId || "", value)
            }
          })
        } else if (schemaModel.property.type === "string") {
          // 字符串型
          DeviceControlStringCell({
            dpId: schemaModel.dpId || "",
            dpName: schemaModel.name || "",
            dpDesc: this.getDpDesc(schemaModel),
            stringValue: this.dps[schemaModel.dpId || ""] ? String(this.dps[schemaModel.dpId || ""]) : "",
            onValueChange: (value: string) => {
              this.triggerPublishDp(schemaModel.dpId || "", value)
            }
          })
        } else if (schemaModel.property.type === "struct" || schemaModel.property.type === "array") {
          // 结构体或数组
          DeviceControlStringCell({
            dpId: schemaModel.dpId || "",
            dpName: schemaModel.name || "",
            dpDesc: this.getDpDesc(schemaModel),
            stringValue: this.dps[schemaModel.dpId || ""] ? JSON.stringify(this.dps[schemaModel.dpId || ""]) : "",
            onValueChange: (value: string) => {
              this.handleStructOrArrayValue(schemaModel.dpId || "", value)
            }
          })
        } else {
          // 其他类型，使用字符串输入
          DeviceControlStringCell({
            dpId: schemaModel.dpId || "",
            dpName: schemaModel.name || "",
            dpDesc: this.getDpDesc(schemaModel),
            stringValue: this.dps[schemaModel.dpId || ""] ? String(this.dps[schemaModel.dpId || ""]) : "",
            onValueChange: (value: string) => {
              this.triggerPublishDp(schemaModel.dpId || "", value)
            }
          })
        }
      }
    } else if (schemaModel.type === "raw") {
      // 透传型
      DeviceControlStringCell({
        dpId: schemaModel.dpId || "",
        dpName: schemaModel.name || "",
        dpDesc: this.getDpDesc(schemaModel),
        stringValue: this.dps[schemaModel.dpId || ""] ? String(this.dps[schemaModel.dpId || ""]) : "",
        onValueChange: (value: string) => {
          this.triggerPublishDp(schemaModel.dpId || "", value)
        }
      })
    } else {
      // 默认使用字符串输入
      DeviceControlStringCell({
        dpId: schemaModel.dpId || "",
        dpName: schemaModel.name || "",
        dpDesc: this.getDpDesc(schemaModel),
        stringValue: this.dps[schemaModel.dpId || ""] ? String(this.dps[schemaModel.dpId || ""]) : "",
        onValueChange: (value: string) => {
          this.triggerPublishDp(schemaModel.dpId || "", value)
        }
      })
    }
  }
}

