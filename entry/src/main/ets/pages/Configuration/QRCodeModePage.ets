import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartActivatorRequester, TSmartActivatorToken, TSmartActivator, ITSmartActivatorListener, TSmartActivatorBuilder,
  ITSmartActivator } from "@thingsmart/activator";
import { TSmartHomeManager } from "@thingsmart/homelib";
import { TSmartDeviceModel } from "@thingsmart/device";
import { promptAction } from "@kit.ArkUI";
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { image } from "@kit.ImageKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

@Route({ name: 'QRCodeModePage' })
@Component
export struct QRCodeModePage {
  @State wifiSSID: string = ""
  @State wifiPassword: string = ""
  @State isConfiguring: boolean = false
  @State activatorToken: TSmartActivatorToken | null = null
  @State pixelMap: image.PixelMap | undefined = undefined
  @State qrCodeString: string = ""
  
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
        // token 获取成功后，如果有 WiFi 信息，生成二维码
        if (this.wifiSSID.trim().length > 0) {
          this.generateQRCode()
        }
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

      // 构建 QRCode 配网构建器
      this.activatorBuilder = TSmartActivator.buildQRCodeActivatorBuilder(
        this.homeId,
        this.wifiSSID,
        this.wifiPassword,
        120 * 1000, // 120秒超时
        this.activatorListener,
        this.activatorToken
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

  // 生成二维码
  private generateQRCode() {
    // 如果缺少必要信息，不生成二维码
    if (!this.activatorToken || this.wifiSSID.trim().length === 0) {
      this.pixelMap = undefined
      return
    }

    // 获取二维码字符串
    try {
      this.qrCodeString = TSmartActivator.getQRCodeString(this.wifiSSID, this.wifiPassword, this.activatorToken)
    } catch (e) {
      console.error("获取二维码字符串失败: " + e)
      this.qrCodeString = ""
      return
    }

    if (!this.qrCodeString || this.qrCodeString.length === 0) {
      this.pixelMap = undefined
      return
    }

    let content: string = this.qrCodeString
    let options: generateBarcode.CreateOptions = {
      scanType: scanCore.ScanType.QR_CODE,
      height: 400,
      width: 400,
      margin: 1,
      level: generateBarcode.ErrorCorrectionLevel.LEVEL_M,
      backgroundColor: 0xFFFFFF,
      pixelMapColor: 0x000000
    }

    try {
      // 码图生成接口，成功返回PixelMap格式图片
      generateBarcode.createBarcode(content, options).then((pixelMap: image.PixelMap) => {
        this.pixelMap = pixelMap
      }).catch((error: BusinessError) => {
        hilog.error(0x0001, '[generateBarcode]',
          `Failed to get PixelMap by promise with options. Code: ${error.code}, message: ${error.message}`)
        this.pixelMap = undefined
      })
    } catch (error) {
      const err = error as BusinessError
      hilog.error(0x0001, '[generateBarcode]',
        `Failed to createBarcode by promise with options. Code: ${err.code}, message: ${err.message}`)
      this.pixelMap = undefined
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
            // WiFi 信息变化时，如果有 token，重新生成二维码
            if (this.activatorToken && this.wifiSSID.trim().length > 0) {
              this.generateQRCode()
            } else {
              this.pixelMap = undefined
            }
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
            // WiFi 信息变化时，如果有 token，重新生成二维码
            if (this.activatorToken && this.wifiSSID.trim().length > 0) {
              this.generateQRCode()
            }
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

        // 二维码显示区域
        if (this.pixelMap) {
          Row() {
            Image(this.pixelMap)
              .width(300)
              .height(300)
              .objectFit(ImageFit.Contain)
          }
          .width("100%")
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 })

          // 说明文字
          Text("请将IPC设备重置到待配网状态，并使用设备的摄像头扫码，扫码时听到提示音后再点击开始配网按钮。")
            .fontSize(14)
            .fontColor("#666666")
            .lineHeight(20)
            .width("100%")
            .textAlign(TextAlign.Center)
            .margin({ top: 16, left: 16, right: 16 })
            .padding({ left: 8, right: 8 })
        }

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
    .title("IPC 扫码配网")
    .hideToolBar(false)
    .hideTitleBar(false)
    .onBackPressed(() => {
      return false
    })
  }
}

