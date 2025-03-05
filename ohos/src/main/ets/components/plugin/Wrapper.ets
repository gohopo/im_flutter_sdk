import { FlutterPluginBinding,
  JSONMethodCodec,
  MethodCall, MethodCallHandler, MethodChannel, MethodResult } from "@ohos/flutter_ohos";
import { common } from "@kit.AbilityKit";
import { ChatError } from "@easemob/chatsdk";
import { HashMap } from "@kit.ArkTS";

export default class Wrapper implements MethodCallHandler{
  private static readonly CHANNEL_PREFIX = "com.chat.im/";
  protected  binding: FlutterPluginBinding;
  protected context: common.Context;
  protected channel: MethodChannel;
  constructor(binding: FlutterPluginBinding, channelName:  string) {
    this.binding = binding;
    this.context = binding.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), Wrapper.CHANNEL_PREFIX + channelName, JSONMethodCodec.INSTANCE);
    this.channel.setMethodCallHandler(this);
  }
  onError(result: MethodResult,error: ChatError|ESObject){
    if(!(error instanceof  ChatError)) error = new ChatError(ChatError.GENERAL_ERROR,error.toString());
    this.post(()=>{
      result.success({error});
    });
  }
  onMethodCall(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
  }
  onSuccess(result: MethodResult, channelName: string, object: ESObject) {
    this.post(()=>{
      let data: HashMap<string,ESObject> = new HashMap<string,ESObject>();
      if(object != null){
        data.set(channelName,object);
      }
      result.success(data);
    });
  }
  post(func: ()=>void) {
    func();
  }
  unRegisterEaseListener(){}
}