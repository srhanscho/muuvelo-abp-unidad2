/// Connection data of the Muuvelo backend (Supabase).
///
/// WHY it is OK to have this key inside the app:
/// - It is a *publishable* key (the modern name of the "anon" key). It is
///   designed to ship inside mobile and web apps: anyone who installs the
///   APK could read it anyway.
/// - By itself it gives NO access to data. Every table has Row Level
///   Security (RLS): a request only sees rows whose `owner_id` equals the
///   id of the user who logged in. Without a session (anon role) the
///   tables have no privileges at all.
///
/// NEVER put the `service_role` / secret key in the app: that key skips
/// RLS and would let anyone read or delete every user's data. It only
/// belongs on a trusted server.
abstract final class SupabaseConfig {
  static const url = 'https://qhszxmmosnqoghnhwvwn.supabase.co';
  static const publishableKey = 'sb_publishable_iAjGIt73lvo3XkXiGqjCtw_PygoSeEt';
}
