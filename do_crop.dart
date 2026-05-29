import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/home_mascot.png');
  final image = img.decodeImage(file.readAsBytesSync());

  if (image == null) return;

  // The dark area is roughly from 92 to 931. Let's crop an 840x840 square.
  // x = 92, y = 92, w = 840, h = 840
  final cropped = img.copyCrop(image, x: 92, y: 92, width: 840, height: 840);
  
  // Resize back to 1024x1024 to make it standard
  final resized = img.copyResize(cropped, width: 1024, height: 1024);

  // Force no alpha channel
  final finalImage = img.Image(width: 1024, height: 1024, numChannels: 3);
  img.compositeImage(finalImage, resized);

  // Overwrite the app_icon_solid.png
  File('assets/images/app_icon_solid.png').writeAsBytesSync(img.encodePng(finalImage));
  print('Cropped successfully!');
}
