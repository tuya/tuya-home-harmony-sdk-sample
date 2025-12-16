import { Route, ZRouter } from '@hzw/zrouter';
import { NormalSceneBean, SceneAction, SceneCondition, TSmartScene } from '@thingsmart/scenelib';
import { TSmartHomeManager } from '@thingsmart/homelib';
import { HomePlainInfoCell } from '../views/HomePlainInfoCell';
import { promptAction } from '@kit.ArkUI';

@Route({ name: 'HMSceneDetailPage' })
@Component
export struct HMSceneDetailPage {
  @State sceneId: string = ''
  @State sceneDetail: NormalSceneBean | undefined = undefined
  @State conditions: SceneCondition[] = []
  @State actions: SceneAction[] = []

  async aboutToAppear() {
    let params = ZRouter.getInstance().getParam() as Record<string, Object>
    if (params) {
      this.sceneId = params.sceneId as string
      this.loadSceneDetail()
    }
  }

  // 加载场景详情
  loadSceneDetail() {
    // 如果只有场景ID，尝试从当前家庭的所有场景中查找
    const currentHomeId = TSmartHomeManager.getInstance().getCurrentHomeId() ?? 0
    TSmartScene.getSceneDetailV1(currentHomeId, this.sceneId, undefined, true).then((response)=>{
        if (response && response.result) {
            this.sceneDetail = response.result
            this.conditions = this.sceneDetail.conditions ?? []
            this.actions = this.sceneDetail.actions ?? []
        }
    }).catch((error: Error)=>{
        const errorMessage = error instanceof Error ? error.message : String(error)
        console.error('加载场景详情失败:', errorMessage)
        promptAction.showToast({
            message: '加载场景详情失败',
            duration: 2000
        })
    })
  }

  // 获取场景类型文本
  getSceneTypeText(): string {
    if (!this.sceneDetail) return ''
    if (this.sceneDetail.outOfWork === 1) {
      return '无效场景'
    }
    return this.sceneDetail.ruleGenre === 1 ? '一键执行场景' : '自动化场景'
  }

  // 获取场景状态文本
  getSceneStatusText(): string {
    if (!this.sceneDetail) return ''
    if (this.sceneDetail.outOfWork === 1) {
      return '无效'
    }
    if (this.sceneDetail.ruleGenre === 2) {
      return this.sceneDetail.enabled ? '已启用' : '已禁用'
    }
    return '正常'
  }

