import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for the app.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAf7ojGRtkZ76hwmnBsNnbC5njgOYrf9_I',
    appId: '1:1038196524463:web:abc123def456',
    messagingSenderId: '1038196524463',
    projectId: 'yepo-10685',
    authDomain: 'yepo-10685.firebaseapp.com',
    storageBucket: 'yepo-10685.appspot.com',
    databaseURL: 'https://yepo-10685.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAf7ojGRtkZ76hwmnBsNnbC5njgOYrf9_I',
    appId: '1:1038196524463:android:0e7b2f1234567890abcdef',
    messagingSenderId: '1038196524463',
    projectId: 'yepo-10685',
    storageBucket: 'yepo-10685.appspot.com',
    databaseURL: 'https://yepo-10685.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAf7ojGRtkZ76hwmnBsNnbC5njgOYrf9_I',
    appId: '1:1038196524463:ios:abc123def456ghi789',
    messagingSenderId: '1038196524463',
    projectId: 'yepo-10685',
    storageBucket: 'yepo-10685.appspot.com',
    iosClientId: '1038196524463-abc123.apps.googleusercontent.com',
    iosBundleId: 'com.stardust.stardust',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAf7ojGRtkZ76hwmnBsNnbC5njgOYrf9_I',
    appId: '1:1038196524463:macos:abc123def456ghi789',
    messagingSenderId: '1038196524463',
    projectId: 'yepo-10685',
    storageBucket: 'yepo-10685.appspot.com',
    iosClientId: '1038196524463-abc123.apps.googleusercontent.com',
    iosBundleId: 'com.stardust.stardust',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAf7ojGRtkZ76hwmnBsNnbC5njgOYrf9_I',
    appId: '1:1038196524463:windows:abc123def456ghi789',
    messagingSenderId: '1038196524463',
    projectId: 'yepo-10685',
    storageBucket: 'yepo-10685.appspot.com',
  );
}
