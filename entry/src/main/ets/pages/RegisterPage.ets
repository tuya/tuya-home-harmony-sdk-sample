import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartUser, TSmartUserAccountType, TSmartUserAuthCodeType } from "@thingsmart/userlib";

@Route({ name: 'RegisterPage' })
@Component
export struct RegisterPage {
  @State account: string = ""
  @State password: string = ""
  @State authCode: string = ""
  @State hasSend: boolean = false
  @State hasVerify: boolean = false

  private async registerAction() {
    let isEmail: boolean = false
    if (this.account.includes("@")) {
      isEmail = true
    }
    const res = await TSmartUser.registerAccount({
      account: this.account,
      countryCode: "86",
      authCode: this.authCode,
      password: this.password,
      accountType: isEmail ? TSmartUserAccountType.EMAIL : TSmartUserAccountType.PHONE
    })
    if (res.result) {
      ZRouter.getInstance().replace("HMHomePage")
    }
  }

  private sendAction() {
    TSmartUser.sendAuthCode({
      account: this.account,
      countryCode: "86",
      codeType: TSmartUserAuthCodeType.REGISTER
    })
    this.hasSend = true
  }

  private async verifyAction() {
    const resp = await TSmartUser.verifyAuthCode({
      account: this.account,
      countryCode: "86",
      codeType: TSmartUserAuthCodeType.REGISTER,
      authCode: this.authCode
    })
    if (resp.result === true) {
      this.hasVerify = true
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
          placeholder: "Verificatioin code"
        }).onChange((value: string) => {
          this.authCode = value
        })
        TextInput({
          placeholder: "password"
        }).onChange((value: string) => {
          this.password = value
        }).visibility(this.hasVerify ? Visibility.Visible : Visibility.Hidden)

        Button(this.hasSend ? "Verify Code" : "Send Code")
          .onClick(() => {
            if (this.hasSend) {
              this.verifyAction()
            } else {
              this.sendAction()
            }
          }).visibility(this.hasVerify ? Visibility.Hidden : Visibility.Visible)

        Button("Register")
          .onClick(() => {
            this.registerAction()
          }).visibility(this.hasVerify ? Visibility.Visible : Visibility.Hidden)
      }
      .width("100%")
      .height("100%")
      .padding({ left: 32, right: 32, top: 100 })
    }
    .hideToolBar(true)
    .hideTitleBar(true)
  }
}