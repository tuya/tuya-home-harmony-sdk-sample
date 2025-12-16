import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartScanMode, TSmartScannerBuilder, TSmartScannerListener, TSmartScannerResult, TSmartDeviceType, TSmartActivatorRequester, TSmartActivatorToken, TSmartActivator, ITSmartActivatorListener, TSmartActivatorBuilder, ITSmartActivator, TSmartActivatorStep } from "@thingsmart/activator";
import { TSmartHomeManager } from "@thingsmart/homelib";
import { TSmartDeviceModel } from "@thingsmart/device";
import { promptAction } from "@kit.ArkUI";

// 扩展接口，用于访问有线网关设备的gwId和productId属性
// 使用 Omit 排除可能冲突的属性，然后重新定义
interface WiredDeviceInfo extends Omit<TSmartScannerResult, 'productId' | 'gwId'> {
  gwId?: string;
  productId?: string;
}

@Route({ name: 'WiredModePage' })
@Component
export struct WiredModePage {
  @State isSearching: boolean = false
  @State isConfiguring: boolean = false // 配网状态
  @State deviceList: TSmartScannerResult[] = [] // 扫描到的设备列表
  @State selectedDeviceId: string | null = null // 选中的设备ID
  @State activatorToken: TSmartActivatorToken | null = null
  @State activeDevices: TSmartDeviceModel[] = [] // 配网成功的设备列表

  // 统一的左右边距
  private readonly horizontalMargin: number = 16

  private scanner: TSmartScannerBuilder | null = null
  private scanListener: TSmartScannerListener | null = null
  private homeId: number = 0
  private activator: ITSmartActivator | null = null
  private activatorBuilder: TSmartActivatorBuilder | null = null

