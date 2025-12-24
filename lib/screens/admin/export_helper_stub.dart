// Stub implementation - this file is used when neither web nor io is available
// This should never actually be used in practice

Future<Map<String, dynamic>> saveFile(String fileName, String content) async {
  return {
    'success': false,
    'error': 'Platform not supported',
  };
}
