import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/home_mascot.png');
  final image = img.decodeImage(file.readAsBytesSync());

  if (image == null) return;
  
  final y = image.height ~/ 2;
  int startX = 0;
  for (int x = 0; x < image.width; x++) {
    final p = image.getPixel(x, y);
    // If it's dark (not white-ish)
    if (p.r < 100 && p.g < 100 && p.b < 100) {
      startX = x;
      break;
    }
  }
  
  int endX = image.width - 1;
  for (int x = image.width - 1; x >= 0; x--) {
    final p = image.getPixel(x, y);
    if (p.r < 100 && p.g < 100 && p.b < 100) {
      endX = x;
      break;
    }
  }

  print('Dark area on X-axis starts at $startX and ends at $endX. Width: ${endX - startX}');
}
