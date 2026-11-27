import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  static final ImageService instance = ImageService._init();
  final ImagePicker _picker = ImagePicker();

  ImageService._init();

  /// Prompts user to pick an image from gallery
  Future<String?> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1800,
        imageQuality: 85,
      );
      return pickedFile?.path;
    } catch (_) {
      return null;
    }
  }

  /// Saves picked image to permanent local app storage with stable ID naming
  Future<String> saveImageForAnime(int animeId, String sourceFilePath) async {
    final docDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docDir.path, 'anime_images'));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = p.extension(sourceFilePath).isNotEmpty
        ? p.extension(sourceFilePath)
        : '.jpg';

    // Use anime_{id}_{timestamp} to bust any image cache when replacing
    final fileName = 'anime_${animeId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destinationPath = p.join(imagesDir.path, fileName);

    final sourceFile = File(sourceFilePath);
    await sourceFile.copy(destinationPath);

    return destinationPath;
  }

  /// Deletes image file from local storage safely
  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore cleanup error if already deleted or invalid
    }
  }

  /// Replaces existing image with new one and cleans up the old file
  Future<String> replaceImage({
    required int animeId,
    required String? oldImagePath,
    required String newSourcePath,
  }) async {
    // Delete old image file first
    await deleteImage(oldImagePath);
    // Save new image file
    return await saveImageForAnime(animeId, newSourcePath);
  }

  /// Downloads an image URL to a temporary staging directory.
  /// Returns the staged file path, or null if download fails.
  Future<String?> downloadToStaging({
    required String imageUrl,
    required Directory stagingDir,
    required String fileKey,
  }) async {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return null;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri).timeout(
        const Duration(seconds: 10),
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'Wakanime/1.0');

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200) {
        return null;
      }

      final bytesBuilder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 15))) {
        bytesBuilder.add(chunk);
      }
      final bytes = bytesBuilder.takeBytes();
      if (bytes.isEmpty) return null;

      final rawExt = p.extension(uri.path).toLowerCase();
      final ext = (rawExt == '.jpg' || rawExt == '.jpeg' || rawExt == '.png' || rawExt == '.webp')
          ? rawExt
          : '.jpg';

      final stagedFile = File(p.join(stagingDir.path, '$fileKey$ext'));
      await stagedFile.writeAsBytes(bytes, flush: true);
      return stagedFile.path;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Safe widget builder for anime images, showing an elegant placeholder on missing/invalid files
  Widget buildImage({
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    Widget content;

    final fileExists = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    if (fileExists) {
      content = Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(
          width: width,
          height: height,
        ),
      );
    } else {
      content = _buildPlaceholder(
        width: width,
        height: height,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: content,
      );
    }

    return content;
  }

  Widget _buildPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_outlined,
        color: Colors.grey.shade400,
        size: (width != null && width < 60) ? 24 : 36,
      ),
    );
  }
}
