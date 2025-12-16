import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartHomeManager, TSmartHome } from "@thingsmart/homelib";
import { TSmartDeviceModel } from "@thingsmart/device";
import { TSmartActivator, ITSmartActivatorListener, TSmartActivatorBuilder, ITSmartActivator, TSmartActivatorStep } from "@thingsmart/activator";
import { promptAction } from "@kit.ArkUI";

@Route({ name: 'SubDeviceModePage' })
@Component
export struct SubDeviceModePage {
  @State isSearching: boolean = false
  @State isConfiguring: boolean = false
  @State gatewayDeviceList: TSmartDeviceModel[] = [] // 网关设备列表
  @State selectedGatewayId: string | null = null // 选中的网关设备ID
  @State isLoadingGateways: boolean = false // 是否正在加载网关列表
  @State activeDevices: TSmartDeviceModel[] = [] // 配网成功的子设备列表

  // 统一的左右边距
  private readonly horizontalMargin: number = 16

  private homeId: number = 0
  private activator: ITSmartActivator | null = null
  private activatorBuilder: TSmartActivatorBuilder | null = null
  
  // 初始化配网监听器
  private initActivatorListener(): ITSmartActivatorListener {
    return {
      onActiveStepAndError: (step: TSmartActivatorStep, error?: Error, device?: TSmartDeviceModel) => {
        console.error("Activation error:", error, 'step:' + step, device);
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
        // 检查设备是否已存在（去重）
        for (let device of this.activeDevices) {
          if (device.devId === deviceModel.devId) {
            return
          }
        }
        // 添加新设备到列表
        const newList = this.activeDevices.slice()
        newList.push(deviceModel)
        this.activeDevices = newList
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
        console.error("配网失败: " + JSON.stringify(error), deviceModel?.devId);
        try {
          promptAction.showToast({
            message: "配网失败: " + error.message,
            duration: 2000
          })
        } catch (e) {
          console.error("显示 toast 失败: " + e)
        }
      }
    }
  }

  async aboutToAppear(): Promise<void> {
    // 获取当前家庭的 homeId
    this.homeId = TSmartHomeManager.getInstance().getCurrentHomeId() ?? 0
    // 加载网关设备列表
    await this.loadGatewayDevices()
  }

  aboutToDisappear() {
    // 页面销毁时停止搜索
    if (this.isSearching) {
      this.stopSearch()
    }
  }

  // 加载网关设备列表
  private async loadGatewayDevices(): Promise<void> {
    if (this.homeId === 0) {
      console.error("加载网关设备失败: 没有当前家庭")
      return
    }

    this.isLoadingGateways = true
    try {
      const res = await TSmartHome.getInstance(this.homeId).getHomeDetailAsync()
      if (res) {
        const allDevices = res.getDeviceListSync()
        // 筛选网关设备
        this.gatewayDeviceList = allDevices.filter((device: TSmartDeviceModel) => {
          // 判断是否为网关设备
          // return (device.protocolAttribute ?? 0) > 0
          return device.isGateway()
        })
        console.info("加载网关设备列表成功，共 " + this.gatewayDeviceList.length + " 个网关设备")
      }
    } catch (error) {
      console.error("加载网关设备列表失败: " + JSON.stringify(error))
    } finally {
      this.isLoadingGateways = false
    }
  }

