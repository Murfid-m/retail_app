// Native (Android/iOS/Desktop) implementation - uses dart:io and path_provider
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<Map<String, dynamic>> saveFile(String fileName, String content) async {
  try {
    // Get downloads directory based on platform
    Directory? directory;
    
    if (Platform.isAndroid) {
      // Try Downloads folder first
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    } else {
      // Windows/macOS/Linux - use documents directory
      directory = await getApplicationDocumentsDirectory();
    }
    
    if (directory == null) {
      return {
        'success': false,
        'error': 'Tidak dapat mengakses direktori penyimpanan',
      };
    }
    
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    
    return {
      'success': true,
      'path': file.path,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
