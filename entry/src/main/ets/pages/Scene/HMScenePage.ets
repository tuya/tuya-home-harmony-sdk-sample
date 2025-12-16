import { Route } from '@hzw/zrouter';
import { promptAction, window } from '@kit.ArkUI';
import { ZRouter } from '@hzw/zrouter';
import { NormalSceneBean, TSmartScene } from '@thingsmart/scenelib';
import { TSmartHomeManager } from '@thingsmart/homelib';

@Route({ name: 'HMScenePage' })
@Component
export struct HMScenePage {
  @State sceneList: NormalSceneBean[] = []
  @State manualScenes: NormalSceneBean[] = [] // 一键执行场景（有效）
  @State autoScenes: NormalSceneBean[] = [] // 自动化场景（有效）
  @State invalidScenes: NormalSceneBean[] = [] // 无效场景
  @State currentHomeId: number = 0

  aboutToAppear(): void {
    this.currentHomeId = TSmartHomeManager.getInstance().getCurrentHomeId() ?? 0
    this.loadSceneList()
  }

  async loadSceneList() {
    TSmartScene.getSimpleSceneAll(this.currentHomeId).then((data)=>{
      if (data.result) {
        this.sceneList = data.result
        this.filterScenes()
      }
    }).catch((error: Error) => {
      console.error('加载场景列表失败:', error)
    })
  }

  // 分类场景为一键执行、自动化和无效场景
  filterScenes() {
    // 无效场景：outOfWork === 1
    this.invalidScenes = this.sceneList.filter((scene: NormalSceneBean) => {
      return scene.outOfWork === 1
    })
    // 一键执行场景：ruleGenre === 1 且有效（outOfWork !== 1）
    this.manualScenes = this.sceneList.filter((scene: NormalSceneBean) => {
      return scene.ruleGenre === 1 && scene.outOfWork !== 1
    })
    // 自动化场景：ruleGenre === 2 且有效（outOfWork !== 1）
    this.autoScenes = this.sceneList.filter((scene: NormalSceneBean) => {
      return scene.ruleGenre === 2 && scene.outOfWork !== 1
    })
  }

  // 处理自动化开关状态变化
  onAutoSceneSwitchChange(scene: NormalSceneBean, isOn: boolean) {
    if (isOn) {
      TSmartScene.enableAutomation(scene.id).then((response) => {
        if (response.result) {
          scene.enabled = response.result
          console.info('TScene enable success')
          promptAction.showToast({
            message: '已启用',
            duration: 2000
          })
        }
      })
    } else {
      TSmartScene.disableAutomation(scene.id).then((response)=> {
        if (response.result) {
          scene.enabled = response.result
          console.info('TScene disable success')
          promptAction.showToast({
            message: '已禁用',
            duration: 2000
          })
        }
      })
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 列表内容
        List({ space: 16 }) {
          // 一键执行 section
          if (this.manualScenes.length > 0) {
            ListItemGroup() {
              // Section 标题
              ListItem() {
                Text('一键执行场景')
                  .fontSize(18)
                  .fontColor(Color.Black)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .padding({ top: 16, bottom: 8, left: 16, right: 16 })
              }
              .backgroundColor(Color.Transparent)

              // 一键执行场景列表
              ForEach(this.manualScenes, (item: NormalSceneBean, index: number) => {
                ListItem() {
                  Column() {
                    Text(item.name)
                      .fontSize(16)
                      .fontColor(Color.Black)
                      .width('100%')
                      .height(64)
                    
                    // 分割线（最后一个不显示）
                    if (index < this.manualScenes.length - 1) {
                      Divider()
                        .width('100%')
                        .height(1)
                        .color('#E5E5E5')
                    }
                  }
                  .width('100%')
                }
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  // 跳转到场景详情页
                  ZRouter.getInstance().setParam({ "sceneId": String(item.id) }).push("HMSceneDetailPage")
                })
              }, (item: NormalSceneBean) => item.id)
            }
            .borderRadius(8)
            .clip(true)
            .backgroundColor(Color.White)
          }

          // 自动化 section
          if (this.autoScenes.length > 0) {
            ListItemGroup() {
              // Section 标题
              ListItem() {
                Text('自动化场景')
                  .fontSize(18)
                  .fontColor(Color.Black)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .padding({ top: 16, bottom: 8, left: 16, right: 16 })
              }
              .backgroundColor(Color.Transparent)

              // 自动化场景列表
              ForEach(this.autoScenes, (item: NormalSceneBean, index: number) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(item.name)
                        .fontSize(16)
                        .fontColor(Color.Black)
                        .layoutWeight(1)
                      
                      // 显示 switch 按钮
                      Toggle({ type: ToggleType.Switch, isOn: item.enabled })
                        .selectedColor("#007DFF")
                        .onChange((isOn: boolean) => {
                          this.onAutoSceneSwitchChange(item, isOn)
                        })
                    }
                    .width('100%')
                    .height(64)
                    .alignItems(VerticalAlign.Center)
                    
                    // 分割线（最后一个不显示）
                    if (index < this.autoScenes.length - 1) {
                      Divider()
                        .width('100%')
                        .height(1)
                        .color('#E5E5E5')
                    }
                  }
                  .width('100%')
                }
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  // 跳转到场景详情页（点击开关按钮不会触发此事件）
                  ZRouter.getInstance().setParam({ "sceneId": String(item.id) }).push("HMSceneDetailPage")
                })
              }, (item: NormalSceneBean) => item.id)
            }
            .borderRadius(8)
            .clip(true)
            .backgroundColor(Color.White)
          }

          // 无效场景 section
          if (this.invalidScenes.length > 0) {
            ListItemGroup() {
              // Section 标题
              ListItem() {
                Text('无效场景')
                  .fontSize(18)
                  .fontColor(Color.Black)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .padding({ top: 16, bottom: 8, left: 16, right: 16 })
              }
              .backgroundColor(Color.Transparent)

              // 无效场景列表
              ForEach(this.invalidScenes, (item: NormalSceneBean, index: number) => {
                ListItem() {
                  Column() {
                    Row() {
                      Text(item.name)
                        .fontSize(16)
                        .fontColor(Color.Black)
                        .layoutWeight(1)
                      
                      // 显示"无效"文案
                      Text('无效')
                        .fontSize(14)
                        .fontColor('#999999')
                    }
                    .width('100%')
                    .height(64)
                    .alignItems(VerticalAlign.Center)
                    
                    // 分割线（最后一个不显示）
                    if (index < this.invalidScenes.length - 1) {
                      Divider()
                        .width('100%')
                        .height(1)
                        .color('#E5E5E5')
                    }
                  }
                  .width('100%')
                }
                .padding({ left: 16, right: 16 })
              }, (item: NormalSceneBean) => item.id)
            }
            .borderRadius(8)
            .clip(true)
            .backgroundColor(Color.White)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
    }
    .backgroundColor("#efefef")
    .title('场景列表')
    .hideToolBar(true)
    .menus([
      {
        value: '添加',
        action: () => {
          // 添加按钮点击事件
          console.info('添加按钮被点击')
        }
      }
    ])
    .onWillShow(() => {
        this.loadSceneList()
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
