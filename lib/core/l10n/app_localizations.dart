import 'package:flutter/material.dart';
import '../../features/stock_check/domain/entities/check_status.dart';

// ── Public API ────────────────────────────────────────────────────────────────

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate = _Delegate();

  // Login
  String get loginTitle;
  String get loginSubtitle;
  String get loginEmail;
  String get loginPassword;
  String get loginSubmit;
  String get loginErrorEmailEmpty;
  String get loginErrorEmailInvalid;
  String get loginErrorPasswordEmpty;
  String get loginErrorGeneral;

  // Common tooltips
  String get tooltipLightMode;
  String get tooltipDarkMode;
  String get tooltipLanguage;

  // Home
  String get homeTitle;
  String get tooltipCloseSearch;
  String get tooltipSearch;
  String get tooltipRefresh;
  String get tooltipSignOut;
  String get searchHint;
  String get tabNewRequests;
  String get urgentBadge;
  String get tabTransferred;
  String get filterToday;
  String get filterYesterday;
  String get filterThisWeek;
  String get filterAll;
  String get emptyAllClearTitle;
  String get emptyAllClearMsg;
  String get emptyNothingYetTitle;
  String get emptyNothingYetMsg;
  String get emptyNoMatchesTitle;
  String get emptyNoMatchesMsg;
  String get errorTitle;
  String get btnRetry;
  String get snackRefreshed;
  String get unknownCustomer;
  String get btnCallCustomer;
  String get noPhone;
  String get btnWhatsApp;
  String get btnCancel;
  String get statusPendingChip;
  String get statusTransferredChip;

  // Stats chip
  String get statsLast7Days;
  String get statsDay;
  String get statsPending;
  String get statsTransferred;
  String get statsToday;
  String get statsYesterday;
  String get statsFooter;

  // Stock check
  String get stockCheckTitle;
  String get tooltipScan;
  String get tooltipSearchItems;
  String get tooltipPdf;
  String get tooltipMore;
  String get menuShowHistory;
  String get searchItemsHint;
  String get allChecked;
  String get labelProgress;
  String get statusAvailable;
  String get statusPartial;
  String get statusOutOfStock;
  String get emptyNoItemsTitle;
  String get emptyNoItemsMsg;
  String get hintCheckAll;
  String get hintAddShortageReason;
  String get hintIssuesNotify;
  String get btnSendReview;
  String get btnMarkTransferred;
  String get sellAsLabel;
  String get sellAsHamasat;
  String get sellAsFlowerCenter;
  String get snackTransferredManual;
  String get snackTransferQueued;
  String get noFixedPriceTitle;
  String noFixedPriceContent(String items);
  String get btnHandleManually;
  String get handleManuallyBtn;
  String get manualTransferTitle;
  String get manualTransferContent;
  String get btnConfirm;
  String get btnMarkAll;
  String get dialogMarkAllTitle;
  String get dialogConfirmTransferTitle;
  String get dialogConfirmTransferContent;
  String get dialogSendReviewTitle;
  String get dialogSendReviewContent;
  String get snackSentReview;
  String get snackTransferred;
  String markAllAvailableBtn(int count);
  String dialogMarkAllContent(int count);
  String noBarcodeMatch(String code);
  String showingFilter(int visible, int total, int checked);
  String itemsChecked(int checked, int total);

  // Scanner
  String get scannerTitle;
  String get tooltipTorch;
  String get scannerHint;

  // PDF preview
  String get pdfTitle;
  String get pdfGenerating;
  String get pdfError;
  String get btnDownload;
  String get btnShare;

  // Table columns
  String get colItem;
  String get colQty;
  String get colStore;
  String get colAvail;
  String get colSendQty;
  String get colStatus;
  String get statusAvailShort;
  String get statusPartShort;
  String get statusOosShort;
  String get outOfStockPlaceholder;
  String get storeSelectHint;
  String get storeAdd;

  // History sheets
  String get historyTitle;
  String get historySubtitle;
  String get historyEmpty;
  String get historyFailedLoad;
  String get shortageTitle;
  String get shortageEmpty;
  String get recentEvents;
  String get statusAvailableLabel;
  String get statusPartialLabel;
  String get statusOutOfStockLabel;
  String get statusPendingLabel;
  String mostRecentOf(int shown, int total);
  String oosCount(int n);
  String partialCount(int n);

  // Relative time
  String get timeJustNow;
  String get timeYesterday;
  String timeMinutesAgo(int n);
  String timeHoursAgo(int n);
  String timeDaysAgo(int n);

  // Weekday abbreviation (1 = Mon … 7 = Sun)
  String weekdayAbbr(int weekday);
}

