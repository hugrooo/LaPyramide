import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/app_icon_solid.png');
  final image = img.decodeImage(file.readAsBytesSync());

  if (image == null) return;
  
  final pixel = image.getPixel(0, 0);
  print('Pixel at (0,0): R=${pixel.r}, G=${pixel.g}, B=${pixel.b}');
}
