import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/explore_genre.dart';
import '../bloc/explore_genre_cubit.dart';
import '../bloc/explore_section_cubit.dart';
import '../widgets/explore_book_list.dart';
import '../widgets/explore_home.dart';

/// The full list behind the genre shelf's "View all".
class ExploreGenrePage extends StatelessWidget {
  const ExploreGenrePage({super.key, required this.genre});

  final ExploreGenre genre;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExploreGenreCubit>(param1: genre)..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(genre.label(context))),
        body: BlocBuilder<ExploreGenreCubit, ExploreSectionState>(
          builder: (context, state) => ExploreBookList(
            state: state,
            onRetry: () => context.read<ExploreGenreCubit>().load(),
          ),
        ),
      ),
    );
  }
}
