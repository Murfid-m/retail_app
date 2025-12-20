import 'package:flutter/material.dart';
import '../../main.dart';
import '../models/search_history_model.dart';

/// Search bar with history suggestions dropdown
class SearchBarWithHistory extends StatefulWidget {
  final TextEditingController controller;
  final List<SearchHistoryItem> history;
  final Function(String) onSearch;
  final Function(String) onHistoryTap;
  final Function(String) onHistoryDelete;
  final VoidCallback? onClearHistory;
  final String hintText;

  const SearchBarWithHistory({
    super.key,
    required this.controller,
    required this.history,
    required this.onSearch,
    required this.onHistoryTap,
    required this.onHistoryDelete,
    this.onClearHistory,
    this.hintText = 'Cari produk...',
  });

  @override
  State<SearchBarWithHistory> createState() => _SearchBarWithHistoryState();
}

class _SearchBarWithHistoryState extends State<SearchBarWithHistory> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && widget.history.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChange() {
    if (_focusNode.hasFocus) {
      if (widget.controller.text.isEmpty && widget.history.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showSuggestions = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_showSuggestions) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riwayat Pencarian',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        if (widget.onClearHistory != null)
                          TextButton(
                            onPressed: () {
                              widget.onClearHistory!();
                              _removeOverlay();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text(
                              'Hapus Semua',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // History list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: widget.history.length,
                      itemBuilder: (context, index) {
                        final item = widget.history[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.history, size: 20),
                          title: Text(
                            item.query,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              widget.onHistoryDelete(item.query);
                              if (widget.history.length <= 1) {
                                _removeOverlay();
                              }
                            },
                          ),
                          onTap: () {
                            widget.controller.text = item.query;
                            widget.onHistoryTap(item.query);
                            _removeOverlay();
                            _focusNode.unfocus();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: TextStyle(
          color: isDark ? kAccentColor : kPrimaryColor,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: isDark
                ? kAccentColor.withOpacity(0.6)
                : kPrimaryColor.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? kAccentColor : kPrimaryColor,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        onChanged: (value) {
          widget.onSearch(value);
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            widget.onSearch(value);
            _removeOverlay();
          }
        },
      ),
    );
  }
}

/// Simple search history chips
class SearchHistoryChips extends StatelessWidget {
  final List<SearchHistoryItem> history;
  final Function(String) onTap;
  final Function(String) onDelete;

  const SearchHistoryChips({
    super.key,
    required this.history,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: history.map((item) {
        return InputChip(
          label: Text(item.query),
          onPressed: () => onTap(item.query),
          onDeleted: () => onDelete(item.query),
          deleteIconColor: Colors.grey,
          avatar: const Icon(Icons.history, size: 16),
        );
      }).toList(),
    );
  }
}