  // 开始搜索子设备
  private startSearch(): void {
    if (this.isSearching) {
      return
    }

    if (!this.selectedGatewayId) {
      try {
        promptAction.showToast({
          message: "请先选择一个网关设备",
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      return
    }

    // 查找选中的网关设备
    const selectedGateway = this.gatewayDeviceList.find(device => device.devId === this.selectedGatewayId)
    if (!selectedGateway) {
      try {
        promptAction.showToast({
          message: "选中的网关设备不存在",
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      return
    }

    // 获取网关设备的devId
    const gatewayDevId = selectedGateway.devId
    if (!gatewayDevId) {
      try {
        promptAction.showToast({
          message: "网关设备ID无效",
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      return
    }

    try {
      // 创建子设备配网构建器
      const listener = this.initActivatorListener()
      const builder = TSmartActivator.buildSubDeviceActivatorBuilder(gatewayDevId, 120000, listener)
      
      // 创建配网器
      this.activator = TSmartActivator.createActivator(builder)
      this.activatorBuilder = builder

      // 开始搜索
      this.activator?.startActive()
      this.isSearching = true
      // 清空之前的配网成功列表
      this.activeDevices = []
      console.info("开始搜索子设备，网关ID: " + gatewayDevId)
    } catch (error) {
      console.error("开始搜索失败: " + JSON.stringify(error))
      const errorMessage = error instanceof Error ? error.message : "未知错误"
      try {
        promptAction.showToast({
          message: "开始搜索失败: " + errorMessage,
          duration: 2000
        })
      } catch (e) {
        console.error("显示 toast 失败: " + e)
      }
      this.isSearching = false
    }
  }

  // 停止搜索子设备
  private stopSearch(): void {
    if (!this.isSearching) {
      return
    }
    try {
      if (this.activator) {
        this.activator.stopActive()
        this.activator = null
      }
      this.activatorBuilder = null
      this.isSearching = false
      console.info("停止搜索子设备")
    } catch (error) {
      console.error("停止搜索失败: " + JSON.stringify(error))
      this.isSearching = false
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 描述文字区域
        Column() {
          Text("请先选择一个网关设备，然后搜索并配网子设备。")
            .fontSize(14)
            .fontColor("#333333")
            .lineHeight(20)
        }
        .width("100%")
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // 网关设备选择区域
        if (this.isLoadingGateways) {
          // 加载中提示
          Column() {
            Text("正在加载网关设备列表...")
              .fontSize(14)
              .fontColor("#999999")
              .margin({ top: 40 })
          }
          .width("100%")
          .layoutWeight(1)
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Center)
        } else if (this.gatewayDeviceList.length > 0) {
          // 网关设备列表
          Column() {
            Text("请选择一个网关设备")
              .fontSize(14)
              .fontColor("#666666")
              .margin({ top: 16, bottom: 8 })
              .width("100%")
              .textAlign(TextAlign.Start)
            
            List() {
              ForEach(this.gatewayDeviceList, (device: TSmartDeviceModel) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(device.name ?? "未知设备")
                        .fontSize(16)
                        .fontColor("#000000")
                        .fontWeight(FontWeight.Medium)
                      Blank()
                      // 选中标志
                      if (this.selectedGatewayId === device.devId) {
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
                  .backgroundColor(this.selectedGatewayId === device.devId ? "#E6F3FF" : Color.White)
                }
                .enabled(!this.isSearching) // 搜索时禁用选择
                .onClick(() => {
                  // 搜索过程中不能切换网关
                  if (this.isSearching) {
                    return
                  }
                  // 单选：如果点击的是已选中的设备，则取消选择；否则选中该设备
                  if (this.selectedGatewayId === device.devId) {
                    this.selectedGatewayId = null
                  } else {
                    this.selectedGatewayId = device.devId ?? null
                    // 切换网关时清空之前的配网成功列表
                    this.activeDevices = []
                  }
                  console.info("选中网关设备: " + (device.name ?? "未知设备") + ", devId: " + device.devId)
                })
              }, (device: TSmartDeviceModel) => device.devId ?? "")
            }
            .width("100%")
            .layoutWeight(1)
            .margin({ top: 16 })
            .borderRadius(8)
            .clip(true)
          }
          .width("100%")
          .layoutWeight(1)

          // 搜索控制按钮（只有选择了网关后才显示）
          if (this.selectedGatewayId) {
            Button(this.isSearching ? "停止搜索" : "搜索子设备")
              .width("100%")
              .height(48)
              .margin({ top: 16 })
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
          }

          // 配网成功的子设备列表
          if (this.activeDevices.length > 0) {
            Column() {
              Text("配网成功的子设备")
                .fontSize(14)
                .fontColor("#666666")
                .margin({ top: 16, bottom: 8 })
                .width("100%")
                .textAlign(TextAlign.Start)
              
              List() {
                ForEach(this.activeDevices, (device: TSmartDeviceModel) => {
                  ListItem() {
                    Column() {
                      Row() {
                        Text(device.name ?? "未知设备")
                          .fontSize(16)
                          .fontColor("#000000")
                          .fontWeight(FontWeight.Medium)
                        Blank()
                        Text("✓")
                          .fontSize(20)
                          .fontColor("#00C853")
                          .fontWeight(FontWeight.Bold)
                          .margin({ right: 12 })
                      }
                      .width("100%")
                      .height(56)
                      .padding({ left: 12, right: 12 })
                      
                      Divider()
                        .width("100%")
                        .height(px2vp(1))
                    }
                    .width("100%")
                    .backgroundColor("#E8F5E9")
                  }
                }, (device: TSmartDeviceModel) => device.devId ?? "")
              }
              .width("100%")
              .height(300)
              .margin({ top: 16 })
              .borderRadius(8)
              .clip(true)
            }
            .width("100%")
            .margin({ top: 16 })
          }
        } else {
          // 空状态提示
          Column() {
            Text("暂无网关设备，请先添加网关设备")
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
    .title("网关子设备配网")
    .hideToolBar(false)
    .hideTitleBar(false)
    .onBackPressed(() => {
      return false
    })
  }
}

