import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'my_khata': 'My Khata',
      'dashboard': 'Dashboard',
      'clients': 'Clients',
      'all_clients': 'All Clients',
      'add_customer': 'Add Customer',
      'search': 'Search',
      'filter': 'Filter',
      'all': 'All',
      'you_will_get': 'You\'ll Get',
      'you_will_give': 'You\'ll Give',
      'cleared': 'Cleared',
      'recently_added': 'Recently Added',
      'customer_details': 'Customer Details',
      'entries': 'Entries',
      'you_gave': 'You Gave',
      'you_got': 'You Got',
      'hide_balance': 'Hide Balance',
      'show_balance': 'Show Balance',
      'total': 'Total',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'share': 'Share',
      'pdf': 'PDF',
      'phone_number': 'Phone Number',
      'address': 'Address',
      'city': 'City',
      'cnic': 'CNIC',
      'notes': 'Notes',
      'item_category': 'Item Category',
      'cash': 'Cash',
      'bank': 'Bank',
      'online': 'Online',
      'update_customer': 'Update Customer',
      'add_new_customer': 'Add New Customer',
      'customer_name': 'Customer Name *',
      'settings': 'Settings',
      'choose_language': 'Choose Language',
      'english': 'English',
      'urdu': 'اردو (Urdu)',
      'new_customer': 'New Customer',
      'save_customer': 'SAVE CUSTOMER',
      'delete_customer': 'Delete Customer',
      'delete_customer_msg': 'Are you sure you want to delete this customer?',
      'close': 'CLOSE',
      'amount': 'Amount',
      'date': 'Date',
      'add_transaction': 'Add Transaction',
      'update_transaction': 'Update Transaction',
      'transaction_type': 'Transaction Type?',
      'which_goods': 'Which Goods?',
      'weight': 'Weight',
      'today': 'Today',
      'transaction_saved': 'Transaction saved successfully',
      'select_date': 'Select Date',
      'purchased_goods': 'Purchased Goods',
      'sold_goods': 'Sold Goods',
      'cash_given': 'Cash Given',
      'cash_received': 'Cash Received',
      'rice': 'Rice',
      'scrap': 'Scrap',
      'other': 'Other',
    },
    'ur': {
      'my_khata': 'میرا کھاتہ',
      'dashboard': 'ڈیش بورڈ',
      'clients': 'کلائنٹس',
      'all_clients': 'تمام کلائنٹس',
      'add_customer': 'گاہک شامل کریں',
      'search': 'تلاش کریں',
      'filter': 'فلٹر',
      'all': 'تمام',
      'you_will_get': 'آپ کو ملیں گے',
      'you_will_give': 'آپ دیں گے',
      'cleared': 'صاف شدہ (Cleared)',
      'recently_added': 'حال ہی میں شامل کیے گئے',
      'customer_details': 'گاہک کی تفصیلات',
      'entries': 'اندراجات',
      'you_gave': 'آپ نے دیے',
      'you_got': 'آپ کو ملے',
      'hide_balance': 'بیلنس چھپائیں',
      'show_balance': 'بیلنس دکھائیں',
      'total': 'کل',
      'save': 'محفوظ کریں',
      'cancel': 'منسوخ کریں',
      'delete': 'حذف کریں',
      'edit': 'ترمیم کریں',
      'share': 'شیئر کریں',
      'pdf': 'پی ڈی ایف',
      'phone_number': 'فون نمبر',
      'address': 'پتہ',
      'city': 'شہر',
      'cnic': 'شناختی کارڈ',
      'notes': 'نوٹس',
      'item_category': 'آئٹم کیٹیگری',
      'cash': 'کیش',
      'bank': 'بینک',
      'online': 'آن لائن',
      'update_customer': 'گاہک اپ ڈیٹ کریں',
      'add_new_customer': 'نیا گاہک شامل کریں',
      'customer_name': 'گاہک کا نام *',
      'settings': 'ترتیبات',
      'choose_language': 'زبان کا انتخاب کریں',
      'english': 'English',
      'urdu': 'اردو (Urdu)',
      'new_customer': 'نیا گاہک',
      'save_customer': 'گاہک محفوظ کریں',
      'delete_customer': 'گاہک حذف کریں',
      'delete_customer_msg': 'کیا آپ واقعی اس گاہک کو حذف کرنا چاہتے ہیں؟',
      'close': 'بند کریں',
      'amount': 'رقم',
      'date': 'تاریخ',
      'add_transaction': 'لین دین شامل کریں',
      'update_transaction': 'لین دین اپ ڈیٹ کریں',
      'transaction_type': 'لین دین کی قسم؟',
      'which_goods': 'کون سا مال؟',
      'weight': 'وزن',
      'today': 'آج',
      'transaction_saved': 'لین دین کامیابی سے محفوظ ہو گیا',
      'select_date': 'تاریخ منتخب کریں',
      'purchased_goods': 'مال خریدا',
      'sold_goods': 'مال بیچا',
      'cash_given': 'کیش دیا',
      'cash_received': 'کیش لیا',
      'rice': 'چاول',
      'scrap': 'اسکریپ',
      'other': 'دیگر',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ur'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
