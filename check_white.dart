import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/app_icon_solid.png');
  final image = img.decodeImage(file.readAsBytesSync());

  if (image == null) return;
  
  bool hasWhite = false;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      if (p.r > 200 && p.g > 200 && p.b > 200) {
        print('Found white pixel at ($x, $y)');
        hasWhite = true;
        break;
      }
    }
    if (hasWhite) break;
  }
  
  if (!hasWhite) {
    print('No white pixels found in the image.');
  }
}
