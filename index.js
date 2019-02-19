import { NativeModules } from 'react-native';
let FegoReload = NativeModules.FegoRnUpdate;
class FegoRnUpdate {
	static hotReload(businessName: string): void {
		FegoReload.hotReload(businessName);
	}
}
export default FegoRnUpdate;