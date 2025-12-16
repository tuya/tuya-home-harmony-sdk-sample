import { Route, ZRouter } from "@hzw/zrouter";
import { window } from "@kit.ArkUI";
import { TSmartHomeBean, TSmartHomeManager } from "@thingsmart/homelib";
import { TSmartUser } from "@thingsmart/userlib";
import { HomeActionCell } from "./views/HomeActionCell";
import { HomePlainInfoCell } from "./views/HomePlainInfoCell";

@Route({ name: 'HMHomePage' })
@Component
export struct HMHomePage {
  @State currentHome: TSmartHomeBean | undefined = undefined

  aboutToAppear(): void {
    this.setupCurrentHome()
  }

  async setupCurrentHome() {
    let homeBean = TSmartHomeManager.getInstance().getCurrentHome()
    if (homeBean === undefined) {
      TSmartHomeManager.getInstance().setupValidHome()
      homeBean = TSmartHomeManager.getInstance().getCurrentHome()
    }
    if (!homeBean) {
      //可能已被移除当前家庭，则选中第一个家庭
      await TSmartHomeManager.getInstance().getHomeList()
      homeBean = TSmartHomeManager.getInstance().getCurrentHome()
    }
    this.currentHome = homeBean
  }

  build() {
    NavDestination() {
      List({ space: 16 }) {
        ListItemGroup() {
          ListItem() {
            HomePlainInfoCell({ title: TSmartUser.getUserName(), showArrow: false })
          }

          if (this.currentHome) {
            ListItem() {
              HomePlainInfoCell({ title: "当前家庭: " + this.currentHome.homeName })
            }
          }

          ListItem() {
            HomeActionCell({ title: "Logout" }).onClick(async () => {
              const resp = await TSmartUser.logout()
              if (resp.result) {
                ZRouter.getInstance().replace("LoginPage")
              }
            })
          }
        }
        .borderRadius(8)
        .clip(true)

        ListItemGroup() {
          ListItem() {
            HomePlainInfoCell({ title: "配网" })
          }
          .onClick(() => {
            ZRouter.getInstance().push("NetworkConfigurationListPage")
          })
          ListItem() {
            HomePlainInfoCell({ title: "场景" })
              .onClick(() => {
                ZRouter.getInstance().push("HMScenePage")
              })
          }
          ListItem() {
            HomePlainInfoCell({ title: "家庭" })
              .onClick(() => {
                ZRouter.getInstance().push("HMFamilyPage")
              })
          }

          HomePlainInfoCell({ title: "消息列表" })
            .onClick(() => {
              ZRouter.getInstance().push("MessageListPage")
            })
        }
        .borderRadius(8)
        .clip(true)
      }
      .width("100%")
      .height("100%")
      .padding({ left: 16, right: 16 })
    }
    .backgroundColor("#efefef")
    .hideToolBar(true)
    .hideTitleBar(true)
    .onWillShow(() => {
      this.setupCurrentHome()
    })
    .onBackPressed(() => {
      if (ZRouter.getNavStack().size() === 1) {
        window.getLastWindow(getContext()).then((data) => {
          let windowClass = data
          windowClass.minimize().then(() => {

          }).catch(() => {

          })
        })
        return true
      }
      return false
    })
  }
}