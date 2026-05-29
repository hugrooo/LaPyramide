import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/app_icon_solid.png');
  final image = img.decodeImage(file.readAsBytesSync());

  if (image == null) return;
  
  bool cornerIsWhite(int startX, int startY) {
    for (int y = startY; y < startY + 10; y++) {
      for (int x = startX; x < startX + 10; x++) {
        final p = image.getPixel(x, y);
        if (p.r > 200 && p.g > 200 && p.b > 200) return true;
      }
    }
    return false;
  }
  
  print('Top-Left is white: ${cornerIsWhite(0, 0)}');
  print('Top-Right is white: ${cornerIsWhite(image.width - 10, 0)}');
  print('Bottom-Left is white: ${cornerIsWhite(0, image.height - 10)}');
  print('Bottom-Right is white: ${cornerIsWhite(image.width - 10, image.height - 10)}');
}