// ── BuildContext extension ────────────────────────────────────────────────────

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// ── CheckStatus extension ─────────────────────────────────────────────────────

extension CheckStatusL10n on CheckStatus {
  String localizedLabel(AppLocalizations l) => switch (this) {
        CheckStatus.available  => l.statusAvailableLabel,
        CheckStatus.partial    => l.statusPartialLabel,
        CheckStatus.outOfStock => l.statusOutOfStockLabel,
        CheckStatus.pending    => l.statusPendingLabel,
      };

  String localizedShort(AppLocalizations l) => switch (this) {
        CheckStatus.available  => l.statusAvailShort,
        CheckStatus.partial    => l.statusPartShort,
        CheckStatus.outOfStock => l.statusOosShort,
        CheckStatus.pending    => '',
      };
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      locale.languageCode == 'ar' ? _ArLocalizations() : _EnLocalizations();

  @override
  bool shouldReload(_Delegate old) => false;
}

// ── English ───────────────────────────────────────────────────────────────────

class _EnLocalizations extends AppLocalizations {
  @override String get loginTitle             => 'Warehouse\nManager';
  @override String get loginSubtitle          => 'Flower Center — Stock & Transfer';
  @override String get loginEmail             => 'Email address';
  @override String get loginPassword          => 'Password';
  @override String get loginSubmit            => 'Sign In';
  @override String get loginErrorEmailEmpty   => 'Enter your email';
  @override String get loginErrorEmailInvalid => 'Enter a valid email';
  @override String get loginErrorPasswordEmpty => 'Enter your password';
  @override String get loginErrorGeneral      => 'An error occurred. Please try again.';

  @override String get tooltipLightMode => 'Switch to light mode';
  @override String get tooltipDarkMode  => 'Switch to dark mode';
  @override String get tooltipLanguage  => 'عربي';

  @override String get homeTitle            => 'Warehouse';
  @override String get tooltipCloseSearch   => 'Close search';
  @override String get tooltipSearch        => 'Search';
  @override String get tooltipRefresh       => 'Refresh';
  @override String get tooltipSignOut       => 'Sign out';
  @override String get searchHint           => 'Search customer, company, salesperson…';
  @override String get tabNewRequests       => 'New Requests';
  @override String get urgentBadge          => 'URGENT';
  @override String get tabTransferred       => 'Transferred';
  @override String get filterToday          => 'Today';
  @override String get filterYesterday      => 'Yesterday';
  @override String get filterThisWeek       => 'This week';
  @override String get filterAll            => 'All';
  @override String get emptyAllClearTitle   => 'All clear!';
  @override String get emptyAllClearMsg     => 'No new requests right now.';
  @override String get emptyNothingYetTitle => 'Nothing here yet';
  @override String get emptyNothingYetMsg   => 'No transferred quotations for this filter.';
  @override String get emptyNoMatchesTitle  => 'No matches';
  @override String get emptyNoMatchesMsg    => 'Try a different search term or filter.';
  @override String get errorTitle           => 'Something went wrong';
  @override String get btnRetry             => 'Retry';
  @override String get snackRefreshed       => 'Refreshed';
  @override String get unknownCustomer      => 'Unknown Customer';
  @override String get btnCallCustomer      => 'Call customer';
  @override String get noPhone              => 'No phone number on this quotation';
  @override String get btnWhatsApp          => 'WhatsApp';
  @override String get btnCancel            => 'Cancel';
  @override String get statusPendingChip    => 'Pending';
  @override String get statusTransferredChip => 'Transferred';

