import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which quotation IDs the user has already opened, so the home
/// screen can show an unread indicator (gold dot) on new arrivals.
///
/// Stored locally as a simple string list in SharedPreferences — capped
/// at 500 IDs to prevent unbounded growth. Older IDs are evicted FIFO.
class SeenQuotationsService {
  static const String _key = 'seen_quotation_ids_v1';
  static const int _maxIds = 500;

  static Set<int> _cache = {};
  static bool _loaded = false;

  /// Load once at app startup or before first read.
  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? const [];
    _cache = stored.map(int.tryParse).whereType<int>().toSet();
    _loaded = true;
  }

  /// Synchronous check — call [load] once before using.
  static bool isSeen(int id) => _cache.contains(id);

  /// Mark a quotation as seen and persist.
  static Future<void> markSeen(int id) async {
    if (_cache.contains(id)) return;
    _cache.add(id);
    // FIFO eviction if cache is too large
    if (_cache.length > _maxIds) {
      final toRemove = _cache.length - _maxIds;
      _cache = _cache.skip(toRemove).toSet();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _cache.map((e) => e.toString()).toList());
  }

  /// Mark many at once (used to seed initial list as seen on first ever run).
  static Future<void> markManySeen(Iterable<int> ids) async {
    var changed = false;
    for (final id in ids) {
      if (_cache.add(id)) changed = true;
    }
    if (!changed) return;
    if (_cache.length > _maxIds) {
      final toRemove = _cache.length - _maxIds;
      _cache = _cache.skip(toRemove).toSet();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _cache.map((e) => e.toString()).toList());
  }
}
