import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CookieConsentStatus {
  undecided,
  accepted,
  rejected,
}

class CookieConsentService {
  CookieConsentService._();
  static final CookieConsentService instance = CookieConsentService._();

  static const String _consentKey = 'cookie_consent_status';

  final ValueNotifier<CookieConsentStatus> consentNotifier =
      ValueNotifier<CookieConsentStatus>(CookieConsentStatus.undecided);

  bool get isAccepted => consentNotifier.value == CookieConsentStatus.accepted;
  bool get isRejected => consentNotifier.value == CookieConsentStatus.rejected;
  bool get isUndecided => consentNotifier.value == CookieConsentStatus.undecided;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_consentKey);
      if (saved == 'accepted') {
        consentNotifier.value = CookieConsentStatus.accepted;
      } else if (saved == 'rejected') {
        consentNotifier.value = CookieConsentStatus.rejected;
      } else {
        consentNotifier.value = CookieConsentStatus.undecided;
      }
    } catch (e) {
      debugPrint('[CookieConsentService] Error loading consent status: $e');
    }
  }

  Future<void> acceptCookies() async {
    consentNotifier.value = CookieConsentStatus.accepted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_consentKey, 'accepted');
    } catch (e) {
      debugPrint('[CookieConsentService] Error saving accepted consent: $e');
    }
  }

  Future<void> rejectCookies() async {
    consentNotifier.value = CookieConsentStatus.rejected;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_consentKey, 'rejected');
    } catch (e) {
      debugPrint('[CookieConsentService] Error saving rejected consent: $e');
    }
  }

  Future<void> resetConsent() async {
    consentNotifier.value = CookieConsentStatus.undecided;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentKey);
    } catch (e) {
      debugPrint('[CookieConsentService] Error resetting consent: $e');
    }
  }
}
