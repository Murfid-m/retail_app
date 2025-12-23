// Web implementation - uses HTML anchor download
// Using dart:html for broader Flutter compatibility (works in stable channel)
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';

Future<Map<String, dynamic>> saveFile(String fileName, String content) async {
  try {
    // Create a Blob with UTF-8 BOM for Excel compatibility
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    
    // Create download link
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    
    // Add to document, click, then remove
    html.document.body?.children.add(anchor);
    anchor.click();
    
    // Cleanup
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    
    return {
      'success': true,
      'path': 'Downloaded: $fileName',
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
