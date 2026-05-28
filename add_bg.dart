import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/home_mascot.png');
  final image = img.decodeImage(file.readAsBytesSync());

  if (image == null) return;

  // #180D2B is R:24 G:13 B:43
  final bg = img.Image(width: image.width, height: image.height);
  img.fill(bg, color: img.ColorRgb8(24, 13, 43));

  // Composite the mascot over the background
  img.compositeImage(bg, image);

  // Save the result
  File('assets/images/app_icon_solid.png').writeAsBytesSync(img.encodePng(bg));
  print('Done!');
}
