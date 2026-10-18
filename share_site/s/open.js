// How "Apri in BookShelf" opens the app, and where it goes when the app is
// missing. Pure functions on window.BookShelfOpen (also exported for tests).
(function (root) {
  var SCHEME = 'io.supabase.bookshelf';

  function platform(userAgent, maxTouchPoints) {
    if (/android/i.test(userAgent)) return 'android';
    // iPadOS reports itself as a Mac with a touch screen.
    if (/iphone|ipad|ipod/i.test(userAgent) ||
        (/macintosh/i.test(userAgent) && maxTouchPoints > 1)) return 'ios';
    return 'desktop';
  }

  function schemeLink(token) {
    return SCHEME + '://shelf/shared-shelf/' + encodeURIComponent(token);
  }

  // Chrome on Android ignores plain custom-scheme links in many cases;
  // an intent: link opens the app, or the fallback URL when it is missing.
  function androidLink(token, cfg) {
    var parts = [
      'intent://shelf/shared-shelf/' + encodeURIComponent(token) + '#Intent',
      'scheme=' + SCHEME
    ];
    if (cfg.playStoreUrl) {
      parts.push('package=' + cfg.androidPackage);
      parts.push('S.browser_fallback_url=' + encodeURIComponent(cfg.playStoreUrl));
    }
    return parts.join(';') + ';end';
  }

  function storeUrl(kind, cfg) {
    if (kind === 'android') return cfg.playStoreUrl || '';
    if (kind === 'ios') return cfg.appStoreUrl || '';
    return '';
  }

  var api = {
    platform: platform,
    schemeLink: schemeLink,
    androidLink: androidLink,
    storeUrl: storeUrl
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  root.BookShelfOpen = api;
})(typeof window !== 'undefined' ? window : this);
