import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/**
 * Enterprise Localization Provider for LensIQ.
 * Supports complete English (default) and Arabic (العربية) with bidirectional RTL layout.
 */
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
    // Brand & App Identity
    'LensIQ': 'لينس آي كيو (LensIQ)',
    'LensIQ Enterprise': 'منصة LensIQ المؤسسية',
    'AI Surveillance & Anomaly Detection': 'المراقبة الذكية ورصد المخاطر بالذكاء الاصطناعي',
    'AI CCTV Monitoring Platform': 'منصة مراقبة الكاميرات بالذكاء الاصطناعي',
    'Developed by POM Agency': 'تم التطوير بواسطة POM Agency',
    'pom-agency.online': 'pom-agency.online',
    'Visit POM Agency': 'زيارة موقع POM Agency',

    // Navigation & Menus
    'Dashboard': 'لوحة التحكم',
    'Companies': 'الشركات',
    'Brands': 'العلامات التجارية',
    'Branches': 'الفروع',
    'Cameras': 'الكاميرات',
    'AI Rules': 'قواعد الذكاء الاصطناعي',
    'Incidents': 'الحوادث والتنبيهات',
    'Users': 'إدارة المستخدمين',
    'Audit Logs': 'سجل العمليات والتدقيق',
    'Settings': 'الإعدادات',
    'Overview': 'نظرة عامة',
    'Camera Health': 'حالة الكاميرات',
    'Live Streams': 'البث المباشر',
    'Live Cameras': 'الكاميرات المباشرة',
    'Live Monitoring': 'المراقبة الحية',
    'Detection Rules': 'قواعد الرصد',
    'Multi-Grid': 'شبكة العرض المتعدد',
    'NOC Live Operations': 'مركز العمليات الأمنية (NOC)',

    // Roles & Authorization
    'Super Admin': 'مدير عام للنظام',
    'Brand Manager': 'مدير علامة تجارية',
    'Branch Security': 'مسؤول أمن الفرع',
    'Security Operator': 'مشغل أمني',
    'System Administrator': 'مدير النظام التقني',
    'Role': 'الدور والصلاحية',
    'Global Access': 'صلاحية شاملة لجميع الشركات',
    'Brand Scoped': 'محدود بالعلامة التجارية المحددة',
    'Branch Scoped': 'محدود بالفرع المحدد فقط',
    'Switch Demo Role': 'تبديل الدور التجريبي',

    // Statuses & Severities
    'Online': 'متصل',
    'Offline': 'غير متصل',
    'Active': 'نشط',
    'Inactive': 'غير نشط',
    'Degraded': 'أداء منخفض',
    'Critical': 'حرج',
    'High': 'مرتفع',
    'Medium': 'متوسط',
    'Low': 'منخفض',
    'Warning': 'تحذير',
    'Info': 'معلومات',
    'Open': 'مفتوح / غير معالج',
    'Acknowledged': 'تم الاستلام والمتابعة',
    'Resolved': 'تم الحل والإغلاق',
    'Dismissed': 'تم التجاهل',
    'False Positive': 'إنذار كاذب',
    'Real-time': 'فوري مباشر',
    'Live': 'مباشر',
    'Healthy': 'سليم',
    'Error': 'خطأ',
    'Pending': 'معلق',
    'Success': 'ناجح',
    'Failed': 'فشل',

    // Multi-Company & Multi-Tenancy
    'Company Management': 'إدارة الشركات والمؤسسات',
    'Add Company': 'إضافة شركة جديدة',
    'Edit Company': 'تعديل بيانات الشركة',
    'Delete Company': 'حذف الشركة',
    'Company Details': 'تفاصيل الشركة',
    'Company Name': 'اسم الشركة',
    'Total Companies': 'إجمالي الشركات',
    'Subscription Tier': 'باقة الاشتراك',
    'Enterprise Tier': 'باقة المؤسسات (Enterprise)',
    'Professional Tier': 'الباقة الاحترافية (Pro)',
    'Starter Tier': 'الباقة الأساسية (Starter)',
    'Max Brands': 'الحد الأقصى للعلامات',
    'Max Cameras': 'الحد الأقصى للكاميرات',
    'Created At': 'تاريخ الإنشاء',
    'Status': 'الحالة',

    // Brands
    'Brand Management': 'إدارة العلامات التجارية',
    'Add Brand': 'إضافة علامة تجارية',
    'Edit Brand': 'تعديل علامة تجارية',
    'Delete Brand': 'حذف العلامة التجارية',
    'Brand Details': 'تفاصيل العلامة التجارية',
    'Brand Name': 'اسم العلامة التجارية',
    'Total Brands': 'إجمالي العلامات التجارية',
    'Select Company': 'اختر الشركة التابعة لها',
    'Company': 'الشركة',

    // Branches
    'Branch Management': 'إدارة الفروع',
    'Add Branch': 'إضافة فرع جديد',
    'Edit Branch': 'تعديل بيانات الفرع',
    'Delete Branch': 'حذف الفرع',
    'Branch Details': 'تفاصيل الفرع',
    'Branch Name': 'اسم الفرع',
    'Total Branches': 'إجمالي الفروع',
    'City': 'المدينة',
    'Address': 'العنوان التفصيلي',
    'Phone': 'رقم الهاتف / التواصل',
    'Select Brand': 'اختر العلامة التجارية',
    'Select Branch': 'اختر الفرع',
    'Branch': 'الفرع',
    'Brand': 'العلامة التجارية',

    // Filtering & Searching
    'Filter by Company': 'تصفية حسب الشركة',
    'Filter by Brand': 'تصفية حسب العلامة التجارية',
    'Filter by Branch': 'تصفية حسب الفرع',
    'Filter by Status': 'تصفية حسب الحالة',
    'Filter by Severity': 'تصفية حسب درجة الخطورة',
    'Filter by Source': 'تصفية حسب نوع المصدر',
    'All Companies': 'جميع الشركات',
    'All Brands': 'جميع العلامات التجارية',
    'All Branches': 'جميع الفروع',
    'All Statuses': 'جميع الحالات',
    'All Severities': 'جميع درجات الخطورة',
    'All Sources': 'جميع أنواع المصادر',
    'Search companies...': 'البحث في الشركات...',
    'Search brands...': 'البحث في العلامات التجارية...',
    'Search branches...': 'البحث في الفروع...',
    'Search cameras...': 'البحث في الكاميرات...',
    'Search incidents...': 'البحث في الحوادث والتنبيهات...',
    'Search users...': 'البحث في المستخدمين...',
    'Search logs...': 'البحث في سجل التدقيق...',

    // Camera Management & Streaming
    'Camera Management': 'إدارة الكاميرات والبث',
    'Add Camera': 'إضافة كاميرا جديدة',
    'Edit Camera': 'تعديل بيانات الكاميرا',
    'Delete Camera': 'حذف الكاميرا',
    'Camera Details': 'تفاصيل الكاميرا',
    'Camera Name': 'اسم الكاميرا',
    'IP Address': 'عنوان IP',
    'Port': 'المنفذ (Port)',
    'RTSP Stream': 'بث مباشر RTSP',
    'Hikvision P2P': 'سحابي هيك فيجن P2P',
    'Source Type': 'نوع المصدر والاتصال',
    'Protocol': 'البروتوكول المستخدم',
    'Stream URL': 'رابط بث RTSP الكامل',
    'Device Serial': 'الرقم التسلسلي للجهاز (Serial)',
    'Verification Code': 'رمز التحقق الأمني (Verification Code)',
    'Resolution': 'دقة العرض',
    'FPS': 'معدل الإطارات (FPS)',
    'Bitrate': 'معدل نقل البيانات (Bitrate)',
    'Stream Health': 'كفاءة واستقرار البث',
    'Latency': 'زمن الاستجابة (Latency)',
    'Refresh Stream': 'تحديث البث',
    'Restart Camera': 'إعادة تشغيل الكاميرا',
    'Fullscreen': 'ملء الشاشة',
    'Exit Fullscreen': 'خروج من ملء الشاشة',
    'Snapshot': 'التقاط صورة',
    'Single View': 'عرض فردي',
    '2x2 Grid': 'شبكة 2×2 (4 كاميرات)',
    '3x3 Grid': 'شبكة 3×3 (9 كاميرات)',
    'Select Camera': 'اختر كاميرا للمعاينة',
    'Total Cameras': 'إجمالي الكاميرات',
    'Online Cameras': 'الكاميرات المتصلة',
    'Offline Cameras': 'الكاميرات المفصولة',
    'Degraded Streams': 'بثوث منخفضة الجودة',
    'Live Video Feed': 'شاشة البث الحي',
    'No camera selected': 'لم يتم تحديد كاميرا',
    'Connecting stream...': 'جاري الاتصال بالبث...',
    'Camera stream offline': 'بث الكاميرا متوقف حالياً',
    'Reconnecting...': 'جاري إعادة المحاولة...',
    'Test Connection': 'اختبار الاتصال',
    'Connection Successful': 'تم الاتصال بالكاميرا بنجاح',
    'Connection Failed': 'فشل الاتصال بالكاميرا، تحقق من الإعدادات',

    // AI Rules & Detections
    'AI Detection Rules': 'قواعد الرصد والتحليل الذكي',
    'Add AI Rule': 'إضافة قاعدة ذكاء اصطناعي',
    'Edit AI Rule': 'تعديل القاعدة',
    'Delete AI Rule': 'حذف القاعدة',
    'Rule Name': 'اسم القاعدة',
    'Rule Type': 'نوع الرصد الذكي',
    'Sensitivity': 'درجة الحساسية',
    'Confidence Threshold': 'عتبة الثقة واليقين',
    'Alert Severity': 'درجة خطورة التنبيه',
    'Cooldown (Seconds)': 'فترة التهدئة بين التنبيهات (ثانية)',
    'Detection Schedule': 'جدول العمل والمراقبة',
    'Cashier Area Empty': 'منطقة الكاشير خالية من الموظف',
    'Loitering Detected': 'رصد تواجد مشبوه أو تسكع متكرر',
    'Intrusion Detected': 'رصد تسلل لمنطقة محظورة أمنياً',
    'Face Mask Violation': 'مخالفة عدم ارتداء الكمامة الواقية',
    'Overcrowding Alert': 'تنبيه تكدس وازدحام مفرط للعملاء',
    'Fire & Smoke Detection': 'رصد دخان أو اشتعال حريق',
    'Perimeter Breach': 'اختراق المحيط الخارجي للموقع',
    'Suspicious Package': 'رصد حقيبة أو جسم مشبوه مجهول',
    'Active Rules': 'القواعد المفعلة',
    'Triggers Today': 'مرات الرصد اليوم',
    'Toggle Rule': 'تفعيل / تعطيل القاعدة',

    // Incidents & Security Feed
    'Live Incident Feed': 'الموجز الأمني للحوادث المباشرة',
    'Active Incidents': 'الحوادث النشطة الحالية',
    'Critical Incidents': 'حوادث ذات خطورة حرجة',
    'Incidents Today': 'إجمالي حوادث اليوم',
    'Resolved Incidents': 'الحوادث التي تم حلها',
    'Incident ID': 'معرّف الحادثة',
    'Timestamp': 'التوقيت والتاريخ',
    'Camera': 'الكاميرا',
    'Action': 'الإجراء المطلوب',
    'Acknowledge': 'استلام ومتابعة',
    'Resolve': 'إغلاق الحادثة',
    'Mark as False Positive': 'تحديد كإنذار خاطئ',
    'View Evidence': 'معاينة الأدلة المصورة',
    'Download Snapshot': 'تنزيل لقطة الحادثة',
    'Incident Details': 'تفاصيل الحادثة الأمنية',
    'Security Notes': 'ملاحظات فريق الأمن',
    'Add Note': 'إضافة ملاحظة جديدة',
    'Assigned Operator': 'المشغل المسؤول',
    'Action History': 'سجل الإجراءات المتخذة',
    'No incidents found': 'لا توجد حوادث أمنية مسجلة',
    'Recent Security Incidents': 'أحدث الحوادث والتنبيهات الأمنية',

    // Users & RBAC
    'User Management': 'إدارة المستخدمين والصلاحيات',
    'Add User': 'إضافة مستخدم جديد',
    'Edit User': 'تعديل بيانات المستخدم',
    'Delete User': 'حذف المستخدم',
    'Full Name': 'الاسم بالكامل',
    'Email': 'البريد الإلكتروني',
    'Password': 'كلمة المرور',
    'Confirm Password': 'تأكيد كلمة المرور',
    'Last Login': 'آخر تسجيل دخول',
    'Assigned Brand': 'العلامة التجارية المخصصة',
    'Assigned Branch': 'الفرع المخصص',
    'Active Users': 'المستخدمين النشطين',
    'User Details': 'تفاصيل المستخدم',

    // Audit Logs
    'Audit Trail & Security Logs': 'سجل التدقيق والعمليات الأمنية',
    'User': 'المستخدم',
    'Action Performed': 'العملية المنفذة',
    'Resource': 'المورد المستهدف',
    'Device / Agent': 'المتصفح / نظام التشغيل',
    'Export Audit Log': 'تصدير سجل التدقيق',

    // Settings & Configuration
    'System Preferences': 'تفضيلات وإعدادات النظام',
    'Appearance': 'المظهر والألوان',
    'Theme Mode': 'وضع العرض',
    'Dark Theme (NOC Security)': 'الوضع الليلي الداكن (مركز العمليات)',
    'Light Theme (Clean Enterprise)': 'الوضع النهاري الفاتح (مؤسسي ناصع)',
    'Language': 'اللغة وتنسيق الواجهة',
    'English (Default)': 'الإنجليزية (الافتراضية)',
    'Arabic (العربية RTL)': 'العربية (RTL مدمج بالكامل)',
    'Push Notifications': 'الإشعارات الفورية (FCM Push)',
    'Sound Alerts': 'التنبيهات الصوتية عند الحوادث الحرجة',
    'Email Alerts': 'إشعارات البريد الإلكتروني للمديرين',
    'Stream Quality': 'جودة بث الكاميرات',
    'High Definition (1080p)': 'دقة عالية (1080p)',
    'Save Preferences': 'حفظ التفضيلات',
    'Preferences saved': 'تم حفظ التفضيلات بنجاح',
    'Account Security & Password': 'أمان الحساب وكلمة المرور',
    'Current Password': 'كلمة المرور الحالية',
    'New Password': 'كلمة المرور الجديدة',
    'Confirm New Password': 'تأكيد كلمة المرور الجديدة',
    'Update Password': 'تحديث كلمة المرور',
    'Password updated successfully!': 'تم تحديث كلمة المرور بنجاح!',
    'Please fill in all password fields': 'يرجى ملء جميع حقول كلمة المرور',
    'New passwords do not match': 'كلمتا المرور غير متطابقتين',
    'Password must be at least 6 characters': 'يجب ألا تقل كلمة المرور عن 6 أحرف',

    // Notifications Panel & Header
    'Alerts & Notifications': 'التنبيهات والإشعارات الأمنية',
    'Mark all as read': 'تحديد الكل كمقروء',
    'No new notifications': 'لا توجد إشعارات جديدة حالياً',
    'Tap to inspect': 'اضغط للمعاينة الفورية',
    'Toggle Theme': 'تبديل المظهر',
    'Switch Language': 'تبديل اللغة',
    'Sign Out': 'تسجيل الخروج',
    'Notifications': 'الإشعارات',

    // Login Portal
    'Sign in to your account': 'تسجيل الدخول إلى حسابك',
    'Welcome Back': 'مرحباً بعودتك إلى LensIQ',
    'Remember me': 'تذكر بيانات الدخول',
    'Forgot Password?': 'نسيت كلمة المرور؟',
    'Sign In': 'تسجيل الدخول',
    'Signing in...': 'جاري تسجيل الدخول...',
    'Quick Demo Accounts': 'حسابات الدخول التجريبي السريع',
    'Super Admin Demo': 'دخول تجريبي: مدير عام (Super Admin)',
    'Brand Manager Demo': 'دخول تجريبي: مدير علامة (Brand Manager)',
    'Branch Security Demo': 'دخول تجريبي: مسؤول أمن (Branch Security)',
    'Please enter email and password': 'يرجى إدخال البريد الإلكتروني وكلمة المرور',
    'Authentication Failed': 'فشل التحقق، يرجى مراجعة البيانات المدخلة',

    // Common UI Buttons & Labels
    'Search': 'بحث...',
    'Filter': 'تصفية',
    'Clear Filters': 'مسح التصفية',
    'Save': 'حفظ',
    'Save Changes': 'حفظ التغييرات',
    'Cancel': 'إلغاء',
    'Delete': 'حذف',
    'Edit': 'تعديل',
    'View': 'عرض',
    'Close': 'إغلاق',
    'Confirm': 'تأكيد',
    'Apply': 'تطبيق',
    'Submit': 'إرسال',
    'Back': 'رجوع',
    'Next': 'التالي',
    'Previous': 'السابق',
    'Loading': 'جاري التحميل...',
    'No data found': 'لا توجد بيانات متوفرة حالياً',
    'Are you sure?': 'هل أنت متأكد من تنفيذ هذا الإجراء؟',
    'This action cannot be undone': 'هذا الإجراء نهائي ولا يمكن التراجع عنه.',
    'Action completed successfully': 'تم إتمام العملية بنجاح',
    'An error occurred': 'حدث خطأ، يرجى المحاولة مرة أخرى',
    'All Rights Reserved': 'جميع الحقوق محفوظة',
    'Operations Center': 'مركز العمليات',
    'Incident Trend (Last 7 Days)': 'معدل الحوادث (آخر 7 أيام)',
    'Camera Status Breakdown': 'توزيع حالات الكاميرات',
    'Quick Actions': 'إجراءات سريعة',
    'Add New Camera': 'إضافة كاميرا جديدة',
    'Export Report': 'تصدير تقرير أمني',
    'System Operational': 'النظام يعمل بكفاءة 100%',

    // Branch Security Console
    'Guard Feed': 'شاشة الحراسة الميدانية',
    'Live Cams': 'كاميرات حية',
    'Action Queue': 'طابور الإجراءات',
    'Health': 'الحالة التشغيلية',
    'Branch Security Console': 'منصة أمن الفرع',
    'CRITICAL ALERT IN PROGRESS': 'تنبيه طارئ قيد التنفيذ',
    'ACKNOWLEDGE': 'إقرار الاستلام',
    'RESOLVE': 'معالجة وإغلاق',
    'ON DUTY': 'في الخدمة',
    'Fast Triage (Quick Identification)': 'فرز وتصنيف فوري للمخاطر',
    'Show All': 'عرض الكل',
    'Cashier Problems': 'مشكلات الكاشير',
    'Unusual Activity': 'حركات غير معتادة',
    'Branch Live Feeds': 'البث المباشر لكاميرات الفرع',
    'Action Queue — Active Incidents': 'طابور الإجراءات — البلاغات النشطة',
    'Recent Branch History': 'سجل أحداث الفرع المؤخرة',
    'Officer Resolution Notes': 'ملاحظات مسؤول الأمن للحل',
    'Confirm Resolved': 'تأكيد المعالجة والإغلاق',
    'Checked and cleared by security patrol.': 'تم الفحص والمعاينة والتأمين من قِبل الدورية الأمنية.',
    'All clear in current triage filter. No open alerts.': 'الوضع مستقر وآمن تماماً، لا توجد بلاغات نشطة.',
    'Live Stream Connected (WebRTC / HLS)': 'البث المباشر نشط (WebRTC / HLS)',
    'LIVE • AI VISION ANALYSIS ACTIVE': 'بث مباشر • تحليل الذكاء الاصطناعي متصل',
    'Close Stream': 'إغلاق البث',
    'No resolved branch history today.': 'لا يوجد سجل حوادث تم حلها اليوم.',
    'Officer': 'المسؤول',
    'Shift: Active Monitoring': 'الوردية: مراقبة ميدانية نشطة',
  };
}

/// Handy extension on BuildContext for quick access to translations, directionality, and language state
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    try {
      return Provider.of<AppLocaleProvider>(this, listen: false).tr(key);
    } catch (_) {
      return key;
    }
  }

  bool get isArabic {
    try {
      return Provider.of<AppLocaleProvider>(this, listen: false).isArabic;
    } catch (_) {
      return false;
    }
  }

  TextDirection get textDirection {
    try {
      return Provider.of<AppLocaleProvider>(this, listen: false).textDirection;
    } catch (_) {
      return TextDirection.ltr;
    }
  }
}
