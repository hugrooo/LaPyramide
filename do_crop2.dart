import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/final_logo_raw.png');
  final image = img.decodeImage(file.readAsBytesSync());

  if (image == null) return;

  // The white corners are near the edge.
  // Crop a safe 800x800 square from the exact center.
  // 1024 - 800 = 224 / 2 = 112 inset
  final cropped = img.copyCrop(image, x: 112, y: 112, width: 800, height: 800);
  
  // Resize back to 1024x1024
  final resized = img.copyResize(cropped, width: 1024, height: 1024);

  // Force no alpha channel
  final finalImage = img.Image(width: 1024, height: 1024, numChannels: 3);
  img.compositeImage(finalImage, resized);

  // Save the result over the old solid icon!
  File('assets/images/app_icon_solid.png').writeAsBytesSync(img.encodePng(finalImage));
  print('Cropped successfully!');
}
