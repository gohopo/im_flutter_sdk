import { FlutterPluginBinding, MethodCall, MethodResult } from "@ohos/flutter_ohos";
import EmHelper from "./EmHelper";
import Wrapper from "./Wrapper";

export default class ConversationWrapper extends Wrapper{
  constructor(binding: FlutterPluginBinding) {
    super(binding,'chat_conversation');
  }
  getLatestMessage(call: MethodCall, channelName: string, result: MethodResult) {
    let conversation = EmHelper.getConversationWithParam(call);
    let msg = conversation?.getLatestMessage();
    this.onSuccess(result,channelName,msg?EmHelper.messageToJson(msg):null);
  }
  getUnreadMsgCount(call: MethodCall, channelName: string, result: MethodResult) {
    let conversation = EmHelper.getConversationWithParam(call);
    this.onSuccess(result,channelName,conversation?.getUnreadMsgCount());
  }
  onMethodCall(call: MethodCall, result: MethodResult){
    switch (call.method) {
      case 'getLatestMessage':
        this.getLatestMessage(call,call.method,result);
        break;
      case 'getUnreadMsgCount':
        this.getUnreadMsgCount(call,call.method,result);
        break;
      case 'markAllMessagesAsRead':
        this.markAllMessagesAsRead(call,call.method,result);
        break;
      default:
        result.notImplemented();
    }
  }
  markAllMessagesAsRead(call: MethodCall, channelName: string, result: MethodResult) {
    let conversation = EmHelper.getConversationWithParam(call);
    conversation?.markAllMessagesAsRead();
    this.onSuccess(result,channelName,null);
  }
}