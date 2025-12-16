import { Route } from '@hzw/zrouter';
import {
  LevelFirstBean,
  LevelResultBean,
  LevelSecondBean,
  LevelThirdBean,
  thingSmartActivator
} from '@thingsmart/activatorlib';
import { L } from '@thingsmart/thinglogmodule';


@Route({ name: "ActiveDataPage" })
@Component
export struct ActiveDataPage {
  private TAG = "ActiveDataPage"
  private resultList?: LevelResultBean
  private levelFirstList?: LevelFirstBean[]
  private levelSecondList?: LevelSecondBean[]
  private thirdDetailData?: LevelThirdBean
  @State displayText: string = 'empty'

  build() {
    NavDestination() {
      Column() {
        Button('获取一级品类')
          .onClick(async () => {
            this.resultList = await thingSmartActivator.getDeafultDeviceListData()
            L.d(this.TAG, `默认品类 = ${this.resultList.level1List.length}`)
            if (this.resultList) {
              this.levelFirstList = this.resultList.level1List
              this.displayText = JSON.stringify(this.levelFirstList)
            }
          })
          .margin({
            bottom: 20
          })

        Button('获取二级品类').onClick(async () => {
          if (this.levelFirstList) {
            this.levelSecondList =
              await thingSmartActivator.getDeviceLevelSecondData(this.levelFirstList[0].level1Code,
                this.levelFirstList[0].type)
            L.d(this.TAG, `二级品类 = ${this.levelSecondList.length}`)
            this.displayText = JSON.stringify(this.levelSecondList)

          }
        })
          .margin({
            bottom: 20
          })

        Button('获取三级品类详情').onClick(async () => {
          if (this.levelSecondList) {
            this.thirdDetailData =
              await thingSmartActivator.getDeviceLevelThirdDetailData(0,
                this.levelSecondList[0].level3Items[0].category)
            L.d(this.TAG, `三级品类详情 = ${this.thirdDetailData}`)
            this.displayText = JSON.stringify(this.thirdDetailData)
          }
        })
          .margin({
            bottom: 10
          })
      }

      Divider()
        .margin({
          bottom: 20
        })


      Scroll() {
        Text(this.displayText)
          .fontColor(Color.Gray)
          .fontSize(14)
      }.scrollBar(BarState.Off)
    }
  }
}