  @override String get statsLast7Days   => 'Last 7 days';
  @override String get statsDay         => 'Day';
  @override String get statsPending     => 'Pending';
  @override String get statsTransferred => 'Transferred';
  @override String get statsToday       => 'Today';
  @override String get statsYesterday   => 'Yesterday';
  @override String get statsFooter      => 'Counts are by quotation creation date.';

  @override String get stockCheckTitle       => 'Stock Check';
  @override String get tooltipScan           => 'Scan item barcode';
  @override String get tooltipSearchItems    => 'Search items';
  @override String get tooltipPdf            => 'Generate PDF Report';
  @override String get tooltipMore           => 'More';
  @override String get menuShowHistory       => 'Show history';
  @override String get searchItemsHint       => 'Search by name, code, supplier…';
  @override String get allChecked            => 'All items checked!';
  @override String get labelProgress         => 'Progress';
  @override String get statusAvailable       => 'Available';
  @override String get statusPartial         => 'Partial';
  @override String get statusOutOfStock      => 'Out of stock';
  @override String get emptyNoItemsTitle     => 'No items found';
  @override String get emptyNoItemsMsg       => 'This quotation has no items to check.';
  @override String get hintCheckAll          => 'Check all items to enable the transfer action';
  @override String get hintAddShortageReason => 'Add a shortage reason to every Partial / Out-of-stock item';
  @override String get hintIssuesNotify      => 'Some items are partial or out of stock — sales team will be notified.';
  @override String get btnSendReview         => 'Send for Review';
  @override String get btnMarkTransferred    => 'Mark as Transferred';
  @override String get sellAsLabel           => 'Sell as:';
  @override String get sellAsHamasat         => 'Hamasat';
  @override String get sellAsFlowerCenter    => 'Flower Center';
  @override String get snackTransferredManual => 'Marked transferred — handle in Al-Khazen manually.';
  @override String get snackTransferQueued    => 'Still processing — Al-Khazen documents are being created, check back shortly.';
  @override String get noFixedPriceTitle      => 'No fixed price set';
  @override String noFixedPriceContent(String items) =>
      'These items have no fixed price in Al-Khazen:\n\n$items\n\nSet their fixed price in Al-Khazen and tap Retry, or handle this sale manually in Al-Khazen.';
  @override String get btnHandleManually      => 'Handle Manually';
  @override String get handleManuallyBtn      => 'Handle manually in Al-Khazen';
  @override String get manualTransferTitle    => 'Handle manually?';
  @override String get manualTransferContent  =>
      'This marks the quotation transferred without creating any Al-Khazen documents. You will create the transfer, sale and invoice in Al-Khazen yourself. Continue?';
  @override String get btnConfirm            => 'Confirm';
  @override String get btnMarkAll            => 'Mark all';
  @override String get dialogMarkAllTitle    => 'Mark all as Available?';
  @override String get dialogConfirmTransferTitle   => 'Confirm Transfer';
  @override String get dialogConfirmTransferContent =>
      'All items have been verified and stock is ready.\n\nThis will notify the sales team.';
  @override String get dialogSendReviewTitle   => 'Send for Sales Review?';
  @override String get dialogSendReviewContent =>
      'At least one item is partial or out of stock.\n\nThe salesperson will be notified so they can adjust or replace unavailable items.';
  @override String get snackSentReview  => 'Sent to sales for review ✓';
  @override String get snackTransferred => 'Marked as Transferred ✓';
  @override String markAllAvailableBtn(int count) => 'Mark all $count items as available';
  @override String dialogMarkAllContent(int count) =>
      'This will mark all $count items as Available with the requested quantity.\n\nYou can still adjust individual items afterwards.';
  @override String noBarcodeMatch(String code) =>
      'No item in this quotation matches "$code"';
  @override String showingFilter(int visible, int total, int checked) =>
      'Showing $visible of $total · $checked checked';
  @override String itemsChecked(int checked, int total) =>
      '$checked of $total items checked';

  @override String get scannerTitle => 'Scan barcode';
  @override String get tooltipTorch => 'Toggle torch';
  @override String get scannerHint  => 'Point the camera at the item barcode';

  @override String get pdfTitle      => 'PDF Report';
  @override String get pdfGenerating => 'Generating PDF…';
  @override String get pdfError      => 'Failed to generate PDF';
  @override String get btnDownload   => 'Download';
  @override String get btnShare      => 'Share';

