import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartActivatorRequester, TSmartActivatorToken, TSmartActivator, ITSmartActivatorListener, TSmartActivatorBuilder,
  ITSmartActivator } from "@thingsmart/activator";
import { TSmartHomeManager } from "@thingsmart/homelib";
import { TSmartDeviceModel } from "@thingsmart/device";
import { promptAction } from "@kit.ArkUI";

@Route({ name: 'EZModePage' })
@Component
export struct EZModePage {
  @State wifiSSID: string = ""
  @State wifiPassword: string = ""
  @State isConfiguring: boolean = false
  @State activatorToken: TSmartActivatorToken | null = null
  
  private activatorBuilder: TSmartActivatorBuilder | null = null
  private activator: ITSmartActivator | null = null
  private homeId: number = 0

  // 统一的左右边距
  private readonly horizontalMargin: number = 16

  // 配网监听器
  private activatorListener: ITSmartActivatorListener = {
    onActiveSuccess: (deviceModel: TSmartDeviceModel) => {
      console.info("配网成功: device=" + JSON.stringify(deviceModel))
      try {
        promptAction.showToast({
          message: "配网成功:"+deviceModel.name,
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      this.isConfiguring = false
      // 配网成功后可以返回上一级页面或刷新设备列表
    },
    onError: (error: Error) => {
      console.error("配网失败: code=" + error.name + ", message=" + error.message)
      try {
        promptAction.showToast({
          message: "配网失败: " + error.message,
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      this.isConfiguring = false
    }
  }

  async aboutToAppear() {
    // 获取当前家庭的 homeId
    this.homeId = TSmartHomeManager.getInstance().getCurrentHomeId() ?? 0
    await this.fetchActivatorToken()
  }

  aboutToDisappear() {
    // 页面销毁时停止配网
    this.stopConfiguration()
  }

  private async fetchActivatorToken() {
    try {
      if (this.homeId === 0) {
        console.error("获取 token 失败: 没有当前家庭")
        try {
          promptAction.showToast({
            message: "获取 token 失败: 没有当前家庭",
            duration: 2000
          })
        } catch (e) {
          console.error("显示 toast 失败: " + e)
        }
        setTimeout(() => {
          ZRouter.getInstance().pop()
        }, 2000)
        return
      }
      const token = await TSmartActivatorRequester.getActivatorToken(this.homeId)
      if (token) {
        this.activatorToken = token
        console.info("获取 token 成功")
      } else {
        console.error("获取 token 失败: token 为空")
        try {
          promptAction.showToast({
            message: "获取 token 失败",
            duration: 2000
          })
        } catch (e) {
          console.error("显示 toast 失败: " + e)
        }
        setTimeout(() => {
          ZRouter.getInstance().pop()
        }, 2000)
      }
    } catch (error) {
      console.error("获取 token 失败: " + JSON.stringify(error))
      const errorMessage = error instanceof Error ? error.message : "未知错误"
      try {
        promptAction.showToast({
          message: "获取 token 失败: " + errorMessage,
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      setTimeout(() => {
        ZRouter.getInstance().pop()
      }, 2000)
    }
  }

  private startConfiguration() {
    try {
      if (this.homeId === 0) {
        try {
          promptAction.showToast({
            message: "没有当前家庭",
            duration: 2000
          })
        } catch (e) {
          console.error("显示 toast 失败: " + e)
        }
        return
      }

      // 构建 EZ 配网构建器
      this.activatorBuilder = TSmartActivator.buildEzActivatorBuilder(
        this.wifiSSID,
        this.wifiPassword,
        120 * 1000, // 120秒超时
        this.activatorListener,
        this.homeId
      )

      // 创建配网器
      this.activator = TSmartActivator.createActivator(this.activatorBuilder)

      // 开始配网
      this.activator.startActive()
      this.isConfiguring = true
      console.info("开始配网: SSID=" + this.wifiSSID + ", homeId=" + this.homeId)
    } catch (error) {
      console.error("开始配网失败: " + JSON.stringify(error))
      const errorMessage = error instanceof Error ? error.message : "未知错误"
      try {
        promptAction.showToast({
          message: "开始配网失败: " + errorMessage,
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      this.isConfiguring = false
    }
  }

  private stopConfiguration() {
    try {
      if (this.activator) {
        this.activator.stopActive()
        this.activator = null
      }
      this.activatorBuilder = null
      this.isConfiguring = false
      console.info("停止配网")
    } catch (error) {
      console.error("停止配网失败: " + JSON.stringify(error))
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 内容区域 - 白色卡片
        Column() {
          // Wi-Fi SSID 输入框
          TextInput({
            placeholder: "Wi-Fi SSID",
            text: this.wifiSSID
          })
          .onChange((value: string) => {
            this.wifiSSID = value
          })
          .width("100%")
          .height(56)
          .padding({ left: 12, right: 12 })

          // 分隔线
          Divider()
            .width("100%")
            .height(px2vp(1))
            .color("#E5E5E5")

          // Wi-Fi Password 输入框
          TextInput({
            placeholder: "Wi-Fi Password",
            text: this.wifiPassword
          })
          .onChange((value: string) => {
            this.wifiPassword = value
          })
          .type(InputType.Password)
          .width("100%")
          .height(56)
          .padding({ left: 12, right: 12 })
        }
        .width("100%")
        .backgroundColor("#efefef")
        .borderRadius(8)
        .margin({ top: 16 })

        // 配网控制按钮
        Button(this.isConfiguring ? "停止配网" : "开始配网")
          .width("100%")
          .height(48)
          .margin({ top: 24 })
          .backgroundColor(this.isConfiguring ? "#FF4444" : "#007AFF")
          .fontColor(Color.White)
          .fontSize(16)
          .enabled((this.wifiSSID.trim().length > 0) || this.isConfiguring)
          .opacity(((this.wifiSSID.trim().length > 0) || this.isConfiguring) ? 1 : 0.5)
          .onClick(() => {
            if (this.wifiSSID.trim().length === 0 && !this.isConfiguring) {
              return
            }
            if (this.isConfiguring) {
              this.stopConfiguration()
            } else {
              this.startConfiguration()
            }
          })
      }
      .width("100%")
      .height("100%")
      .padding({ left: this.horizontalMargin, right: this.horizontalMargin })
      .backgroundColor("#efefef")
      .alignItems(HorizontalAlign.Start)
    }
    .backgroundColor("#efefef")
    .title("EZ Mode")
    .hideToolBar(false)
    .hideTitleBar(false)
    .onBackPressed(() => {
      return false
    })
  }
}


