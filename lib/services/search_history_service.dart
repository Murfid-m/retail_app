import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_history_model.dart';

class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  /// Get search history from local storage
  Future<List<SearchHistoryItem>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];
      
      return historyJson
          .map((item) => SearchHistoryItem.fromJson(jsonDecode(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a search query to history
  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];
      
      // Parse existing history
      final history = historyJson
          .map((item) => SearchHistoryItem.fromJson(jsonDecode(item)))
          .toList();
      
      // Remove duplicate if exists
      history.removeWhere(
        (item) => item.query.toLowerCase() == query.toLowerCase().trim(),
      );
      
      // Add new item at the beginning
      final newItem = SearchHistoryItem(
        query: query.trim(),
        searchedAt: DateTime.now(),
      );
      history.insert(0, newItem);
      
      // Keep only last N items
      final trimmedHistory = history.take(_maxHistoryItems).toList();
      
      // Save back to storage
      final updatedJson = trimmedHistory
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await prefs.setStringList(_searchHistoryKey, updatedJson);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Remove a specific search query from history
  Future<void> removeFromHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];
      
      // Parse and filter
      final history = historyJson
          .map((item) => SearchHistoryItem.fromJson(jsonDecode(item)))
          .where((item) => item.query.toLowerCase() != query.toLowerCase())
          .toList();
      
      // Save back
      final updatedJson = history
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await prefs.setStringList(_searchHistoryKey, updatedJson);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Search within history (for suggestions)
  Future<List<SearchHistoryItem>> searchHistory(String query) async {
    if (query.isEmpty) return await getSearchHistory();
    
    try {
      final history = await getSearchHistory();
      return history
          .where((item) => 
            item.query.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
