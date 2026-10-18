// Public Supabase settings for the shared shelf page. Both values are the
// same ones the app ships with (SUPABASE_URL and SUPABASE_ANON_KEY in .env):
// the anon key is public by design, Row Level Security protects the data.
window.BOOKSHELF = {
  supabaseUrl: 'https://pnmnbfrbxghkkcgitzft.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBubW5iZnJieGdoa2tjZ2l0emZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk4OTg0MzgsImV4cCI6MjEwNTQ3NDQzOH0.baD_6U8-0XNKJJZkRR_RaIUNa21wKbAtgRWwu-s-QkI',

  // Android applicationId (android/app/build.gradle.kts).
  androidPackage: 'com.example.bookshelf',

  // Store pages, used when the app is not installed. Empty = not published
  // yet: the page then tells the reader the app is needed.
  // e.g. 'https://play.google.com/store/apps/details?id=com.example.bookshelf'
  playStoreUrl: '',
  // e.g. 'https://apps.apple.com/app/id1234567890'
  appStoreUrl: '',
};
