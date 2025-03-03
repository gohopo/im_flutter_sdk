import { Conversation } from "@easemob/chatsdk";
import { FlutterPluginBinding, MethodCall, MethodResult } from "@ohos/flutter_ohos";
import EmHelper from "./EmHelper";
import Wrapper from "./Wrapper";

export default class ConversationWrapper extends Wrapper{
  constructor(binding: FlutterPluginBinding) {
    super(binding,'chat_conversation');
  }
  onMethodCall(call: MethodCall, result: MethodResult){
    switch (call.method) {
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