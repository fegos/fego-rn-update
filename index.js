import { NativeModules } from 'react-native';
let FegoReload = NativeModules.FegoRnUpdate;
class FegoRnUpdate {
	static hotReload(): void {
		FegoReload.hotReload();
	}
}
export default FegoRnUpdate;