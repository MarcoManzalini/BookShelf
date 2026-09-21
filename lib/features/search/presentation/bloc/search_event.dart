part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Restricts results to one language (`ita`, `eng`...); null = all.
final class SearchLanguageChanged extends SearchEvent {
  const SearchLanguageChanged(this.language);

  final String? language;

  @override
  List<Object?> get props => [language];
}

final class SearchNextPageRequested extends SearchEvent {
  const SearchNextPageRequested();
}
