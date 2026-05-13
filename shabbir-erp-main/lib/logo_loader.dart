import 'dart:convert';
import 'dart:ui' as ui;
import 'logo_data.dart';

ui.Image? _cachedLogoImage;
ui.Image? get cachedLogoImage => _cachedLogoImage;

Future<void> preloadLogoImage() async {
  try {
    final bytes = base64Decode(kLogoBase64);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _cachedLogoImage = frame.image;
  } catch (_) {}
}
