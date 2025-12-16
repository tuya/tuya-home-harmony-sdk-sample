import { ZRouter } from '@hzw/zrouter'
import { TSmartUser } from '@thingsmart/userlib'

@Entry
@Component
struct Index {
  build() {
    Column() {
      Navigation(ZRouter.getNavStack()) {
        Column() {
          Text("Hello Tuya")
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
        }
        .justifyContent(FlexAlign.Center)
        .width("100%")
        .height("100%")

      }
      .hideToolBar(true)
      .mode(NavigationMode.Stack)
      .onAppear(() => {
        if (TSmartUser.isLogin()) {
          TSmartUser.getUserName()
          ZRouter.getInstance().push("HMHomePage")
        } else {
          ZRouter.getInstance().push("LoginPage")
        }
      }).customNavContentTransition(ZRouter.getInstance().animateMgr().getAnimCustomNavContentTransition())
    }
    .height('100%')
    .width('100%')
  }
}