  @override String get colItem                => 'ITEM';
  @override String get colQty                 => 'QTY';
  @override String get colStore               => 'STORE / WAREHOUSE';
  @override String get colAvail               => 'AVAIL';
  @override String get colSendQty             => 'SEND QTY';
  @override String get colStatus              => 'STATUS';
  @override String get statusAvailShort       => 'Avail';
  @override String get statusPartShort        => 'Part';
  @override String get statusOosShort         => 'OOS';
  @override String get outOfStockPlaceholder  => 'Out of stock';
  @override String get storeSelectHint        => 'Select store';
  @override String get storeAdd               => 'Add store';

  @override String get historyTitle       => 'Stock check history';
  @override String get historySubtitle    => 'Every status change on this quotation';
  @override String get historyEmpty       => 'No history yet — changes will appear here as you check items.';
  @override String get historyFailedLoad  => 'Failed to load history.';
  @override String get shortageTitle      => 'Shortage history (last 30 days)';
  @override String get shortageEmpty      => 'No shortages recorded for this item in the last 30 days.';
  @override String get recentEvents       => 'Recent events';
  @override String get statusAvailableLabel  => 'Available';
  @override String get statusPartialLabel    => 'Partial';
  @override String get statusOutOfStockLabel => 'Out of stock';
  @override String get statusPendingLabel    => 'Pending';
  @override String mostRecentOf(int shown, int total) => 'Most recent $shown of $total';
  @override String oosCount(int n)     => '$n × out of stock';
  @override String partialCount(int n) => '$n × partial';

  @override String get timeJustNow   => 'Just now';
  @override String get timeYesterday => 'Yesterday';
  @override String timeMinutesAgo(int n) => '${n}m ago';
  @override String timeHoursAgo(int n)   => '${n}h ago';
  @override String timeDaysAgo(int n)    => '${n}d ago';

  @override String weekdayAbbr(int weekday) => const [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ][weekday - 1];
}

// ── Arabic ────────────────────────────────────────────────────────────────────

class _ArLocalizations extends AppLocalizations {
  @override String get loginTitle             => 'مدير\nالمستودع';
  @override String get loginSubtitle          => 'مركز الزهور — المخزون والنقل';
  @override String get loginEmail             => 'البريد الإلكتروني';
  @override String get loginPassword          => 'كلمة المرور';
  @override String get loginSubmit            => 'تسجيل الدخول';
  @override String get loginErrorEmailEmpty   => 'أدخل بريدك الإلكتروني';
  @override String get loginErrorEmailInvalid => 'أدخل بريداً إلكترونياً صحيحاً';
  @override String get loginErrorPasswordEmpty => 'أدخل كلمة المرور';
  @override String get loginErrorGeneral      => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override String get tooltipLightMode => 'الوضع الفاتح';
  @override String get tooltipDarkMode  => 'الوضع الداكن';
  @override String get tooltipLanguage  => 'English';

  @override String get homeTitle            => 'المستودع';
  @override String get tooltipCloseSearch   => 'إغلاق البحث';
  @override String get tooltipSearch        => 'بحث';
  @override String get tooltipRefresh       => 'تحديث';
  @override String get tooltipSignOut       => 'تسجيل الخروج';
  @override String get searchHint           => 'بحث بالعميل أو الشركة أو المندوب...';
  @override String get tabNewRequests       => 'طلبات جديدة';
  @override String get urgentBadge          => 'عاجل';
  @override String get tabTransferred       => 'تم النقل';
  @override String get filterToday          => 'اليوم';
  @override String get filterYesterday      => 'أمس';
  @override String get filterThisWeek       => 'هذا الأسبوع';
  @override String get filterAll            => 'الكل';
  @override String get emptyAllClearTitle   => 'لا توجد طلبات!';
  @override String get emptyAllClearMsg     => 'لا توجد طلبات جديدة الآن.';
  @override String get emptyNothingYetTitle => 'لا يوجد شيء بعد';
  @override String get emptyNothingYetMsg   => 'لا توجد عروض أسعار منقولة لهذا الفلتر.';
  @override String get emptyNoMatchesTitle  => 'لا توجد نتائج';
  @override String get emptyNoMatchesMsg    => 'جرّب مصطلح بحث أو فلتراً مختلفاً.';
  @override String get errorTitle           => 'حدث خطأ ما';
  @override String get btnRetry             => 'إعادة المحاولة';
  @override String get snackRefreshed       => 'تم التحديث';
  @override String get unknownCustomer      => 'عميل غير معروف';
  @override String get btnCallCustomer      => 'الاتصال بالعميل';
  @override String get noPhone              => 'لا يوجد رقم هاتف في هذا العرض';
  @override String get btnWhatsApp          => 'واتساب';
  @override String get btnCancel            => 'إلغاء';
  @override String get statusPendingChip    => 'قيد الانتظار';
  @override String get statusTransferredChip => 'تم النقل';

