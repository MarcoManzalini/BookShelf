part of 'search_bloc.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.status = RequestStatus.initial,
    this.books = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
    this.language,
  });

  final String query;

  /// initial = no query yet; success with empty [books] = no results.
  final RequestStatus status;
  final List<Book> books;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  /// Language filter applied to the search, or null for all.
  final String? language;

  SearchState copyWith({
    String? query,
    RequestStatus? status,
    List<Book>? books,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? Function()? failure,
    Failure? Function()? loadMoreFailure,
    String? Function()? language,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      books: books ?? this.books,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure != null ? failure() : this.failure,
      loadMoreFailure:
          loadMoreFailure != null ? loadMoreFailure() : this.loadMoreFailure,
      language: language != null ? language() : this.language,
    );
  }

  @override
  List<Object?> get props => [
        query,
        status,
        books,
        page,
        hasMore,
        isLoadingMore,
        failure,
        loadMoreFailure,
        language,
      ];
}
