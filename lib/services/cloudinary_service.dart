import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static const String _cloudName = 'ehjspc4t';
  static const String _uploadPreset = 'gear_preset';

  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  static Future<String> uploadImage({
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromBytesData(
        bytes,
        identifier: filename,
        resourceType: CloudinaryResourceType.Image,
        folder: 'gear-track/products',
      ),
    );
    return response.secureUrl;
  }
}
