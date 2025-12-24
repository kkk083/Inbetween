import 'dart:io';
import 'package:image/image.dart' as img;

class ImageHelper {
  static Future<File> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return file;
      
      // Redimensionne si > 1200px
      if (image.width > 1200 || image.height > 1200) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1200 : null,
          height: image.height > image.width ? 1200 : null,
        );
      }
      
      // Compresse JPEG qualité 70
      final compressedBytes = img.encodeJpg(image, quality: 70);
      
      final tempPath = '${file.path}_compressed.jpg';
      final compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      return file; // Retourne l'original si erreur
    }
  }
  
  static Future<List<File>> compressImages(List<File> files) async {
    return Future.wait(files.map((file) => compressImage(file)));
  }
}