class SearchHistoryItem {
  final String query;
  final DateTime searchedAt;

  SearchHistoryItem({
    required this.query,
    required this.searchedAt,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] ?? '',
      searchedAt: DateTime.parse(
        json['searched_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'searched_at': searchedAt.toIso8601String(),
    };
  }
}
