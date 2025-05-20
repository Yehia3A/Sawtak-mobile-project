import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a file to Firebase Storage
  Future<String> uploadFile(File file, String folder) async {
    try {
      // Create a unique filename using timestamp
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      String filePath = '$folder/$fileName';

      // Create a reference to the file location
      Reference storageRef = _storage.ref().child(filePath);

      // Detect content type
      String ext = path.extension(file.path).toLowerCase();
      String contentType = 'application/octet-stream';
      if (ext == '.jpg' || ext == '.jpeg') contentType = 'image/jpeg';
      if (ext == '.png') contentType = 'image/png';
      if (ext == '.webp') contentType = 'image/webp';
      if (ext == '.pdf') contentType = 'application/pdf';
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: <String, String>{
          'Content-Disposition': 'inline',
          'Cache-Control': 'public, max-age=31536000',
          'Access-Control-Allow-Origin': '*',
        },
      );

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(file, metadata);

      // Wait for the upload to complete
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload bytes to Firebase Storage
  Future<String> uploadBytes(
    Uint8List bytes,
    String fileName,
    String folder,
  ) async {
    try {
      String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      String filePath = '$folder/$uniqueFileName';
      Reference storageRef = _storage.ref().child(filePath);
      // Detect content type
      String ext = path.extension(fileName).toLowerCase();
      String contentType = 'application/octet-stream';
      if (ext == '.jpg' || ext == '.jpeg') contentType = 'image/jpeg';
      if (ext == '.png') contentType = 'image/png';
      if (ext == '.webp') contentType = 'image/webp';
      if (ext == '.pdf') contentType = 'application/pdf';
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: <String, String>{
          'Content-Disposition': 'inline',
          'Cache-Control': 'public, max-age=31536000',
          'Access-Control-Allow-Origin': '*',
        },
      );
      UploadTask uploadTask = storageRef.putData(bytes, metadata);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload multiple files
  Future<List<String>> uploadMultipleFiles(
    List<File> files,
    String folder,
  ) async {
    List<String> downloadUrls = [];
    for (File file in files) {
      String url = await uploadFile(file, folder);
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  // Delete a file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      Reference ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Failed to get file metadata: $e');
    }
  }
}
