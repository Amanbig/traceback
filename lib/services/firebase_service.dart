import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../firebase_options.dart';
import '../models/scam_radar_item.dart';
import '../models/threat_report.dart';

class FirebaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static User? get currentUser =>
      _initialized ? FirebaseAuth.instance.currentUser : null;

  static Stream<User?> authStateChanges() {
    if (!_initialized) return const Stream.empty();
    return FirebaseAuth.instance.authStateChanges();
  }

  static Future<void> initialize() async {
    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Initialize App Check (Required for Firebase AI Logic runtime attestation)
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidDebugProvider(),
          providerApple: const AppleDebugProvider(),
        );
      } catch (e) {
        debugPrint('App Check init warning (tolerated for development): $e');
      }

      // 3. Anonymous Authentication (For session & audit logging)
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }
      } catch (e) {
        debugPrint('Firebase Auth warning: $e');
      }

      // 4. Remote Config initialization (Dynamic scam thresholds)
      try {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 10),
            minimumFetchInterval: const Duration(hours: 1),
          ),
        );
        await remoteConfig.setDefaults({
          'high_risk_threshold': 75,
          'urgency_multiplier': 1.2,
          'enable_cloud_ai': true,
        });
        await remoteConfig.fetchAndActivate();
      } catch (e) {
        debugPrint('Remote Config warning: $e');
      }

      _initialized = true;
      debugPrint('Firebase & App Check initialized successfully!');
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  /// Sign In with Email & Password
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_initialized) return null;
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Create Account with Email & Password
  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    if (!_initialized) return null;
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign In as Guest (Anonymous)
  static Future<UserCredential?> signInGuest() async {
    if (!_initialized) return null;
    return await FirebaseAuth.instance.signInAnonymously();
  }

  /// Sign Out
  static Future<void> signOut() async {
    if (!_initialized) return;
    await FirebaseAuth.instance.signOut();
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
  }

  /// Syncs an investigation report to the user's private cloud history in Firestore
  static Future<void> syncInvestigationToCloud(ThreatReport report) async {
    if (!_initialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('investigations')
          .doc(report.id)
          .set({
        ...report.toMap(),
        'syncedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Cloud sync warning: $e');
    }
  }

  /// Submits a user-reported scam pattern to the public Scam Radar in Firestore
  static Future<void> submitCommunityScam(ScamRadarItem item) async {
    if (!_initialized) return;
    try {
      await FirebaseFirestore.instance.collection('community_scams').add({
        'title': item.title,
        'category': item.category,
        'sampleText': item.sampleText,
        'severity': item.severity,
        'targetAudience': item.targetAudience,
        'modusOperandi': item.modusOperandi,
        'warningSigns': item.warningSigns,
        'safetyTip': item.safetyTip,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error reporting scam to Firestore: $e');
    }
  }

  /// Streams community scam reports from Firestore
  static Stream<List<ScamRadarItem>> streamCommunityScams() {
    if (!_initialized) {
      return Stream.value(ScamRadarItem.trendingScams);
    }
    return FirebaseFirestore.instance
        .collection('community_scams')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return ScamRadarItem.trendingScams;
      }
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return ScamRadarItem(
          id: doc.id,
          title: data['title'] ?? 'Community Reported Fraud',
          category: data['category'] ?? 'General',
          sampleText: data['sampleText'] ?? '',
          severity: data['severity'] ?? 'High',
          targetAudience: data['targetAudience'] ?? 'General Public',
          modusOperandi: data['modusOperandi'] ?? '',
          warningSigns: List<String>.from(data['warningSigns'] ?? []),
          safetyTip: data['safetyTip'] ?? '',
        );
      }).toList();

      return [...items, ...ScamRadarItem.trendingScams];
    });
  }
}
