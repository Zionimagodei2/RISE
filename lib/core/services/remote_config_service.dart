class RemoteConfigService {
  final Map<String, Object> _values = {};
  Future<void> initialize() async => _values.addAll({'paywallEnabled': true, 'guardianEnabled': true});
  T get<T>(String key, T fallback) => _values[key] is T ? _values[key] as T : fallback;
}
