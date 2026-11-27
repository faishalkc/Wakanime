import 'package:flutter/material.dart';

class AnimeSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const AnimeSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Search',
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
