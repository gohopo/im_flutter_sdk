import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
} from '@ohos/flutter_ohos';
import ClientWrapper from './ClientWrapper';
import EmHelper from './EmHelper';

/** ImFlutterSdkPlugin **/
export default class ImFlutterSdkPlugin implements FlutterPlugin, AbilityAware {
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

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    EmHelper.uiContext = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    EmHelper.uiContext = null;
  }
}