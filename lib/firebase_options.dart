import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCwynpZJdfWL2rjFODeFDjsEm70SKLDN4o',
    authDomain: 'game-cd32e.firebaseapp.com',
    projectId: 'game-cd32e',
    storageBucket: 'game-cd32e.firebasestorage.app',
    messagingSenderId: '6623134957',
    appId: '1:6623134957:web:4177360b23b410794d78e4',
    measurementId: 'G-JZGDC31KV5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwynpZJdfWL2rjFODeFDjsEm70SKLDN4o',
    authDomain: 'game-cd32e.firebaseapp.com',
    projectId: 'game-cd32e',
    storageBucket: 'game-cd32e.firebasestorage.app',
    messagingSenderId: '6623134957',
    appId: '1:6623134957:android:4177360b23b410794d78e4',
    measurementId: 'G-JZGDC31KV5',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwynpZJdfWL2rjFODeFDjsEm70SKLDN4o',
    authDomain: 'game-cd32e.firebaseapp.com',
    projectId: 'game-cd32e',
    storageBucket: 'game-cd32e.firebasestorage.app',
    messagingSenderId: '6623134957',
    appId: '1:6623134957:ios:4177360b23b410794d78e4',
    measurementId: 'G-JZGDC31KV5',
    iosClientId: '6623134957-placeholder.apps.googleusercontent.com',
    iosBundleId: 'com.example.codeQuizGame',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCwynpZJdfWL2rjFODeFDjsEm70SKLDN4o',
    authDomain: 'game-cd32e.firebaseapp.com',
    projectId: 'game-cd32e',
    storageBucket: 'game-cd32e.firebasestorage.app',
    messagingSenderId: '6623134957',
    appId: '1:6623134957:ios:4177360b23b410794d78e4',
    measurementId: 'G-JZGDC31KV5',
    iosClientId: '6623134957-placeholder.apps.googleusercontent.com',
    iosBundleId: 'com.example.codeQuizGame',
  );
}
