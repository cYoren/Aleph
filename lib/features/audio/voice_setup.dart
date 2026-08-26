/// Getting a missing speech voice installed, asking as little of the reader as
/// the platform allows.
///
/// No mobile platform lets an app install a system speech voice on the user's
/// behalf, and neither Hebrew nor Greek can be bundled with the app: the voices
/// belong to the operating system. What an app *can* do is remove the search,
/// which is where the feature is really lost — someone who wanted to hear a
/// psalm read aloud will not go hunting through Accessibility settings for
/// "Install voice data".
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('aleph/voice_setup');

/// Whether this platform has a voice installer worth offering.
///
/// iOS ships its speech voices with the system and downloads better ones by
/// itself, so there is no screen to send anyone to and no offer to make.
bool get canInstallVoices => !kIsWeb && Platform.isAndroid;

/// Opens the system's voice download screen.
///
/// Returns false when the device has no such screen, so the caller can say so
/// plainly rather than leaving a button that does nothing.
Future<bool> openVoiceDownload() async {
  if (!canInstallVoices) return false;
  try {
    return await _channel.invokeMethod<bool>('openVoiceDownload') ?? false;
  } on PlatformException catch (e) {
    if (kDebugMode) {
      debugPrint('openVoiceDownload failed: $e');
    }
    return false;
  } on MissingPluginException {
    // An older build of the host app without the channel.
    return false;
  }
}