  aboutToAppear(): void {
    // 获取当前家庭的 homeId
    this.homeId = TSmartHomeManager.getInstance().getCurrentHomeId() ?? 0
    this.fetchActivatorToken()
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

  // 初始化扫描监听器
  private initScanListener() {
    this.scanListener = {
      onDeviceFound: (scanResult: TSmartScannerResult) => {
        console.info("扫描到设备: " + JSON.stringify(scanResult))
        this.addDevice(scanResult)
      },
      onScanError: (error: Error) => {
        console.error("扫描错误: " + error.message)
        this.isSearching = false
      }
    } as TSmartScannerListener
  }

  // 添加设备到列表（去重）
  private addDevice(scanResult: TSmartScannerResult) {
    const uniqueId = scanResult.uniqueId
    
    // 如果没有uniqueId，跳过该设备
    if (!uniqueId) {
      return
    }
    
    // 根据TSmartDeviceType过滤，只保留WIRED类型的设备
    if (scanResult.deviceType !== TSmartDeviceType.WIRED) {
      return
    }
    
    // 检查设备是否已存在（使用uniqueId去重）
    const existingIndex = this.deviceList.findIndex(d => d.uniqueId === uniqueId)
    if (existingIndex !== -1) {
      // 如果设备已存在，更新为最新的扫描结果（创建新数组以触发响应式更新）
      const updatedList = this.deviceList.slice()
      updatedList[existingIndex] = scanResult
      this.deviceList = updatedList
    } else {
      // 添加新设备
      const newList = this.deviceList.slice()
      newList.push(scanResult)
      this.deviceList = newList
    }
  }

  private startScan() {
    if (this.isSearching) {
      return
    }
    this.isSearching = true
    // 开始搜索时清空列表和选中状态
    this.deviceList = []
    this.selectedDeviceId = null
    
    if (!this.scanner) {
      // 初始化扫描监听器
      if (!this.scanListener) {
        this.initScanListener()
      }
      if (this.scanListener) {
        this.scanner = new TSmartScannerBuilder(this.scanListener)
        this.scanner.setScanTimeout(120000).addScanMode(TSmartScanMode.SCAN_MODE_LAN)
      }
    }
    this.scanner?.startScan()
  }

  private stopScan() {
    if (!this.isSearching) {
      return
    }
    this.isSearching = false
    this.scanner?.stopScan()
  }

  private startSearch() {
    this.startScan()
    console.info("开始搜索有线网关设备")
  }

  private stopSearch() {
    this.stopScan()
    console.info("停止搜索有线网关设备")
  }

  private startConfiguration() {
    if (this.isConfiguring) {
      return
    }

    // 检查是否有选中的设备
    if (!this.selectedDeviceId) {
      try {
        promptAction.showToast({
          message: "请先选择一个设备",
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      return
    }

    // 查找选中的设备
    const selectedDevice = this.deviceList.find(device => device.uniqueId === this.selectedDeviceId)
    if (!selectedDevice) {
      try {
        promptAction.showToast({
          message: "选中的设备不存在",
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      return
    }

    // 检查homeId
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

    // 获取设备的gwId和productId
    const deviceInfo = selectedDevice as WiredDeviceInfo
    const gwId = deviceInfo.uniqueId
    const productId = deviceInfo.productId

    if (!gwId || !productId) {
      try {
        promptAction.showToast({
          message: "设备信息不完整，缺少gwId或productId",
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      return
    }

    try {
      // 创建配网监听器
      const listener: ITSmartActivatorListener = {
        onActiveStepAndError: (step: TSmartActivatorStep, error?: Error, device?: TSmartDeviceModel) => {
          console.error("Activation error:", error);
          if (error) {
            try {
              promptAction.showToast({
                message: "配网错误: " + error.message,
                duration: 2000
              })
            } catch (e) {
              console.error("显示 toast 失败: " + e)
            }
          }
        },
        onActiveSuccess: (deviceModel: TSmartDeviceModel) => {
          console.log("Activation successful:", JSON.stringify(deviceModel));
          this.activeDevices.push(deviceModel)
          // 从扫描列表中移除已配网成功的设备
          this.deviceList = this.deviceList.filter((res) => {
            return res.uniqueId !== deviceModel.uuid;
          });
          // 如果当前选中的设备已配网成功，清空选中状态
          if (this.selectedDeviceId === deviceModel.uuid) {
            this.selectedDeviceId = null
          }
          this.isConfiguring = false
          try {
            promptAction.showToast({
              message: "配网成功: " + deviceModel.name,
              duration: 2000
            })
          } catch (e) {
            console.error("显示 toast 失败: " + e)
          }
        },
        onError: (error: Error, deviceModel?: TSmartDeviceModel) => {
          console.log(JSON.stringify(error), deviceModel?.uuid);
          this.isConfiguring = false
          try {
            promptAction.showToast({
              message: "配网失败: " + error.message,
              duration: 2000
            })
          } catch (e) {
            console.error("显示 toast 失败: " + e)
          }
        }
      };

      // 创建有线网关配网构建器
      const builder = TSmartActivator.buildWiredActivatorBuilder(
        this.homeId,
        gwId,
        productId,
        120 * 1000,
        listener
      )

      // 创建配网器
      this.activator = TSmartActivator.createActivator(builder)
      this.activatorBuilder = builder

      // 开始配网
      this.activator.startActive()
      this.isConfiguring = true
      console.info("开始配网: deviceId=" + this.selectedDeviceId + ", gwId=" + gwId + ", productId=" + productId + ", homeId=" + this.homeId)
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
    if (!this.isConfiguring) {
      return
    }
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
      this.isConfiguring = false
    }
  }

  aboutToDisappear() {
    // 页面销毁时停止搜索和配网
    if (this.isSearching) {
      this.stopSearch()
    }
    if (this.isConfiguring) {
      this.stopConfiguration()
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 描述文字区域
        Column() {
          Text("让有线网关连接到路由器，并确保手机和网关在同一局域网内。")
            .fontSize(14)
            .fontColor("#333333")
            .lineHeight(20)
        }
        .width("100%")
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 搜索控制按钮
        Button(this.isSearching ? "停止搜索" : "搜索设备")
          .width("100%")
          .height(48)
          .margin({ top: 24 })
          .backgroundColor(this.isSearching ? "#FF4444" : "#007AFF")
          .fontColor(Color.White)
          .fontSize(16)
          .onClick(() => {
            if (this.isSearching) {
              this.stopSearch()
            } else {
              this.startSearch()
            }
          })

        // 设备列表
        if (this.deviceList.length > 0) {
          // 提示文本
          Text("请选择一个设备，然后开始配网")
            .fontSize(14)
            .fontColor("#666666")
            .margin({ top: 16, bottom: 8 })
            .width("100%")
            .textAlign(TextAlign.Start)
          
          List() {
            ForEach(this.deviceList, (device: TSmartScannerResult) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(device.name ?? "New Device")
                      .fontSize(16)
                      .fontColor("#000000")
                      .fontWeight(FontWeight.Medium)
                    Blank()
                    // 选中标志
                    if (this.selectedDeviceId === device.uniqueId) {
                      Text("✓")
                        .fontSize(20)
                        .fontColor("#007AFF")
                        .fontWeight(FontWeight.Bold)
                        .margin({ right: 12 })
                    }
                  }
                  .width("100%")
                  .height(56)
                  .padding({ left: 12, right: 12 })
                  
                  Divider()
                    .width("100%")
                    .height(px2vp(1))
                }
                .width("100%")
                .backgroundColor(this.selectedDeviceId === device.uniqueId ? "#E6F3FF" : Color.White)
              }
              .enabled(!this.isConfiguring) // 配网时禁用选择
              .onClick(() => {
                // 配网过程中不能选择设备
                if (this.isConfiguring) {
                  return
                }
                // 单选：如果点击的是已选中的设备，则取消选择；否则选中该设备
                if (this.selectedDeviceId === device.uniqueId) {
                  this.selectedDeviceId = null
                } else {
                  this.selectedDeviceId = device.uniqueId ?? null
                }
                console.info("选中设备: " + (device.name ?? "New Device"))
              })
            }, (device: TSmartScannerResult) => device.uniqueId)
          }
          .width("100%")
          .layoutWeight(1)
          .margin({ top: 16 })
          .borderRadius(8)
          .clip(true)
          
          // 开始配网按钮
          Button(this.isConfiguring ? "停止配网" : "开始配网")
            .width("100%")
            .height(48)
            .margin({ top: 16 })
            .backgroundColor(this.isConfiguring ? "#FF4444" : "#007AFF")
            .fontColor(Color.White)
            .fontSize(16)
            .enabled(this.isConfiguring || this.selectedDeviceId !== null) // 只有选中设备或正在配网时才可点击
            .opacity((this.isConfiguring || this.selectedDeviceId !== null) ? 1 : 0.5) // 未选中时降低透明度
            .onClick(() => {
              if (this.isConfiguring) {
                this.stopConfiguration()
              } else {
                // 只有选中设备才能开始配网
                if (this.selectedDeviceId) {
                  this.startConfiguration()
                }
              }
            })
        } else {
          // 空状态提示
          Column() {
            Text(this.isSearching ? "正在搜索设备..." : "暂无设备")
              .fontSize(14)
              .fontColor("#999999")
              .margin({ top: 40 })
          }
          .width("100%")
          .layoutWeight(1)
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width("100%")
      .height("100%")
      .padding({ left: this.horizontalMargin, right: this.horizontalMargin })
      .backgroundColor("#efefef")
      .alignItems(HorizontalAlign.Start)
    }
    .backgroundColor("#efefef")
    .title("有线网关配网")
    .hideToolBar(false)
    .hideTitleBar(false)
    .onBackPressed(() => {
      return false
    })
  }
}
