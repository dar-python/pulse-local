import 'package:shared_preferences/shared_preferences.dart';

class DemoAccount {
  DemoAccount._();

  static const _defaultUsername = 'user';
  static const _defaultEmail = 'user@foodpulse.local';
  static const _defaultContactNumber = '09175550148';
  static const _defaultPassword = 'pass';
  static const maxUsernameLength = 25;
  static const maxPasswordLength = 15;
  static const maxContactNumberLength = 11;
  static const _usernameKey = 'demo_account_username';
  static const _emailKey = 'demo_account_email';
  static const _contactNumberKey = 'demo_account_contact_number';
  static const _passwordKey = 'demo_account_password';

  static final usernamePattern = RegExp(r'^[A-Za-z0-9._-]+$');
  static final passwordPattern = RegExp(r'^[A-Za-z0-9!@#$%^&*._-]+$');
  static final contactNumberPattern = RegExp(r'^[0-9]+$');

  static String username = _defaultUsername;
  static String email = _defaultEmail;
  static String contactNumber = _defaultContactNumber;
  static String password = _defaultPassword;

  static bool get hasAccount => username.isNotEmpty && password.isNotEmpty;

  static bool canLogin({required String username, required String password}) {
    return username == DemoAccount.username && password == DemoAccount.password;
  }

  static void updateFromApi({
    required String username,
    required String email,
    required String contactNumber,
    required String password,
  }) {
    DemoAccount.username = username;
    DemoAccount.email = email;
    DemoAccount.contactNumber = contactNumber;
    DemoAccount.password = password;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    username = prefs.getString(_usernameKey) ?? _defaultUsername;
    email = prefs.getString(_emailKey) ?? _defaultEmail;
    contactNumber = prefs.getString(_contactNumberKey) ?? _defaultContactNumber;
    password = prefs.getString(_passwordKey) ?? _defaultPassword;
  }

  static Future<void> register({
    required String username,
    required String email,
    required String contactNumber,
    required String password,
  }) async {
    DemoAccount.username = username;
    DemoAccount.email = email;
    DemoAccount.contactNumber = contactNumber;
    DemoAccount.password = password;

    await save();
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_usernameKey, username);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_contactNumberKey, contactNumber);
    await prefs.setString(_passwordKey, password);
  }

  static Future<void> reset() async {
    username = _defaultUsername;
    email = _defaultEmail;
    contactNumber = _defaultContactNumber;
    password = _defaultPassword;

    await save();
  }
}
