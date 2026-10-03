import '../../../core/config/app_config.dart';
import '../../search/domain/entities/book.dart';

/// A place where the reader can buy the book.
class BuyLink {
  const BuyLink({required this.label, required this.uri});

  final String label;
  final Uri uri;
}

/// The publisher's own site, when [Book.publisher] matches a known publisher.
class PublisherLink extends BuyLink {
  const PublisherLink({required super.label, required super.uri});
}

/// Links shown under "Where to buy": the publisher first (when known), then
/// the general bookstores.
List<BuyLink> buyLinksFor(Book book) => [
      if (publisherLinkFor(book) case final publisher?) publisher,
      ...storeLinksFor(book),
    ];

/// General bookstores. They index ISBNs, so the ISBN finds the exact edition;
/// without one, title and author are searched.
List<BuyLink> storeLinksFor(Book book) {
  final query = book.isbn ?? _titleQuery(book);
  const amazonTag = AppConfig.amazonAffiliateTag;
  return [
    BuyLink(
      label: 'Amazon',
      uri: Uri.https('www.amazon.it', '/s', {
        'k': query,
        if (amazonTag != null) 'tag': amazonTag,
      }),
    ),
    BuyLink(
      label: 'IBS',
      uri: Uri.https('www.ibs.it', '/search/', {'ts': 'as', 'query': query}),
    ),
    BuyLink(
      label: 'laFeltrinelli',
      uri: Uri.https('www.lafeltrinelli.it', '/search/', {'query': query}),
    ),
  ];
}

/// The publisher's site, searched by title where its search works without
/// JavaScript, otherwise its home page. Null for unknown publishers.
PublisherLink? publisherLinkFor(Book book) {
  final publisher = book.publisher;
  if (publisher == null) return null;
  final normalized = _normalize(publisher);
  for (final site in _publishers) {
    if (site.keywords.any((k) => _containsWord(normalized, k))) {
      return PublisherLink(label: site.name, uri: site.uriFor(book.title));
    }
  }
  return null;
}

String _titleQuery(Book book) =>
    [book.title, book.authors.firstOrNull].nonNulls.join(' ');

/// Lower case, accents and punctuation folded to plain words, so
/// "Giulio Einaudi Editore" and "EINAUDI" both read as "... einaudi ...".
String _normalize(String text) {
  const accents = {
    'à': 'a', 'á': 'a', 'è': 'e', 'é': 'e', 'ì': 'i', 'í': 'i', //
    'ò': 'o', 'ó': 'o', 'ù': 'u', 'ú': 'u',
  };
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'[^a-z0-9/]+'), ' ').trim();
}

bool _containsWord(String haystack, String keyword) =>
    RegExp('(^| )${RegExp.escape(keyword)}( |\$)').hasMatch(haystack);

class _PublisherSite {
  const _PublisherSite(
    this.name,
    this.keywords,
    this.host, {
    this.searchPath,
    this.searchParam,
  });

  final String name;

  /// Words of the normalized Open Library publisher name that identify it.
  final List<String> keywords;
  final String host;
  final String? searchPath;
  final String? searchParam;

  Uri uriFor(String title) => searchParam == null
      ? Uri.https(host, '/')
      : Uri.https(host, searchPath ?? '/', {searchParam!: title});
}

/// Publisher sites. A search is set only where it was checked to return
/// results as plain HTML; the others open on the home page.
const _publishers = [
  _PublisherSite('Einaudi', ['einaudi'], 'www.einaudi.it', searchParam: 's'),
  _PublisherSite(
    'Mondadori',
    ['mondadori'],
    'www.mondadori.it',
    searchParam: 's',
  ),
  _PublisherSite(
    'Feltrinelli',
    ['feltrinelli'],
    'www.feltrinellieditore.it',
    searchPath: '/search/',
    searchParam: 'q',
  ),
  _PublisherSite(
    'Rizzoli',
    ['rizzoli', 'bur'],
    'www.rizzolilibri.it',
    searchParam: 's',
  ),
  _PublisherSite(
    'Edizioni E/O',
    ['e/o'],
    'www.edizionieo.it',
    searchParam: 's',
  ),
  _PublisherSite(
    'minimum fax',
    ['minimum fax', 'minimumfax'],
    'www.minimumfax.com',
    searchParam: 's',
  ),
  _PublisherSite('Adelphi', ['adelphi'], 'www.adelphi.it'),
  _PublisherSite('Bompiani', ['bompiani'], 'www.bompiani.it'),
  _PublisherSite('Neri Pozza', ['neri pozza'], 'www.neripozza.it'),
  _PublisherSite('Sellerio', ['sellerio'], 'www.sellerio.it'),
  _PublisherSite('Garzanti', ['garzanti'], 'www.garzanti.it'),
  _PublisherSite('Longanesi', ['longanesi'], 'www.longanesi.it'),
  _PublisherSite('Salani', ['salani'], 'www.salani.it'),
  _PublisherSite('Giunti', ['giunti'], 'www.giunti.it'),
  _PublisherSite('Iperborea', ['iperborea'], 'iperborea.com'),
  _PublisherSite('Marsilio', ['marsilio'], 'www.marsilioeditori.it'),
  _PublisherSite('Newton Compton', ['newton compton'], 'www.newtoncompton.com'),
  _PublisherSite('Fazi', ['fazi'], 'www.fazieditore.it'),
  _PublisherSite('Laterza', ['laterza'], 'www.laterza.it'),
  _PublisherSite('il Mulino', ['il mulino'], 'www.ilmulino.it'),
  _PublisherSite('Sperling & Kupfer', ['sperling'], 'www.sperling.it'),
  _PublisherSite('TEA', ['tea'], 'www.tealibri.it'),
  _PublisherSite('UTET', ['utet'], 'www.utetlibri.it'),
  _PublisherSite(
    'Penguin Random House',
    ['penguin', 'random house', 'vintage', 'knopf', 'doubleday'],
    'www.penguinrandomhouse.com',
    searchPath: '/search/site',
    searchParam: 'q',
  ),
];
