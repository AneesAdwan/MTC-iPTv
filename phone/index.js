/**
 * @format
 */
import { AppRegistry } from 'react-native';
import App from './App';
import { name as appName } from './app.json';
import { setBackgroundHandler } from './src/lib/push';

// معالج إشعارات الخلفية يجب تسجيله خارج المكوّن قبل التسجيل
setBackgroundHandler();

AppRegistry.registerComponent(appName, () => App);
