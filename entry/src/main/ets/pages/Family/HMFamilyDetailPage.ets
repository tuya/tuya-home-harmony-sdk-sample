import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartHome, TSmartHomeBean,
  TSmartHomeMemberBean,
  TSmartHomeRoleType, TSmartMember } from "@thingsmart/homelib";
import { HomeActionCell } from "../views/HomeActionCell";
import { HomePlainInfoCell } from "../views/HomePlainInfoCell";
import { TSmartUser } from "@thingsmart/userlib";
import { TSmartDeviceModel, TSmartDevice } from "@thingsmart/device";
import { TSmartBLEManager } from "@thingsmart/channel";
import { abilityAccessCtrl, common, Permissions } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { promptAction } from '@kit.ArkUI';

@Route({ name: "HMFamilyDetailPage" })
@Component
export struct HMFamilyDetailPage {
  homeId: number = 0
  @State homeBean: TSmartHomeBean | undefined = undefined
  @State deviceList: TSmartDeviceModel[] = []
  @State isRefreshing: boolean = false // 下拉刷新状态
  memberList: TSmartHomeMemberBean[] = []
  mine?: TSmartHomeMemberBean

  async aboutToAppear() {
    const param = ZRouter.getInstance().getParam() as Record<string, Object>
    this.homeId = param["homeId"] as number
    const res = await TSmartHome.getInstance(this.homeId).getHomeInfo();
    if (res.result) {
      this.homeBean = res.result
    }

    this.loadMembers()
    await this.loadDeviceList()
    // 获取设备列表后，请求权限并开始蓝牙搜索，搜索时会自动连接设备列表中的支持蓝牙控制是设备
    this.requestPermissions()
  }

  private async loadMembers() {
    const res = await TSmartMember.getInstance().getMemberList(this.homeId)
    if (res.result) {
      this.memberList = res.result
      this.mine = this.memberList.find(obj => obj.uid === TSmartUser.getUid())
    }
  }

  private async loadDeviceList(forceSync: boolean = false) {
    const res = await TSmartHome.getInstance(this.homeId).getHomeDetailAsync()
    if (res) {
      // 创建新数组以确保响应式更新
      let newDeviceList = res.getDeviceListSync()
      
      // 如果需要强制同步，为每个设备同步最新状态
      if (forceSync && newDeviceList.length > 0) {
        const syncedDeviceList: TSmartDeviceModel[] = []
        for (let i = 0; i < newDeviceList.length; i++) {
          const device = newDeviceList[i]
          try {
            const deviceInstance = TSmartDevice.create(device.devId)
            if (deviceInstance) {
              const syncedDevice = await deviceInstance.syncDeviceInfo()
              if (syncedDevice) {
                syncedDeviceList.push(syncedDevice)
              } else {
                syncedDeviceList.push(device)
              }
            } else {
              syncedDeviceList.push(device)
            }
          } catch (error) {
            // 如果同步失败，使用原始设备对象
            syncedDeviceList.push(device)
          }
        }
        newDeviceList = syncedDeviceList
      }
      
      // 强制更新设备列表，触发UI刷新
      this.deviceList = []
      this.deviceList = newDeviceList
    }
  }

  // 请求蓝牙权限
  private requestPermissions(): void {
    // 一次性请求所有需要的权限
    const allPermissions: Array<Permissions> = [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION',
      'ohos.permission.ACCESS_BLUETOOTH'
    ];

    this.reqPermissionsFromUser(allPermissions);
  }

  reqPermissionsFromUser(permissions: Array<Permissions>): void {
    let context = getContext(this) as common.UIAbilityContext;
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

    atManager.requestPermissionsFromUser(context, permissions).then((data) => {
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;
      let allGranted = true;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] !== 0) {
          allGranted = false;
          break;
        }
      }
      // 所有权限都授权后，开始蓝牙搜索
      if (allGranted) {
        this.startBluetoothScan()
      }
    }).catch((err: BusinessError) => {
      console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
    })
  }

  // 开始蓝牙搜索
  private startBluetoothScan() {
    try {
      TSmartBLEManager.getInstance().startScan(120000)
      console.info("开始蓝牙搜索")
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      console.error("启动蓝牙搜索失败: " + errorMessage)
    }
  }

  build() {
    NavDestination() {
      Refresh({ refreshing: $$this.isRefreshing, offset: 64, friction: 62 }) {
        List({ space: 16 }) {
          if (this.homeBean) {
            ListItem() {
              HomePlainInfoCell({ title: this.homeBean.homeName, showArrow: false })
                .clip(true)
                .borderRadius(8)
            }

            ListItemGroup() {
              ForEach(this.deviceList, (device: TSmartDeviceModel)=> {
                ListItem() {
                  this.buildDeviceCell(device)
                }
                .onClick(() => {
                  if (device.isOnline()) {
                    ZRouter.getInstance().setParam({ "deviceId": device.devId }).push("HMDeviceControlPage")
                  } else {
                    promptAction.showToast({
                      message: "设备不在线",
                      duration: 2000
                    })
                  }
                })
              }, (device: TSmartDeviceModel) => device.devId)
            }
            .clip(true)
            .borderRadius(8)

            ListItem() {
              HomeActionCell({ title: "删除家庭" }).onClick(async () => {
                if (this.mine?.role === TSmartHomeRoleType.HOME_ROLE_TYPE_ADMIN) {
                // 删除家庭
                  await TSmartHome.getInstance(this.homeId).deleteHome()
                  ZRouter.getInstance().pop()
                } else {
                  // 离开家庭
                  if (this.mine?.memberId) {
                    await TSmartHome.getInstance(this.homeId).leaveHome(this.mine.memberId)
                    ZRouter.getInstance().pop()
                  }
                }
              }).clip(true)
                .borderRadius(8)
            }

            // 添加底部空白项，确保列表可以滚动到底部
            ListItem() {
              Column()
                .width("100%")
                .height(100)
            }
            .width("100%")
          }
        }
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .onRefreshing(() => {
        this.onRefresh()
      })
    }
    .title(this.homeBean?.homeName || "家庭详情")
    .backgroundColor("#efefef")
  }

  // 下拉刷新处理
  private async onRefresh() {
    this.isRefreshing = true
    try {
      // 清除缓存，确保获取最新数据
      TSmartHome.getInstance(this.homeId).clearAllCache()
      // 刷新设备列表，强制同步每个设备的状态
      await this.loadDeviceList(true)
      // 同时刷新家庭成员列表
      await this.loadMembers()
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      console.error("刷新失败: " + errorMessage)
      promptAction.showToast({
        message: "刷新失败",
        duration: 2000
      })
    } finally {
      this.isRefreshing = false
    }
  }

  @Builder
  buildDeviceCell(device: TSmartDeviceModel) {
    Column() {
      Row() {
        Row() {
          // 在线状态指示器
          Circle({ width: 8, height: 8 })
            .fill(device.isOnline() ? "#4CAF50" : "#9E9E9E")
            .margin({ right: 8 })
          Text(device.name)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        Image($r("app.media.arrow"))
          .objectFit(ImageFit.Contain)
          .width(25)
          .height(25)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width("100%")
      .height(56)
      .padding({ left: 12, right: 12 })

      Divider()
        .width("100%")
        .height(px2vp(1))
    }
    .width("100%")
    .backgroundColor(Color.White)
  }
}