import { ChatClient, ConnectionListener, MultiDevicesListener } from "@easemob/chatsdk";
import { FlutterPluginBinding, MethodCall, MethodResult } from "@ohos/flutter_ohos";
import ChatManagerWrapper from "./ChatManagerWrapper";
import ChatRoomManagerWrapper from "./ChatRoomManagerWrapper";
import ConversationWrapper from "./ConversationWrapper";
import EmHelper from "./EmHelper";
import Wrapper from "./Wrapper";

export default class ClientWrapper extends Wrapper{
  private chatManagerWrapper: ChatManagerWrapper|null = null;
  private chatRoomManagerWrapper: ChatRoomManagerWrapper|null = null;
  private conversationWrapper: ConversationWrapper|null = null;
  private connectionListener: ConnectionListener|null = null;
  private multiDeviceListener: MultiDevicesListener|null = null;
  constructor(binding: FlutterPluginBinding) {
    super(binding,'chat_client');
  }
  bindingManagers(){
    this.chatManagerWrapper = new ChatManagerWrapper(this.binding);
    this.chatRoomManagerWrapper = new ChatRoomManagerWrapper(this.binding);
    this.conversationWrapper = new ConversationWrapper(this.binding);
  }
  getCurrentUser(call: MethodCall, channelName: string, result: MethodResult) {
    this.onSuccess(result,channelName,ChatClient.getInstance().getCurrentUser());
  }
  init(call: MethodCall, channelName: string, result: MethodResult) {
    try{
      if(!ChatClient.getInstance().isSdkInited()){
        let options = EmHelper.optionsWithParam(call);
        ChatClient.getInstance().init(this.context,options);

        this.bindingManagers();
        this.registerEaseListener();
      }
      this.onSuccess(result,channelName,null);
    }
    catch (error){
      this.onError(result,error);
    }
  }
  async login(call: MethodCall, channelName: string, result: MethodResult) {
    let isPassword: boolean = call.argument('isPassword');
    let username: string = call.argument('username');
    let pwdOrToken: string = call.argument('pwdOrToken');
    try{
      if(isPassword){
        await ChatClient.getInstance().login(username,pwdOrToken);
      }
      else{
        await ChatClient.getInstance().loginWithToken(username,pwdOrToken);
      }
      ChatClient.getInstance().getCurrentUser();
      this.onSuccess(result,channelName,null);
    }
    catch (error){
      this.onError(result,error);
    }
  }
  logout(channelName: string, result: MethodResult) {
    ChatClient.getInstance().logout().then(()=> {
      this.onSuccess(result,channelName,null);
    });
  }
  onMethodCall(call: MethodCall, result: MethodResult){
    switch (call.method) {
      case 'getCurrentUser':
        this.getCurrentUser(call,call.method,result);
        break;
      case 'init':
        this.init(call,call.method,result);
        break;
      case 'login':
        this.login(call,call.method,result);
        break;
      case 'logout':
        this.logout(call.method,result);
        break;
      case 'startCallback':
        this.onSuccess(result,call.method,null);
        break;
      default:
        result.notImplemented();
    }
  }
  registerEaseListener() {
    this.unRegisterEaseListener();

    this.connectionListener = {
      onConnected: () => {
        this.post(()=>this.channel?.invokeMethod('onConnected',{connected:true}));
      },
      onDisconnected: (errorCode) => {
        switch (errorCode){
          case 8:
            this.post(()=>this.channel?.invokeMethod('onAppActiveNumberReachLimit',null));
            break;
          case 202:
            this.post(()=>this.channel?.invokeMethod('onUserAuthenticationFailed',null));
            break;
          case 207:
            this.post(()=>this.channel?.invokeMethod('onUserDidRemoveFromServer',null));
            break;
          case 217:
            this.post(()=>this.channel?.invokeMethod('onUserKickedByOtherDevice',null));
            break;
          case 214:
            this.post(()=>this.channel?.invokeMethod('onUserDidLoginTooManyDevice',null));
            break;
          case 216:
            this.post(()=>this.channel?.invokeMethod('onUserDidChangePassword',null));
            break;
          case 305:
            this.post(()=>this.channel?.invokeMethod('onUserDidForbidByServer',null));
            break;
          default:
            this.post(()=>this.channel?.invokeMethod('onDisconnected',null));
            break;
        }
      },
      onLogout: (errorCode, info) => {
        if(errorCode == 206) {
          this.post(()=>this.channel?.invokeMethod('onUserDidLoginFromOtherDevice',null));
        }
      },
      onTokenExpired: () => {
        this.post(()=>this.channel?.invokeMethod('onTokenDidExpire',null));
      },
      onTokenWillExpire: () => {
        this.post(()=>this.channel?.invokeMethod('onTokenWillExpire',null));
      },
      onOfflineMessageSyncStart: () => {
        this.post(()=>this.channel?.invokeMethod('onOfflineMessageSyncStart',null));
      },
      onOfflineMessageSyncFinish: () => {
        this.post(()=>this.channel?.invokeMethod('onOfflineMessageSyncFinish',null));
      }
    };
    this.multiDeviceListener = {
      onContactEvent: (event, target, ext) => {
        this.post(()=>this.channel?.invokeMethod('onMultiDeviceContactEvent',{
          event,target,ext
        }));
      },
      onGroupEvent: (event, target, userIds) => {
        this.post(()=>this.channel?.invokeMethod('onMultiDeviceGroupEvent',{
          event,target,users:userIds
        }));
      },
      onMessageRemoved: (conversationId, deviceId) => {
        this.post(()=>this.channel?.invokeMethod('onMultiDeviceRemoveMessagesEvent',{
          convId:conversationId,deviceId
        }));
      },
      onConversationEvent: (event, conversationId, type) => {
        this.post(()=>this.channel?.invokeMethod('onMultiDevicesConversationEvent',{
          event,convId:conversationId,convType:type
        }));
      }
    };

    ChatClient.getInstance().addConnectionListener(this.connectionListener);
    ChatClient.getInstance().addMultiDevicesListener(this.multiDeviceListener);
  }
  unRegisterEaseListener() {
    if(this.connectionListener){
      ChatClient.getInstance().removeConnectionListener(this.connectionListener);
      this.connectionListener = null;
    }
    if(this.multiDeviceListener){
      ChatClient.getInstance().removeMultiDevicesListener(this.multiDeviceListener);
      this.multiDeviceListener = null;
    }

    this.chatManagerWrapper?.unRegisterEaseListener();
    this.chatRoomManagerWrapper?.unRegisterEaseListener();
    this.conversationWrapper?.unRegisterEaseListener();
  }
}