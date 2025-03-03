import {
  FlutterPlugin,
  FlutterPluginBinding,
} from '@ohos/flutter_ohos';
import ClientWrapper from './ClientWrapper';

/** ImFlutterSdkPlugin **/
export default class ImFlutterSdkPlugin implements FlutterPlugin {
  private clientWrapper: ClientWrapper | null = null;

  getUniqueClassName(): string {
    return "ImFlutterSdkPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.clientWrapper = new ClientWrapper(binding);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.clientWrapper?.unRegisterEaseListener();
  }
}