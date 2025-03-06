import { ChatClient, ChatError, ChatMessageListener, ConversationListener } from "@easemob/chatsdk";
import { FlutterPluginBinding, JSONMethodCodec, MethodCall, MethodChannel, MethodResult } from "@ohos/flutter_ohos";
import EmHelper from "./EmHelper";
import Wrapper from "./Wrapper";
import { HashMap } from "@kit.ArkTS";

export default class ChatManagerWrapper extends Wrapper{
  private messageChannel: MethodChannel;
  private messageListener: ChatMessageListener|null = null;
  private conversationListener: ConversationListener|null = null;
  constructor(binding: FlutterPluginBinding) {
    super(binding,'chat_manager');
    this.messageChannel = new MethodChannel(binding.getBinaryMessenger(), 'com.chat.im/chat_message', JSONMethodCodec.INSTANCE);
    this.registerEaseListener();
  }
  getConversation(call: MethodCall, channelName: string, result: MethodResult) {
    let convId: string = call.argument('convId');
    let createIfNeed: boolean = call.argument('createIfNeed')??true;
    let type: number = call.argument('type');
    try{
      let conversation = ChatClient.getInstance().chatManager()?.getConversation(convId,type,createIfNeed);
      this.onSuccess(result,channelName,EmHelper.conversationToJson(conversation));
    }
    catch (error){
      this.onError(result,error);
    }
  }
  onMethodCall(call: MethodCall, result: MethodResult){
    switch (call.method) {
      case 'getConversation':
        this.getConversation(call,call.method,result);
        break;
      case 'recallMessage':
        this.recallMessage(call,call.method,result);
        break;
      case 'sendMessage':
        this.sendMessage(call,call.method,result);
        break;
      default:
        result.notImplemented();
    }
  }
  recallMessage(call: MethodCall, channelName: string, result: MethodResult) {
    let message = EmHelper.getMessageWithParam(call);
    let ext: string = call.argument('ext');
    if(message!=null){
      ChatClient.getInstance().chatManager()?.recallMessage(message,ext);
      this.onSuccess(result,channelName,null);
    }
    else{
      this.onError(result,new ChatError(500,'The message was not found'));
    }
  }
  registerEaseListener(){
    this.unRegisterEaseListener();

    this.messageListener = {
      onMessageReceived: (messages)=>{
        let msgList: HashMap<string,ESObject>[] = messages.map((x):HashMap<string,ESObject> => EmHelper.messageToJson(x));
        this.post(()=>this.channel.invokeMethod('onMessagesReceived',msgList));
      },
      onCmdMessageReceived: (messages)=>{
        let msgList: HashMap<string,ESObject>[] = messages.map((x):HashMap<string,ESObject> => EmHelper.messageToJson(x));
        this.post(()=>this.channel.invokeMethod('onCmdMessagesReceived',msgList));
      },
      onMessageRead: (messages)=>{
        let msgList: HashMap<string,ESObject>[] = messages.map((x):HashMap<string,ESObject> => {
          let message: HashMap<string,ESObject> = EmHelper.messageToJson(x);
          this.post(()=>this.channel.invokeMethod('onMessageReadAck',message));
          return message;
        });
        this.post(()=>this.channel.invokeMethod('onMessagesRead',msgList));
      },
      onMessageRecalled: (recallInfo)=>{
        let infoList: HashMap<string,ESObject>[] = recallInfo.map((x):HashMap<string,ESObject> => EmHelper.recallMessageToJson(x));
        this.post(()=>this.channel.invokeMethod('onMessagesRecalledInfo',infoList));
      },
      onMessageDelivered: (messages)=>{
        let msgList: HashMap<string,ESObject>[] = messages.map((x):HashMap<string,ESObject> => {
          let message: HashMap<string,ESObject> = EmHelper.messageToJson(x);
          this.post(()=>this.channel.invokeMethod('onMessageDeliveryAck',message));
          return message;
        });
        this.post(()=>this.channel.invokeMethod('onMessagesDelivered',msgList));
      },
      onGroupMessageRead: (groupReadAcks)=>{
        let list: HashMap<string,ESObject>[] = groupReadAcks.map((x):HashMap<string,ESObject> => EmHelper.groupReadAckToJson(x));
        this.post(()=>this.channel.invokeMethod('onGroupMessageRead',list));
      },
      onReadAckForGroupMessageUpdated: ()=>{
        this.post(()=>this.channel.invokeMethod('onReadAckForGroupMessageUpdated',null));
      },
      onReactionChanged: (messageReactionChange)=>{
        let list: HashMap<string,ESObject>[] = messageReactionChange.map((x):HashMap<string,ESObject> => EmHelper.messageReactionChangeToJson(x));
        this.post(()=>this.channel.invokeMethod('onMessageReactionDidChange',list));
      },
      onMessageContentChanged: (modifiedMessage, operatorId, operationTime)=>{
        this.post(()=>this.channel.invokeMethod('onMessageContentChanged',{
          message:EmHelper.messageToJson(modifiedMessage),operator:operatorId,operationTime
        }));
      },
      onMessagePinChanged: (messageId, conversationId, pinOperation, pinInfo)=>{
        this.post(()=>this.channel.invokeMethod('onMessagePinChanged',{
          messageId,conversationId,pinOperation,pinInfo:{pinTime:pinInfo.pinTime(),operatorId:pinInfo.operatorId()}
        }));
      }
    };
    this.conversationListener = {
      onConversationUpdate: ()=>{
        this.post(()=>this.channel.invokeMethod('onConversationUpdate',{}));
      },
      onConversationRead: (from, to)=>{
        this.post(()=>this.channel.invokeMethod('onConversationHasRead',{from,to}));
      }
    };

    ChatClient.getInstance().chatManager()?.addMessageListener(this.messageListener);
    ChatClient.getInstance().chatManager()?.addConversationListener(this.conversationListener);
  }
  sendMessage(call: MethodCall, channelName: string, result: MethodResult) {
    try{
      let msg = EmHelper.messageFromParam(call);
      let localId = msg.getMsgId();
      msg.setMessageStatusCallback({
        onSuccess: () => {
          this.post(()=>this.messageChannel.invokeMethod('onMessageSuccess',{
            message:EmHelper.messageToJson(msg),localId
          }));
        },
        onProgress: (progress)=>{
          this.post(()=>this.messageChannel.invokeMethod('onMessageProgressUpdate',{
            progress,localId
          }));
        },
        onError: (code, error)=>{
          this.post(()=>this.messageChannel.invokeMethod('onMessageError',{
            message:EmHelper.messageToJson(msg),localId,error:{
              code,description:error
            }
          }));
        }
      });
      ChatClient.getInstance().chatManager()?.sendMessage(msg);
      this.onSuccess(result,channelName,EmHelper.messageToJson(msg));
    }
    catch (error){
      this.onError(result, error);
    }
  }
  unRegisterEaseListener(){
    if(this.messageListener){
      ChatClient.getInstance().chatManager()?.removeMessageListener(this.messageListener);
      this.messageListener = null;
    }
    if(this.conversationListener){
      ChatClient.getInstance().chatManager()?.removeConversationListener(this.conversationListener);
      this.conversationListener = null;
    }
  }
}