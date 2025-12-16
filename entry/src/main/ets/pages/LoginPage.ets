import { Route, ZRouter } from "@hzw/zrouter";
import { window } from "@kit.ArkUI";
import { TSmartUser, TSmartUserAccountType } from "@thingsmart/userlib";

@Route({ name: 'LoginPage' })
@Component
export struct LoginPage {
  @State account: string = ""
  @State password: string = ""

  private async loginAction() {
    let isEmail: boolean = false
    if (this.account.includes("@")) {
      isEmail = true
    }
    const resp = await TSmartUser.loginAccount({
      account: this.account,
      countryCode: "86",
      password: this.password,
      accountType: isEmail ?  TSmartUserAccountType.EMAIL : TSmartUserAccountType.PHONE
    })
    if (resp.result) {
      ZRouter.getInstance().replace("HMHomePage")
    }
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        TextInput({
          placeholder: "account"
        }).onChange((value: string) => {
          this.account = value
        })
        TextInput({
          placeholder: "password"
        }).onChange((value: string) => {
          this.password = value
        })
        Button("Login")
          .onClick(() => {
            this.loginAction()
          })
        Button("Register")
          .onClick(() => {
            ZRouter.getInstance().push("RegisterPage")
          })
      }
      .width("100%")
      .height("100%")
      .padding({ left: 32, right: 32, top: 100 })
    }
    .hideToolBar(true)
    .hideTitleBar(true)
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