import 'package:flutter/material.dart';

import '../common/ui_helpers.dart';
import '../common/widgets.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return CatalogBuilder(builder: (context, catalog) {
      final cat = catalog.category(categoryId);
      final sounds = catalog.inCategory(categoryId);
      return Scaffold(
        appBar: AppBar(title: Text(cat?.title ?? 'Sounds')),
        body: sounds.isEmpty
            ? const EmptyState(icon: Icons.music_off, title: 'Nothing here yet', message: 'No sounds in this category.')
            : ListView(children: [for (final s in sounds) SoundTile(sound: s)]),
      );
    });
  }
}
