import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png');
  final image = img.decodeImage(file.readAsBytesSync());

  if (image == null) return;
  
  final pixel = image.getPixel(0, 0);
  print('iOS Icon Pixel at (0,0): R=${pixel.r}, G=${pixel.g}, B=${pixel.b}');
}
