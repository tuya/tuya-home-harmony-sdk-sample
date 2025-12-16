import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartHomeBean, TSmartHomeManager } from "@thingsmart/homelib";
import { HomeActionCell } from "../views/HomeActionCell";
import { HMFamilyTitleView } from "./HMFamilyTitleView";

@Route({ name: 'HMFamilyPage' })
@Component
export struct HMFamilyPage {
  @State homeList: TSmartHomeBean[] = []
  @State currentHomeId: number = 0

  aboutToAppear() {
    this.reloadData()
    this.currentHomeId = TSmartHomeManager.getInstance().getCurrentHomeId() ?? 0
  }

  async reloadData() {
    const res = await TSmartHomeManager.getInstance().getHomeList()
    if (res.result) {
      this.homeList = res.result
    }
    this.currentHomeId = TSmartHomeManager.getInstance().getCurrentHomeId() ?? 0
    if (this.currentHomeId === 0) {
      this.currentHomeId = this.homeList[0].homeId
    }
  }

  build() {
    NavDestination() {
      List({ space: 16 }) {
        ListItemGroup() {
          ForEach(this.homeList, (homeBean: TSmartHomeBean) => {
            HMFamilyTitleView({
              title: homeBean.homeName, isSelect: this.currentHomeId === homeBean.homeId, onClickFamily: () => {
                ZRouter.getInstance().setParam({ "homeId": homeBean.homeId }).push("HMFamilyDetailPage")
              }
            })
              .onClick(() => {
                this.currentHomeId = homeBean.homeId
                TSmartHomeManager.getInstance().setCurrentHomeId(homeBean.homeId)
              })
          })
        }
        .borderRadius(8)
        .clip(true)

        ListItemGroup() {
          ListItem() {
            HomeActionCell({ title: "创建家庭" }).onClick(() => {
              ZRouter.getInstance().push("HMCreateFamilyPage")
            })
          }
        }.borderRadius(8)
        .clip(true)
      }
      .width("100%")
      .height("100%")
      .padding({ left: 16, right: 16 })
    }
    .backgroundColor("#efefef")
    .onWillShow(() => {
      this.reloadData()
    })
  }
}