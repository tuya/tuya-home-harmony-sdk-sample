import { Route, ZRouter } from "@hzw/zrouter";
import { HomePlainInfoCell } from "../views/HomePlainInfoCell";

@Route({ name: 'NetworkConfigurationListPage' })
@Component
export struct NetworkConfigurationListPage {
  build() {
    NavDestination() {
      List({ space: 16 }) {
        ListItemGroup() {
          // 分组标题
          ListItem() {
            Text("设备网络配置")
              .fontSize(16)
              .fontColor("#666666")
              .width("100%")
              .padding({ left: 12, top: 8, bottom: 8 })
          }

          // EZ 模式
          ListItem() {
            HomePlainInfoCell({ title: "EZ 模式" })
          }
          .onClick(() => {
            ZRouter.getInstance().push("EZModePage")
          })

          // AP 模式
          ListItem() {
            HomePlainInfoCell({ title: "AP 模式" })
          }
          .onClick(() => {
            ZRouter.getInstance().push("APModePage")
          })

          // 低功耗蓝牙配网
          ListItem() {
            HomePlainInfoCell({ title: "低功耗蓝牙配网" })
          }
          .onClick(() => {
            ZRouter.getInstance().push("BLEModePage")
          })

          // 蓝牙 Wi-Fi 双模配网
          ListItem() {
            HomePlainInfoCell({ title: "蓝牙 Wi-Fi 双模配网" })
          }
          .onClick(() => {
            ZRouter.getInstance().push("BLEWiFiModePage")
          })

          // 有线网关配网
          ListItem() {
            HomePlainInfoCell({ title: "有线网关配网" })
          }
          .onClick(() => {
            ZRouter.getInstance().push("WiredModePage")
          })

          // Zigbee网关子设备配网
          ListItem() {
            HomePlainInfoCell({ title: "Zigbee网关子设备配网" })
          }
          .onClick(() => {
            ZRouter.getInstance().push("SubDeviceModePage")
          })

          // IPC 扫码配网
          ListItem() {
            HomePlainInfoCell({ title: "IPC 扫码配网" })
          }
          .onClick(() => {
            ZRouter.getInstance().push("QRCodeModePage")
          })

          // 扫设备二维码配网
          ListItem() {
            HomePlainInfoCell({ title: "扫设备二维码配网" })
          }
          .onClick(() => {
            ZRouter.getInstance().push("MQTTDirectlyPage")
          })
        }
        .borderRadius(8)
        .clip(true)
      }
      .width("100%")
      .height("100%")
      .padding({ left: 16, right: 16, top: 16 })
    }
    .backgroundColor("#efefef")
    .title("配网")
    .hideToolBar(false)
    .hideTitleBar(false)
    .onBackPressed(() => {
      return false
    })
  }
}



