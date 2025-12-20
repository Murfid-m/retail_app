import 'package:flutter/material.dart';
import '../models/search_history_model.dart';
import '../services/search_history_service.dart';

class SearchHistoryProvider extends ChangeNotifier {
  final SearchHistoryService _service = SearchHistoryService();

  List<SearchHistoryItem> _history = [];
  bool _isLoading = false;

  List<SearchHistoryItem> get history => _history;
  bool get isLoading => _isLoading;
  bool get hasHistory => _history.isNotEmpty;

  /// Load search history from storage
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _service.getSearchHistory();
    } catch (e) {
      _history = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a search query to history
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      await _service.addToHistory(query);
      // Reload to get updated list
      _history = await _service.getSearchHistory();
      notifyListeners();
    } catch (e) {
      // Ignore errors
    }
  }

  /// Remove a specific item from history
  Future<void> removeFromHistory(String query) async {
    try {
      await _service.removeFromHistory(query);
      _history.removeWhere(
        (item) => item.query.toLowerCase() == query.toLowerCase(),
      );
      notifyListeners();
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    try {
      await _service.clearHistory();
      _history = [];
      notifyListeners();
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get suggestions based on partial query
  List<SearchHistoryItem> getSuggestions(String query) {
    if (query.isEmpty) return _history;
    
    return _history
        .where((item) => 
          item.query.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