  @override String get statsLast7Days   => 'آخر 7 أيام';
  @override String get statsDay         => 'اليوم';
  @override String get statsPending     => 'معلق';
  @override String get statsTransferred => 'منقول';
  @override String get statsToday       => 'اليوم';
  @override String get statsYesterday   => 'أمس';
  @override String get statsFooter      => 'العدد حسب تاريخ إنشاء عرض السعر.';

  @override String get stockCheckTitle       => 'فحص المخزون';
  @override String get tooltipScan           => 'مسح الباركود';
  @override String get tooltipSearchItems    => 'بحث في الأصناف';
  @override String get tooltipPdf            => 'إنشاء تقرير PDF';
  @override String get tooltipMore           => 'المزيد';
  @override String get menuShowHistory       => 'عرض السجل';
  @override String get searchItemsHint       => 'بحث بالاسم أو الكود أو المورد...';
  @override String get allChecked            => 'تم فحص جميع الأصناف!';
  @override String get labelProgress         => 'التقدم';
  @override String get statusAvailable       => 'متاح';
  @override String get statusPartial         => 'جزئي';
  @override String get statusOutOfStock      => 'نفد المخزون';
  @override String get emptyNoItemsTitle     => 'لا توجد أصناف';
  @override String get emptyNoItemsMsg       => 'لا توجد أصناف لفحصها في هذا العرض.';
  @override String get hintCheckAll          => 'افحص جميع الأصناف لتفعيل إجراء النقل';
  @override String get hintAddShortageReason => 'أضف سبب النقص لكل صنف جزئي أو نافد';
  @override String get hintIssuesNotify      => 'بعض الأصناف جزئية أو نافدة — سيتم إخطار فريق المبيعات.';
  @override String get btnSendReview         => 'إرسال للمراجعة';
  @override String get btnMarkTransferred    => 'تأكيد النقل';
  @override String get sellAsLabel           => 'البيع باسم:';
  @override String get sellAsHamasat         => 'همسات';
  @override String get sellAsFlowerCenter    => 'فلاور سنتر';
  @override String get snackTransferredManual => 'تم تأكيد النقل — تعامل معه يدويًا في الخازن.';
  @override String get snackTransferQueued    => 'قيد المعالجة — جارٍ إنشاء مستندات الخازن، يرجى المراجعة لاحقًا.';
  @override String get noFixedPriceTitle      => 'لا يوجد سعر ثابت';
  @override String noFixedPriceContent(String items) =>
      'هذه الأصناف ليس لها سعر ثابت في الخازن:\n\n$items\n\nاضبط السعر الثابت في الخازن ثم اضغط إعادة المحاولة، أو تعامل مع البيع يدويًا في الخازن.';
  @override String get btnHandleManually      => 'معالجة يدوية';
  @override String get handleManuallyBtn      => 'معالجة يدوية في الخازن';
  @override String get manualTransferTitle    => 'معالجة يدوية؟';
  @override String get manualTransferContent  =>
      'سيتم تأكيد النقل بدون إنشاء أي مستندات في الخازن. ستقوم بإنشاء النقل والبيع والفاتورة في الخازن بنفسك. متابعة؟';
  @override String get btnConfirm            => 'تأكيد';
  @override String get btnMarkAll            => 'تحديد الكل';
  @override String get dialogMarkAllTitle    => 'تحديد الكل كمتاح؟';
  @override String get dialogConfirmTransferTitle   => 'تأكيد النقل';
  @override String get dialogConfirmTransferContent =>
      'تم التحقق من جميع الأصناف والمخزون جاهز.\n\nسيتم إخطار فريق المبيعات.';
  @override String get dialogSendReviewTitle   => 'إرسال لمراجعة المبيعات؟';
  @override String get dialogSendReviewContent =>
      'صنف واحد على الأقل جزئي أو نافد.\n\nسيتم إخطار المندوب ليتمكن من التعديل أو الاستبدال.';
  @override String get snackSentReview  => 'تم الإرسال للمبيعات للمراجعة ✓';
  @override String get snackTransferred => 'تم تأكيد النقل ✓';
  @override String markAllAvailableBtn(int count) => 'تحديد $count صنفاً كمتاح';
  @override String dialogMarkAllContent(int count) =>
      'سيتم تحديد $count صنفاً كمتاح بالكميات المطلوبة.\n\nيمكنك تعديل الأصناف بشكل فردي بعد ذلك.';
  @override String noBarcodeMatch(String code) =>
      'لا يوجد صنف يطابق "$code" في هذا العرض';
  @override String showingFilter(int visible, int total, int checked) =>
      'عرض $visible من $total · $checked تم فحصه';
  @override String itemsChecked(int checked, int total) =>
      '$checked من $total صنف تم فحصه';

