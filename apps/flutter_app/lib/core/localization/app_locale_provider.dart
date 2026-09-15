import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'app_language_code';

  Locale _locale = const Locale('en');
  final SharedPreferences? _prefs;

  AppLocaleProvider([this._prefs]) {
    _loadSavedLanguage();
  }

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isArabic => _locale.languageCode == 'ar';
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  void _loadSavedLanguage() {
    final savedCode = _prefs?.getString(_prefKey) ?? 'en';
    _locale = Locale(savedCode);
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'ar') return;
    if (_locale.languageCode == code) return;

    _locale = Locale(code);
    notifyListeners();

    if (_prefs != null) {
      await _prefs.setString(_prefKey, code);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    }
  }

  Future<void> toggleLanguage() async {
    final nextCode = isArabic ? 'en' : 'ar';
    await setLanguage(nextCode);
  }

  /// Translation dictionary lookup with English as the fallback default
  String tr(String key) {
    if (!isArabic) return key;
    return _translationsAr[key] ?? key;
  }

  static const Map<String, String> _translationsAr = {
    // Navigation / Menus
    'Dashboard': 'لوحة التحكم',
    'Companies': 'الشركات',
    'Brands': 'العلامات التجارية',
    'Branches': 'الفروع',
    'Cameras': 'الكاميرات',
    'AI Rules': 'قواعد الذكاء الاصطناعي',
    'Incidents': 'الحوادث والتنبيهات',
    'Users': 'المستخدمين',
    'Audit Logs': 'سجل العمليات',
    'Settings': 'الإعدادات',
    'Overview': 'نظرة عامة',
    'Camera Health': 'حالة الكاميرات',
    'Live Streams': 'البث المباشر',
    'Live Cameras': 'الكاميرات المباشرة',
    'Detection Rules': 'قواعد الرصد',

    // Roles
    'Super Admin': 'مدير عام',
    'Brand Manager': 'مدير علامة تجارية',
    'Branch Security': 'مسؤول أمن الفرع',

    // Statuses
    'Online': 'متصل',
    'Offline': 'غير متصل',
    'Active': 'نشط',
    'Critical': 'حرج',
    'Warning': 'تحذير',
    'Info': 'معلومات',
    'Open': 'مفتوح',
    'Acknowledged': 'تم الاطلاع',
    'Resolved': 'تم الحل',
    'False Positive': 'إنذار خاطئ',

    // App Bar & Notifications
    'Alerts & Notifications': 'التنبيهات والإشعارات',
    'Mark all as read': 'تحديد الكل كمقروء',
    'Tap to inspect': 'اضغط للمعاينة',
    'Toggle Theme': 'تبديل المظهر',
    'Switch Language': 'تبديل اللغة',
    'Sign Out': 'تسجيل الخروج',
    'Switch Demo Role': 'تبديل الدور التجريبي',

    // Metrics & Headers
    'Total Branches': 'إجمالي الفروع',
    'Online Cameras': 'الكاميرات المتصلة',
    'Offline Cameras': 'الكاميرات المفصولة',
    'Active Incidents': 'الحوادث النشطة',
    'Critical Incidents': 'الحوادث الحرجة',
    'Incidents Today': 'حوادث اليوم',
    'Live Incident Feed': 'موجز الحوادث المباشر',

    // Incident Types
    'Cashier Area Empty': 'منطقة الكاشير فارغة',
    'Loitering Detected': 'رصد تواجد مشبوه',
    'Intrusion Detected': 'رصد تسلل لمنطقة محظورة',
    'Face Mask Violation': 'مخالفة عدم ارتداء كمامة',
    'Overcrowding Alert': 'تنبيه تكدس وتزاحم',

    // Camera Sources
    'RTSP Stream': 'بث RTSP',
    'Hikvision P2P': 'هيك فيجن P2P',
    'Source Type': 'نوع المصدر',
    'Select Camera': 'اختر كاميرا',
    'All Sources': 'جميع المصادر',

    // Settings
    'Push Notifications': 'الإشعارات المباشرة',
    'Configure Preferences': 'تعديل التفضيلات',
    'Language': 'اللغة',
    'English': 'English',
    'Arabic': 'العربية',
  };
}
