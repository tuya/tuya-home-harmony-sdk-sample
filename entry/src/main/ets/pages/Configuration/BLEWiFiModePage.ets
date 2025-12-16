import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartScanMode, TSmartScannerBuilder, TSmartScannerListener, TSmartScannerResult, TSmartDeviceType, TSmartActivatorRequester, TSmartActivatorToken, TSmartActivator, ITSmartActivatorListener, TSmartActivatorBuilder, ITSmartActivator, TSmartActivatorStep } from "@thingsmart/activator";
import { TSmartHomeManager } from "@thingsmart/homelib";
import { TSmartDeviceModel } from "@thingsmart/device";
import { abilityAccessCtrl, common, Permissions } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { promptAction } from "@kit.ArkUI";
import { Device } from "@thingsmart/channel";

// 扩展TSmartScannerResult接口，添加scannedBleDevice属性
interface ExtendedScannerResult extends TSmartScannerResult {
  scannedBleDevice?: Device;
}

@Route({ name: 'BLEWiFiModePage' })
@Component
export struct BLEWiFiModePage {
  @State wifiSSID: string = ""
  @State wifiPassword: string = ""
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
    this.requestPermissions()
    this.fetchActivatorToken()
  }

  requestPermissions(): void {
    const location: Array<Permissions> = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
    const bluetooth: Array<Permissions> = ['ohos.permission.ACCESS_BLUETOOTH']; // 蓝牙

    this.reqPermissionsFromUser(location);
    this.reqPermissionsFromUser(bluetooth);
  }

  reqPermissionsFromUser(permissions: Array<Permissions>): void {
    let context = getContext(this) as common.UIAbilityContext;
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

    // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
    atManager.requestPermissionsFromUser(context, permissions).then((data) => {
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] === 0) {
          // 用户授权，可以继续访问目标操作
        } else {
          // 用户拒绝授权，先弹窗提示用户，确认后再跳转到系统设置
          this.showPermissionDialog();
          return;
        }
      }
    }).catch((err: BusinessError) => {
      console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
      this.showPermissionDialog();
    })
  }

  // 显示权限提示对话框
  private showPermissionDialog(): void {
    promptAction.showDialog({
      title: '权限申请',
      message: '该功能需要相关权限（蓝牙权限和位置权限）才能正常使用，是否前往系统设置中开启权限？',
      buttons: [
        {
          text: '取消',
          color: '#999999'
        },
        {
          text: '前往设置',
          color: '#007AFF'
        }
      ]
    }).then((result) => {
      if (result.index === 1) {
        // 用户点击了"前往设置"，跳转到系统设置页面
        this.openSystemSettings();
      }
    }).catch((err: BusinessError) => {
      console.error(`Failed to show dialog. Code: ${err.code}, message: ${err.message}`);
    })
  }

  // 跳转到系统设置页面
  private openSystemSettings(): void {
    let context = getContext(this) as common.UIAbilityContext;
    context.startAbility({
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
    }).catch((err: BusinessError) => {
      console.error(`Failed to startAbility. Code: ${err.code}, message: ${err.message}`);
    });
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
    
    // 根据TSmartDeviceType过滤，只保留WIFI_BLE类型的设备
    if (scanResult.deviceType !== TSmartDeviceType.WIFI_BLE) {
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
        this.scanner.setScanTimeout(120000).addScanMode(TSmartScanMode.SCAN_MODE_BLE)
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
    console.info("开始搜索BLE WiFi双模设备")
  }

  private stopSearch() {
    this.stopScan()
    console.info("停止搜索BLE WiFi双模设备")
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

    // 检查Wi-Fi信息
    if (!this.wifiSSID || this.wifiSSID.trim().length === 0) {
      try {
        promptAction.showToast({
          message: "请输入Wi-Fi SSID",
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

      // 创建BLE WiFi双模配网构建器
      const builder = TSmartActivator.buildBleWifiActivatorBuilder(
        this.homeId,
        this.wifiSSID,
        this.wifiPassword,
        120000,
        listener,
        this.activatorToken
      )

      // 创建配网器
      this.activator = TSmartActivator.createActivator(builder)
      this.activatorBuilder = builder

      // 添加设备并开始配网
      if (this.activator && this.activator.appendDevice) {
        // 获取scannedBleDevice，这是appendDevice需要的Device类型
        const extendedDevice = selectedDevice as ExtendedScannerResult;
        const scannedBleDevice = extendedDevice.scannedBleDevice;
        
        if (!scannedBleDevice) {
          throw new Error("设备缺少scannedBleDevice属性，无法开始配网")
        }
        
        this.activator.appendDevice(scannedBleDevice)
        this.activator.startActive()
        this.isConfiguring = true
        console.info("开始配网: deviceId=" + this.selectedDeviceId + ", SSID=" + this.wifiSSID + ", homeId=" + this.homeId)
      } else {
        throw new Error("创建配网器失败")
      }
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
            .enabled((this.isConfiguring || (this.selectedDeviceId !== null && this.wifiSSID.trim().length > 0))) // 只有选中设备且输入了SSID或正在配网时才可点击
            .opacity((this.isConfiguring || (this.selectedDeviceId !== null && this.wifiSSID.trim().length > 0)) ? 1 : 0.5) // 未满足条件时降低透明度
            .onClick(() => {
              if (this.isConfiguring) {
                this.stopConfiguration()
              } else {
                // 只有选中设备且输入了SSID才能开始配网
                if (this.selectedDeviceId && this.wifiSSID.trim().length > 0) {
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
    .title("蓝牙WiFi双模配网")
    .hideToolBar(false)
    .hideTitleBar(false)
    .onBackPressed(() => {
      return false
    })
  }
}
