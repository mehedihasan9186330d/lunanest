import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/category_style.dart';
import '../common/ui_helpers.dart';
import '../common/widgets.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: CatalogBuilder(builder: (context, catalog) {
        final q = _query.trim().toLowerCase();
        final results = q.isEmpty
            ? const []
            : catalog.sounds.where((s) {
                final cat = catalog.category(s.categoryId)?.title.toLowerCase() ?? '';
                return s.title.toLowerCase().contains(q) || cat.contains(q);
              }).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              controller: _controller,
              hintText: 'Search sounds',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: q.isNotEmpty
                ? (results.isEmpty
                    ? const EmptyState(icon: Icons.search_off, title: 'No matches', message: 'Try “rain”, “ocean” or “noise”.')
                    : ListView(children: [for (final s in results) SoundTile(sound: s)]))
                : ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                    for (final c in catalog.categories)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          tileColor: Theme.of(context).colorScheme.surface,
                          leading: Icon(CategoryStyle.of(c.id).icon),
                          title: Text(c.title),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/explore/category/${c.id}'),
                        ),
                      ),
                  ]),
          ),
        ]);
      }),
    );
  }
}