  // 执行场景
  async executeScene() {
    if (!this.sceneDetail) return
    if (this.sceneDetail.outOfWork === 1) {
      promptAction.showToast({
        message: '场景无效，无法执行',
        duration: 2000
      })
      return
    }
    try {
      // 根据实际 API 调整执行场景的方法
      // 这里假设有 executeScene 方法，如果没有需要根据实际 API 调整
      const result = await TSmartScene.executeScene(this.sceneDetail.id)
      if (result) {
        promptAction.showToast({
          message: '场景执行成功',
          duration: 2000
        })
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      console.error('执行场景失败:', errorMessage)
      promptAction.showToast({
        message: '执行场景失败',
        duration: 2000
      })
    }
  }

  // 删除场景
  async deleteScene() {
    if (!this.sceneDetail) return
    try {
      // 根据实际 API 调整删除场景的方法
      // 这里假设有 deleteScene 方法，如果没有需要根据实际 API 调整
      const currentHomeId = TSmartHomeManager.getInstance().getCurrentHomeId() ?? 0
      const result = await TSmartScene.deleteSceneWithHomeId(currentHomeId, this.sceneDetail.id)
      if (result) {
        promptAction.showToast({
          message: '删除成功',
          duration: 2000
        })
        // 设置刷新标志，通知列表页需要刷新
        ZRouter.getInstance().pop()
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      console.error('删除场景失败:', errorMessage)
      promptAction.showToast({
        message: '删除场景失败',
        duration: 2000
      })
    }
  }

  // 切换自动化场景开关
  async toggleAutomation() {
    if (!this.sceneDetail) return
    if (this.sceneDetail.ruleGenre !== 2) return
    
    try {
      const newEnabled = !this.sceneDetail.enabled
      if (newEnabled) {
        const result = await TSmartScene.enableAutomation(this.sceneDetail.id)
        if (result) {
          this.sceneDetail.enabled = true
          promptAction.showToast({
            message: '已启用',
            duration: 2000
          })
        }
      } else {
        const result = await TSmartScene.disableAutomation(this.sceneDetail.id)
        if (result) {
          this.sceneDetail.enabled = false
          promptAction.showToast({
            message: '已禁用',
            duration: 2000
          })
        }
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      console.error('切换自动化状态失败:', errorMessage)
      promptAction.showToast({
        message: '操作失败',
        duration: 2000
      })
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          if (this.sceneDetail) {
            // 封面图片（仅一键执行场景）
            if (this.sceneDetail.ruleGenre === 1) {
              this.coverPicView()
            }

            // 场景名称
            this.nameView()

            // 条件视图（仅自动化场景）
            if (this.sceneDetail.ruleGenre === 2) {
              this.conditionView()
            }

            // 执行任务视图
            this.executeView()

            // 场景信息卡片
            this.infoCardView()

            // 操作按钮卡片
            this.actionCardView()

            // 底部空白
            Column()
              .width("100%")
              .height(100)
          }
        }
        .alignItems(HorizontalAlign.Center)
        .padding({
          left: 16,
          right: 16,
          bottom: 16
        })
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .width('100%')
      .layoutWeight(1)
    }
    .title(this.sceneDetail?.name || '场景详情')
    .backgroundColor("#efefef")
  }

  // 封面图片
  @Builder
  coverPicView() {
    if (this.sceneDetail) {
      Row() {
        // 如果有封面图标和颜色，显示它们；否则显示默认图标
        if ((this.sceneDetail as NormalSceneBean).coverIcon && (this.sceneDetail as NormalSceneBean).displayColor) {
          Image((this.sceneDetail as NormalSceneBean).coverIcon)
            .width(54)
            .aspectRatio(1)
            .borderRadius(8)
        } else {
          // 默认图标
          Text('场景')
            .fontSize(20)
            .fontColor('#ffffff')
        }
      }
      .width(54)
      .height(54)
      .justifyContent(FlexAlign.Center)
      .borderRadius(8)
      .backgroundColor((this.sceneDetail as NormalSceneBean).displayColor ? `#${(this.sceneDetail as NormalSceneBean).displayColor}` : '#007DFF')
      .margin({ top: 16, bottom: 8 })
    }
  }

  // 场景名称
  @Builder
  nameView() {
    if (this.sceneDetail) {
      Text(this.sceneDetail.name || '未命名场景')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .textAlign(this.sceneDetail.ruleGenre === 1 ? TextAlign.Center : TextAlign.Start)
        .width('100%')
        .padding({ top: 8, bottom: 8 })
    }
  }

  // 条件视图（自动化场景）
  @Builder
  conditionView() {
    if (this.sceneDetail && this.sceneDetail.ruleGenre === 2) {
      Column({ space: 8 }) {
        Row() {
          Text('满足条件')
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ top: 16, bottom: 8, left: 16, right: 16 })

        if (this.conditions.length > 0) {
          Divider()
            .width('100%')
            .height(1)
            .color('#E5E5E5')

          // 遍历条件列表
          ForEach(this.conditions, (condition: SceneCondition, index: number) => {
            Column() {
              // 主标题
              Row() {
                Text(this.getConditionDisplayText(condition))
                  .fontSize(14)
                  .fontColor(Color.Black)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding({ top: 12, left: 16, right: 16 })

              // 副标题 - 显示 JSON 内容
              Row() {
                Text(JSON.stringify(condition, null, 2))
                  .fontSize(12)
                  .fontColor('#999999')
                  .wordBreak(WordBreak.BREAK_ALL)
              }
              .width('100%')
              .padding({ top: 4, bottom: 12, left: 16, right: 16 })

              if (index < this.conditions.length - 1) {
                Divider()
                  .width('100%')
                  .height(1)
                  .color('#E5E5E5')
                  .margin({ left: 16, right: 16 })
              }
            }
            .width('100%')
          }, (condition: SceneCondition, index: number) => `condition_${index}`)
        } else {
          Divider()
            .width('100%')
            .height(1)
            .color('#E5E5E5')

          // 无条件时显示提示
          Row() {
            Text('暂无条件')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ top: 8, bottom: 16, left: 16, right: 16 })
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(8)
      .padding({ top: 0, bottom: 0 })
    }
  }

  // 获取条件显示文本
  getConditionDisplayText(condition: SceneCondition): string {
    if (!condition) return '未知条件'
    // 根据条件的实际结构返回显示文本
    if (condition.entityName) {
      return condition.entityName
    }
    // if (condition.deviceName) {
    //   return condition.deviceName
    // }
    if (condition.entityType) {
      return `条件类型: ${condition.entityType}`
    }
    return JSON.stringify(condition)
  }

  // 执行任务视图
  @Builder
  executeView() {
    if (this.sceneDetail) {
      Column({ space: 8 }) {
        Row() {
          Text(this.sceneDetail.ruleGenre === 1 ? '一键执行任务' : '执行任务')
            .fontSize(16)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ top: 16, bottom: 8, left: 16, right: 16 })

        if (this.actions.length > 0) {
          Divider()
            .width('100%')
            .height(1)
            .color('#E5E5E5')

          // 遍历任务列表
          ForEach(this.actions, (action: SceneAction, index: number) => {
            Column() {
              // 主标题
              Row() {
                Text(this.getActionDisplayText(action))
                  .fontSize(14)
                  .fontColor(Color.Black)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding({ top: 12, left: 16, right: 16 })

              // 副标题 - 显示 JSON 内容
              Row() {
                Text(JSON.stringify(action, null, 2))
                  .fontSize(12)
                  .fontColor('#999999')
                  .wordBreak(WordBreak.BREAK_ALL)
              }
              .width('100%')
              .padding({ top: 4, bottom: 12, left: 16, right: 16 })

              if (index < this.actions.length - 1) {
                Divider()
                  .width('100%')
                  .height(1)
                  .color('#E5E5E5')
                  .margin({ left: 16, right: 16 })
              }
            }
            .width('100%')
          }, (action: SceneAction, index: number) => `action_${index}`)
        } else {
          Divider()
            .width('100%')
            .height(1)
            .color('#E5E5E5')

          // 无任务时显示提示
          Row() {
            Text('暂无任务')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ top: 8, bottom: 16, left: 16, right: 16 })
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(8)
      .padding({ top: 0, bottom: 0 })
    }
  }

  // 获取任务显示文本
  getActionDisplayText(action: SceneAction): string {
    if (!action) return '未知任务'
    // 根据任务的实际结构返回显示文本
    if (action.entityName) {
      return action.entityName
    }
    // if (action.deviceName) {
    //   return action.deviceName
    // }
    if (action.actionExecutor) {
      return `任务类型: ${action.actionExecutor}`
    }
    return JSON.stringify(action)
  }

  // 信息卡片
  @Builder
  infoCardView() {
    if (this.sceneDetail) {
      Column({ space: 0 }) {
        this.buildInfoRow('场景ID', String(this.sceneDetail.id))
        
        Divider()
          .width('100%')
          .height(1)
          .color('#E5E5E5')
        
        this.buildInfoRow('场景类型', this.getSceneTypeText())
        
        Divider()
          .width('100%')
          .height(1)
          .color('#E5E5E5')
        
        this.buildInfoRow('状态', this.getSceneStatusText())
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(8)
    }
  }

  // 操作按钮卡片
  @Builder
  actionCardView() {
    if (this.sceneDetail) {
      Column({ space: 0 }) {
        // 如果是自动化场景且有效，显示开关
        if (this.sceneDetail.ruleGenre === 2 && this.sceneDetail.outOfWork !== 1) {
          Row() {
            Text('启用自动化')
              .fontSize(16)
              .fontColor(Color.Black)
              .layoutWeight(1)
            
            Toggle({ 
              type: ToggleType.Switch, 
              isOn: this.sceneDetail.enabled 
            })
              .selectedColor("#007DFF")
              .onChange((isOn: boolean) => {
                this.toggleAutomation()
              })
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
        }

        // 如果是一键执行场景且有效，显示执行按钮
        if (this.sceneDetail.ruleGenre === 1 && this.sceneDetail.outOfWork !== 1) {
          Row() {
            Text('执行场景')
              .fontSize(16)
              .fontColor("#007DFF")
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.executeScene()
          })
        }

        // 删除场景按钮
        if (this.sceneDetail.outOfWork !== 1) {
          if (this.sceneDetail.ruleGenre === 2 || this.sceneDetail.ruleGenre === 1) {
            Divider()
              .width('100%')
              .height(1)
              .color('#E5E5E5')
          }
          
          Row() {
            Text('删除场景')
              .fontSize(16)
              .fontColor(Color.Red)
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.deleteScene()
          })
        }
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(8)
    }
  }

  // 构建信息行
  @Builder
  buildInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor(Color.Black)
        .layoutWeight(1)
      
      Text(value)
        .fontSize(16)
        .fontColor('#666666')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }
}

