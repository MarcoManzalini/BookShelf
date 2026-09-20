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

  SearchState copyWith({
    String? query,
    RequestStatus? status,
    List<Book>? books,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Failure? Function()? failure,
    Failure? Function()? loadMoreFailure,
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
      ];
}
