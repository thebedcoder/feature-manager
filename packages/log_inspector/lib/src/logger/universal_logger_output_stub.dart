// Stub implementation for non-web platforms
// This file provides dummy implementations of web APIs for non-web platforms

// Stub window object
final window = _Window();

class _Window {
  final localStorage = _LocalStorage();
}

class _LocalStorage {
  final Map<String, String> _storage = {};
  
  String? operator [](String key) => _storage[key];
  void operator []=(String key, String value) => _storage[key] = value;
  void remove(String key) => _storage.remove(key);
}

// Stub classes for web APIs (these won't be used on non-web platforms)
class Blob {
  Blob(List<String> parts, String type, String endings);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href});
  void setAttribute(String name, String value) {}
  void click() {}
}
