import { Route } from '@hzw/zrouter';
import { MessageBean, MessageListBean, MessageType, TSmartMessage, TSmartMessageSetting } from '@thingsmart/messagelib';


@Route({ name: "MessageListPage" })
@Component
export struct MessageListPage {
  private TAG = "MessageListPage"
  @State displayText: string = 'empty'
  @State messageBean: MessageBean[] | undefined = []

  aboutToAppear(): void {
    this.getData()
  }

  async getData() {
    TSmartMessage.getInstance().getMessageListByMsgType({
      msgType: MessageType.MSG_REPORT,
      encryptImage: false,
      offset: 0,
      limit: 10,
    }).then(value => {
      if (value.result) {
        this.messageBean = value.result.datas
        this.displayText = JSON.stringify(this.messageBean, null, 2)
      } else {
        this.displayText = 'no data'
      }
    }).catch((reason: string) => {
      this.displayText = 'error: ' + reason
    })
  }

  build() {
    NavDestination() {
      Column() {
        List() {
          ForEach(this.messageBean, (item: MessageBean) => {
            ListItem() {
              Text('title: ' + item.msgContent)
                .fontSize(16)
                .fontColor(Color.Black)
                .padding({ top: 8, bottom: 8 })
            }
          })
        }
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