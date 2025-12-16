import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartDefaultRoomBean, TSmartHome, TSmartHomeManager,
  TSmartHomeMode,
  TSmartRoom, TSmartRoomBean } from "@thingsmart/homelib";
import { HomeActionCell } from "../views/HomeActionCell";
import { HomePlainInfoCell } from "../views/HomePlainInfoCell";

@Route({ name: 'HMCreateFamilyPage' })
@Component
export struct HMCreateFamilyPage {
  @State roomList: TSmartDefaultRoomBean[] = []
  @State familyName: string = ""

  async aboutToAppear() {
    const res = await TSmartRoom.getInstance(0).getDefaultRoomList()
    if (res.result) {
      this.roomList = res.result
    }
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        TextInput({ placeholder: "请输入家庭名称" }).onChange((value: string) => {
          this.familyName = value
        })

        List() {
          ForEach(this.roomList, (room: TSmartDefaultRoomBean) => {
            HomePlainInfoCell({ title: room.roomName, showArrow: false })
          })
        }
        .clip(true)
        .borderRadius(8)

        HomeActionCell({ title: "保存"}).onClick(async ()=>{
          await TSmartHomeManager.getInstance().addHome({
            name: this.familyName,
            homeMode: TSmartHomeMode.HOME_MODE_DEFAULT,
            rooms: this.roomList.map(obj => obj.roomName)
          })
          ZRouter.getInstance().pop()
        })
          .clip(true)
          .borderRadius(8)
      }.padding({ left: 16, right: 16 })

    }.backgroundColor("#efefef")
  }
}