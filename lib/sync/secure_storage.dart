import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<String?>? readValue(String key) async {
    return _storage.read(key: key);
  }

  static Future<void> writeValue(String key, String value) async {
    const options = IOSOptions(accessibility: IOSAccessibility.first_unlock);
    await _storage.write(key: key, value: value, iOptions: options);
    await readValue(key);
  }
}
