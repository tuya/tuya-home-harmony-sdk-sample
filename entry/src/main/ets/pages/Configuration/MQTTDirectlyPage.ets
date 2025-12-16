import { Route, ZRouter } from "@hzw/zrouter";
import { TSmartActivatorRequester, TSmartActivator, ITSmartActivatorListener, TSmartActivatorBuilder,
  ITSmartActivator, TSmartActivatorStep } from "@thingsmart/activator";
import { TSmartHomeManager } from "@thingsmart/homelib";
import { TSmartDeviceModel } from "@thingsmart/device";
import { promptAction } from "@kit.ArkUI";
import { BusinessError } from "@kit.BasicServicesKit";
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from "@kit.PerformanceAnalysisKit";

@Route({ name: 'MQTTDirectlyPage' })
@Component
export struct MQTTDirectlyPage {
  @State scanBtnEnable: boolean = true
  @State uuid: string = ""
  @State isActive: boolean = false
  @State deviceName: string = ""
  
  private homeId: number = 0
  private activatorBuilder: TSmartActivatorBuilder | null = null
  private activator: ITSmartActivator | null = null

  // 配网监听器
  private activatorListener: ITSmartActivatorListener = {
    onActiveSuccess: (deviceModel: TSmartDeviceModel) => {
      console.log('onActiveSuccess')
      this.isActive = false
      this.uuid = ""
      this.deviceName = deviceModel.name
    },
    onError: (error: Error) => {
      this.isActive = false
      console.error("配网失败: " + error.message)
    },
  }

  aboutToAppear() {
    // 获取当前家庭的 homeId
    this.homeId = TSmartHomeManager.getInstance().getCurrentHomeId() ?? 0
  }

  aboutToDisappear() {
    // 页面销毁时停止配网
    this.stopActive()
  }


  // 解析二维码内容
  private parseQRCode(code: string) {
    TSmartActivatorRequester.parseQRCode(code).then(res => {
      console.log('ConfigMQTTDirectlyPage ', JSON.stringify(code));
      // {"actionData":{"uuid":"dc18219067cf0516"},"actionName":"device_net_conn_multi_ver"}
      if (res['actionName'] === 'device_net_conn_multi_ver') {
        this.uuid = (res['actionData'] as Record<string, string>)['uuid'];
        this.scanBtnEnable = true;
      }
    }).catch((error: Error) => {
      this.scanBtnEnable = true;
      console.log('ConfigMQTTDirectlyPage ', 'parseQRCode error');
    })
  }

  private startActive() {
    if (this.isActive) {
      return;
    }
    this.isActive = true;

    let homeId = 0
    if (this.homeId) {
      homeId = this.homeId
    }

    const builder = TSmartActivator.buildMQTTDirectlyActivatorBuilder(homeId, this.uuid, 120000, this.activatorListener);
    this.activator = TSmartActivator.createActivator(builder);
    this.activatorBuilder = builder;
    this.activator.startActive();
  }

  private stopActive() {
    if (!this.isActive) {
      return;
    }
    this.isActive = false;
    this.activator?.stopActive();
    this.activator = null;
    this.activatorBuilder = null;
  }

  build() {
    NavDestination() {
      Column() {

        Row() {
          Button("点击扫码")
            .backgroundColor('#0D9FFB')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Normal)
            .align(Alignment.Center)
            .type(ButtonType.Capsule)
            .width('90%')
            .height(40)
            .margin({ top: 50, bottom: 5 })
            .enabled(this.scanBtnEnable)
            .onClick(() => {
              this.scanBtnEnable = false;
              // 定义扫码参数options
              let options: scanBarcode.ScanOptions = {
                scanTypes: [scanCore.ScanType.ALL],
                enableMultiMode: true,
                enableAlbum: true
              };
              try {
                // 可调用getContext接口获取当前页面关联的UIAbilityContext
                scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
                  // 解析码值结果跳转应用服务页
                  hilog.info(0x0001, '[Scan CPSample]', `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
                  this.parseQRCode(result['originalValue'] as string);
                }).catch((error: BusinessError) => {
                  this.scanBtnEnable = true;
                  hilog.error(0x0001, '[Scan CPSample]',
                    `Failed to get ScanResult by promise with options. Code:${error.code}, message: ${error.message}`);
                });
              } catch (error) {
                this.scanBtnEnable = true;
                const err = error as BusinessError;
                hilog.error(0x0001, '[Scan CPSample]',
                  `Failed to start the scanning service. Code:${err.code}, message: ${err.message}`);
              }
            })
        }

        if (this.uuid) {
          Text(this.uuid)
            .fontSize(20)
            .fontWeight(FontWeight.Normal)
            .margin({ top: 40 })

          Row() {
            Button(this.isActive ? '停止配网' : '开始配网')
              .backgroundColor('#0D9FFB')
              .fontSize(20)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Normal)
              .align(Alignment.Center)
              .type(ButtonType.Capsule)
              .width('90%')
              .height(40)
              .margin({ top: 50, bottom: 5 })
              .onClick(() => {
                if (this.isActive) {
                  this.stopActive();
                } else {
                  this.startActive();
                }
              })
          }
        }

        if (this.deviceName) {
          Text(this.deviceName)
            .fontSize(20)
            .fontWeight(FontWeight.Normal)
            .margin({ top: 40 })
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .backgroundColor("#efefef")
    .title("扫设备二维码配网")
    .hideToolBar(false)
    .hideTitleBar(false)
    .onBackPressed(() => {
      return false
    })
  }
}

