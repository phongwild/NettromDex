import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubit/manga_cubit.dart';
import '../../search/widgets/item_manga_widget.dart';

class ListMoreMangaWidget extends StatelessWidget {
  const ListMoreMangaWidget({
    super.key,
    required this.totals,
  });

  final ValueNotifier<int> totals;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MangaCubit, MangaState>(
      builder: (context, state) {
        if (state is MangaLoading) {
          return const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state is MangaError) {
          return Center(
            child: Text(state.message),
          );
        }
        if (state is MangaLoaded) {
          final mangas = state.mangas;
          totals.value = state.total ?? 0;
          return Expanded(child: ItemMangaWidget(mangaList: mangas));
        }
        return const SizedBox(height: 10);
      },
    );
  }
}
