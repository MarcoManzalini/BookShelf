import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/explore_section.dart';
import '../bloc/explore_section_cubit.dart';
import '../widgets/explore_book_list.dart';
import '../widgets/explore_home.dart';

/// The full list behind one Explore shelf ("View all").
class ExploreSectionPage extends StatelessWidget {
  const ExploreSectionPage({super.key, required this.section});

  final ExploreSection section;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ExploreSectionCubit>(param1: section)..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(section.title(context))),
        body: BlocBuilder<ExploreSectionCubit, ExploreSectionState>(
          builder: (context, state) => ExploreBookList(
            state: state,
            onRetry: () => context.read<ExploreSectionCubit>().load(),
          ),
        ),
      ),
    );
  }
}
