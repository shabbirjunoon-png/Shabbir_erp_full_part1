import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/party.dart';
import '../models/stock_item.dart';
import '../models/transaction.dart';

const _supabaseUrl = 'https://ikadfsikkfslnystotxr.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlrYWRmc2lra2ZzbG55c3RvdHhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NTc0MDksImV4cCI6MjA5NDIzMzQwOX0.A0J5-DBOrc94pIKXS5TPGGe6NfSRHwLn2-KbVkTEzr0';

class SupabaseService {
  static SupabaseService? _instance;
  SupabaseService._();
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  SupabaseClient get _client => Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;

  bool get isLoggedIn => _client.auth.currentUser != null;

  String get userId => _client.auth.currentUser?.id ?? 'default';

  String get displayName {
    final u = _client.auth.currentUser;
    if (u == null) return 'User';
    return u.userMetadata?['full_name'] as String? ??
        u.userMetadata?['name'] as String? ??
        u.email ??
        'User';
  }

  String? get avatarUrl {
    final u = _client.auth.currentUser;
    return u?.userMetadata?['avatar_url'] as String? ??
        u?.userMetadata?['picture'] as String?;
  }

  String get email => _client.auth.currentUser?.email ?? '';

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static const _androidRedirect = 'com.shabbir.erp://login-callback/';

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? _webRedirectUrl() : _androidRedirect,
      authScreenLaunchMode: LaunchMode.platformDefault,
    );
  }

  Future<void> signInWithFacebook() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? _webRedirectUrl() : _androidRedirect,
      authScreenLaunchMode: LaunchMode.platformDefault,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String _webRedirectUrl() {
    final uri = Uri.base;
    return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}/';
  }

  // ── Parties ──────────────────────────────────────────────────────────────

  Future<List<Party>> getParties() async {
    final res = await _client
        .from('parties')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Party.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> upsertParty(Party party) async {
    await _client.from('parties').upsert({
      ...party.toMap(),
      'user_id': userId,
    });
  }

  Future<void> deleteParty(String id) async {
    await _client.from('parties').delete().eq('id', id).eq('user_id', userId);
  }

  // ── Stock Items ───────────────────────────────────────────────────────────

  Future<List<StockItem>> getStockItems() async {
    final res = await _client
        .from('stock_items')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => StockItem.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> upsertStockItem(StockItem item) async {
    await _client.from('stock_items').upsert({
      ...item.toMap(),
      'user_id': userId,
    });
  }

  Future<void> deleteStockItem(String id) async {
    await _client.from('stock_items').delete().eq('id', id).eq('user_id', userId);
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<List<Transaction>> getTransactions() async {
    final res = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Transaction.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> upsertTransaction(Transaction tx) async {
    await _client.from('transactions').upsert({
      ...tx.toMap(),
      'user_id': userId,
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id).eq('user_id', userId);
  }

  // ── Sync helpers ──────────────────────────────────────────────────────────

  Future<void> pushAll({
    required List<Party> parties,
    required List<StockItem> items,
    required List<Transaction> transactions,
  }) async {
    if (parties.isNotEmpty) {
      await _client.from('parties').upsert(
        parties.map((p) => {...p.toMap(), 'user_id': userId}).toList(),
      );
    }
    if (items.isNotEmpty) {
      await _client.from('stock_items').upsert(
        items.map((i) => {...i.toMap(), 'user_id': userId}).toList(),
      );
    }
    if (transactions.isNotEmpty) {
      await _client.from('transactions').upsert(
        transactions.map((t) => {...t.toMap(), 'user_id': userId}).toList(),
      );
    }
  }

  Future<Map<String, dynamic>> pullAll() async {
    final parties = await getParties();
    final items = await getStockItems();
    final txs = await getTransactions();
    return {
      'parties': parties,
      'stock_items': items,
      'transactions': txs,
    };
  }
}