  @override String get scannerTitle => 'مسح الباركود';
  @override String get tooltipTorch => 'تشغيل/إيقاف الضوء';
  @override String get scannerHint  => 'وجّه الكاميرا نحو باركود الصنف';

  @override String get pdfTitle      => 'تقرير PDF';
  @override String get pdfGenerating => 'جارٍ إنشاء PDF...';
  @override String get pdfError      => 'فشل إنشاء PDF';
  @override String get btnDownload   => 'تحميل';
  @override String get btnShare      => 'مشاركة';

  @override String get colItem                => 'الصنف';
  @override String get colQty                 => 'الكمية';
  @override String get colStore               => 'المستودع';
  @override String get colAvail               => 'متاح';
  @override String get colSendQty             => 'كمية الإرسال';
  @override String get colStatus              => 'الحالة';
  @override String get statusAvailShort       => 'متاح';
  @override String get statusPartShort        => 'جزئي';
  @override String get statusOosShort         => 'نفد';
  @override String get outOfStockPlaceholder  => 'نفد المخزون';
  @override String get storeSelectHint        => 'اختر المستودع';
  @override String get storeAdd               => 'إضافة مستودع';

  @override String get historyTitle       => 'سجل فحص المخزون';
  @override String get historySubtitle    => 'جميع تغييرات الحالة لهذا العرض';
  @override String get historyEmpty       => 'لا يوجد سجل بعد — ستظهر التغييرات هنا عند فحص الأصناف.';
  @override String get historyFailedLoad  => 'فشل تحميل السجل.';
  @override String get shortageTitle      => 'سجل النقص (آخر 30 يوماً)';
  @override String get shortageEmpty      => 'لا يوجد نقص مسجل لهذا الصنف في آخر 30 يوماً.';
  @override String get recentEvents       => 'الأحداث الأخيرة';
  @override String get statusAvailableLabel  => 'متاح';
  @override String get statusPartialLabel    => 'جزئي';
  @override String get statusOutOfStockLabel => 'نفد المخزون';
  @override String get statusPendingLabel    => 'قيد الانتظار';
  @override String mostRecentOf(int shown, int total) => 'آخر $shown من $total';
  @override String oosCount(int n)     => '$n × نافد المخزون';
  @override String partialCount(int n) => '$n × جزئي';

  @override String get timeJustNow   => 'الآن';
  @override String get timeYesterday => 'أمس';
  @override String timeMinutesAgo(int n) => 'منذ ${n}د';
  @override String timeHoursAgo(int n)   => 'منذ ${n}س';
  @override String timeDaysAgo(int n)    => 'منذ ${n} أيام';

  @override String weekdayAbbr(int weekday) => const [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
  ][weekday - 1];
}
