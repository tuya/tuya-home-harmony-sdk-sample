import { AbilityStage, bundleManager } from "@kit.AbilityKit";
import { TSmartSDK } from "@thingsmart/channel";

export class AppAbilityStage extends AbilityStage{


  onCreate(): void {

    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
    let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleFlags);

    TSmartSDK.startWithAppKey("appKey",
      "appSecret",
      this.context.getApplicationContext(),
      bundleInfo.name);
  }
}