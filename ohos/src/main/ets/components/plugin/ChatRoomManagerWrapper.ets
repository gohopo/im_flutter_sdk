import { ChatClient } from "@easemob/chatsdk";
import { FlutterPluginBinding, MethodCall, MethodResult } from "@ohos/flutter_ohos";
import Wrapper from "./Wrapper";

export default class ChatRoomManagerWrapper extends Wrapper{
  constructor(binding: FlutterPluginBinding) {
    super(binding,'chat_room_manager');
  }
  joinChatRoom(call: MethodCall, channelName: string, result: MethodResult) {
    let roomId: string = call.argument('roomId');
    ChatClient.getInstance().chatroomManager()?.joinChatroom(roomId).then(room => {
      this.onSuccess(result,channelName,null);
    });
  }
  leaveChatRoom(call: MethodCall, channelName: string, result: MethodResult) {
    let roomId: string = call.argument('roomId');
    ChatClient.getInstance().chatroomManager()?.leaveChatroom(roomId).then(room => {
      this.onSuccess(result,channelName,null);
    });
  }
  onMethodCall(call: MethodCall, result: MethodResult){
    switch (call.method) {
      case 'joinChatRoom':
        this.joinChatRoom(call,call.method,result);
        break;
      case 'leaveChatRoom':
        this.leaveChatRoom(call,call.method,result);
        break;
      default:
        result.notImplemented();
    }
  }
}