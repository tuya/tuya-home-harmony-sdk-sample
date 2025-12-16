import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartActivatorRequester, TSmartActivatorToken, TSmartActivator, ITSmartActivatorListener, TSmartActivatorBuilder,
  ITSmartActivator } from "@thingsmart/activator";
import { TSmartHomeManager } from "@thingsmart/homelib";
import { TSmartDeviceModel } from "@thingsmart/device";
import { promptAction } from "@kit.ArkUI";
import { common, Want } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";

@Route({ name: 'APModePage' })
@Component
export struct APModePage {
  @State wifiSSID: string = ""
  @State wifiPassword: string = ""
  @State activatorToken: TSmartActivatorToken | null = null
  @State deviceHotspotName: string = "" // 设备热点名称
  @State isConfiguring: boolean = false
  
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

  // 跳转到系统WiFi设置页面
  private openWifiSettings() {
    let context = getContext(this) as common.UIAbilityContext;
    let want: Want = {
      bundleName: 'com.huawei.hmos.settings',
      uri: 'wifi_entry'
    };
    context.startAbility(want)
      .then(() => {
        // ...
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to startAbility. Code: ${err.code}, message: ${err.message}`);
      });
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

      if (!this.activatorToken) {
        try {
          promptAction.showToast({
            message: "配网token未获取，请稍后重试",
            duration: 2000
          })
        } catch (e) {
          console.error("显示 toast 失败: " + e)
        }
        return
      }

      // 构建 AP 配网构建器
      this.activatorBuilder = TSmartActivator.buildApActivatorBuilder(
        this.wifiSSID,
        this.wifiPassword,
        120 * 1000, // 120秒超时
        this.activatorToken,
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
        // 输入框区域 - 白色卡片
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
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ top: 16 })

        // 说明文字区域 - 白色卡片
        Column() {
          Text("AP模式，也称为热点模式。手机连接智能设备的热点，双方通过约定的端口建立Socket连接来交换数据。")
            .fontSize(14)
            .fontColor("#333333")
            .lineHeight(20)
            .margin({ bottom: 12 })

          Text("让设备进入配对模式，然后将手机的Wi-Fi切换到设备的热点。输入您希望设备连接的Wi-Fi的SSID和密码，先去连接设备热点，成功连接设备热点后，点击开始配网。")
            .fontSize(14)
            .fontColor("#333333")
            .lineHeight(20)
        }
        .width("100%")
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .margin({ top: 16 })
        .alignItems(HorizontalAlign.Start)

        // 去连接设备热点按钮
        Button("去连接设备热点")
          .width("100%")
          .height(48)
          .margin({ top: 24 })
          .backgroundColor("#007AFF")
          .fontColor(Color.White)
          .fontSize(16)
          .enabled(this.wifiSSID.trim().length > 0)
          .opacity(this.wifiSSID.trim().length > 0 ? 1 : 0.5)
          .onClick(() => {
            if (this.wifiSSID.trim().length > 0) {
              this.openWifiSettings()
            }
          })

        // 开始配网按钮
        Button(this.isConfiguring ? "停止配网" : "开始配网")
          .width("100%")
          .height(48)
          .margin({ top: 16 })
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
    .title("AP Mode")
    .hideToolBar(false)
    .hideTitleBar(false)
    .onBackPressed(() => {
      return false
    })
  }
}

