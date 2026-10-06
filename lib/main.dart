import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =====================================================================
//  CẤU HÌNH QUÁN
// =====================================================================
class AppConfig {
  static const String brandName = 'Quán Nhà F&B';
  static const String supabaseUrl = 'https://rfycpsgotkszgwhdxcpg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_QxcnrYLgcAkGnHBwIEh4bg_7MIHnvqL';
  static const String bankBin = '970422'; // MB Bank
  static const String bankAccount = '0944504696';
  static const String bankName = 'MB Bank';
  static const String fallbackSiteUrl = 'https://lhieu0896-lab.github.io/coffee-web/';
  static const int tableCount = 20;
  // Logo quán: để trống = dùng logo chữ mặc định.
  // Muốn dùng logo thật: chép file logo.png vào thư mục web/ của project rồi đặt 'logo.png'
  static const String logoUrl = 'logo.png';
  static const List<String> defaultCategories = [
    'Cà Phê Truyền Thống & Ý',
    'Trà Trái Cây & Nước Ép Tươi',
    'Trà Sữa & Đá Xay',
  ];
}

String? supabaseInitError;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  } catch (e) {
    supabaseInitError = e.toString();
    debugPrint('Supabase init error: $e');
  }
  runApp(const CoffeeShopApp());
}

SupabaseClient get db => Supabase.instance.client;

class AppColors {
  static const Color background = Color(0xFFF9F8F6);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF261C14);
  static const Color accent = Color(0xFFC06C3E);
  static const Color accentLight = Color(0xFFF6EDE7);
  static const Color textMain = Color(0xFF1F1E1D);
  static const Color textMuted = Color(0xFF7A7571);
  static const Color border = Color(0xFFEBE7E1);
  static const Color baristaGreen = Color(0xFF537351);
  static const Color danger = Color(0xFFB3261E);
}

// =====================================================================
//  HÀM TIỆN ÍCH
// =====================================================================
String formatMoney(num amount) {
  final v = amount.round();
  final s = v.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return v < 0 ? '-$s' : s;
}

int toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

String two(int n) => n.toString().padLeft(2, '0');
String fmtTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
DateTime? parseLocal(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
String nowUtcIso() => DateTime.now().toUtc().toIso8601String();

String friendlyError(Object e) {
  final raw = e.toString();
  if (raw.contains('Failed to fetch') ||
      raw.contains('ClientException') ||
      raw.contains('SocketException') ||
      raw.contains('XMLHttpRequest') ||
      raw.contains('LateInitializationError') ||
      raw.contains('initialize')) {
    return 'Không kết nối được máy chủ. Kiểm tra mạng, hoặc project Supabase có đang bị tạm dừng (paused) không.';
  }
  if (e is AuthException) {
    if (e.message.contains('Invalid login credentials')) return 'Sai email hoặc mật khẩu.';
    return e.message;
  }
  if (e is PostgrestException) {
    if (e.code == '42501') return 'Bạn không có quyền thực hiện thao tác này.';
    return e.message;
  }
  return raw;
}

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(backgroundColor: error ? AppColors.danger : AppColors.primary, content: Text(msg)),
  );
}

InputDecoration inputDeco([String? hint]) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    );

Widget fieldLabel(String t) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );

Widget numberField(TextEditingController c, [String? hint]) => TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: inputDeco(hint),
    );

Future<bool> confirmDialog(BuildContext context, {required String title, required String message, String okLabel = 'Đồng ý', bool danger = false}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      content: Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: danger ? AppColors.danger : AppColors.primary, foregroundColor: Colors.white, elevation: 0),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return res == true;
}

Widget errorBanner(String message, {VoidCallback? onRetry}) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF5C2BE))),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.danger, height: 1.3))),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );

// =====================================================================
//  MÔ HÌNH DỮ LIỆU
// =====================================================================
class MenuItem {
  final String id;
  final String name;
  final String category;
  final int priceM;
  final int priceL;
  final int costM;
  final int costL;
  final String imageUrl;
  final bool available;
  final int sortOrder;
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.priceM,
    required this.priceL,
    required this.costM,
    required this.costL,
    required this.imageUrl,
    this.available = true,
    this.sortOrder = 0,
  });
  factory MenuItem.fromDb(Map<String, dynamic> m) => MenuItem(
        id: m['id'].toString(),
        name: m['name']?.toString() ?? '',
        category: m['category']?.toString() ?? '',
        priceM: toInt(m['price_m']),
        priceL: toInt(m['price_l']),
        costM: toInt(m['cost_m']),
        costL: toInt(m['cost_l']),
        imageUrl: m['image_url']?.toString() ?? '',
        available: m['available'] != false,
        sortOrder: toInt(m['sort_order']),
      );
  Map<String, dynamic> toDb() => {
        'id': id,
        'name': name,
        'category': category,
        'price_m': priceM,
        'price_l': priceL,
        'cost_m': costM,
        'cost_l': costL,
        'image_url': imageUrl,
        'available': available,
        'sort_order': sortOrder,
      };
}

class Topping {
  final String id;
  final String name;
  final int price;
  final int cost;
  final bool available;
  final int sortOrder;
  const Topping({required this.id, required this.name, required this.price, required this.cost, this.available = true, this.sortOrder = 0});
  factory Topping.fromDb(Map<String, dynamic> m) => Topping(
        id: m['id'].toString(),
        name: m['name']?.toString() ?? '',
        price: toInt(m['price']),
        cost: toInt(m['cost']),
        available: m['available'] != false,
        sortOrder: toInt(m['sort_order']),
      );
}

class CartItem {
  final MenuItem item;
  final String size;
  final int sugar;
  final int ice;
  final String strength;
  final List<Topping> toppings;
  final String note;
  int quantity;
  CartItem({
    required this.item,
    required this.size,
    required this.sugar,
    required this.ice,
    required this.strength,
    required this.toppings,
    required this.note,
    this.quantity = 1,
  });
  int get unitPrice => (size == 'L' ? item.priceL : item.priceM) + toppings.fold<int>(0, (s, t) => s + t.price);
  int get lineTotal => unitPrice * quantity;
  Map<String, dynamic> toPayload() => {
        'item_id': item.id,
        'size': size,
        'sugar': sugar,
        'ice': ice,
        'strength': strength,
        'toppings': toppings.map((t) => t.id).toList(),
        'note': note,
        'quantity': quantity,
      };
}

List<MenuItem> sortMenu(List<MenuItem> list) {
  list.sort((a, b) {
    final c = a.sortOrder.compareTo(b.sortOrder);
    return c != 0 ? c : a.name.compareTo(b.name);
  });
  return list;
}

// Lưu đơn vừa đặt trên máy khách để xem lại trạng thái (hết hạn sau 6 tiếng)
class OrderHistory {
  static const _kId = 'last_order_id_v2';
  static const _kAt = 'last_order_at_v2';
  static Future<void> save(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kId, id);
    await p.setInt(_kAt, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<String?> lastOrderId() async {
    final p = await SharedPreferences.getInstance();
    final at = p.getInt(_kAt) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - at > 6 * 3600 * 1000) return null;
    return p.getString(_kId);
  }
}

// =====================================================================
//  ĐĂNG NHẬP NHÂN VIÊN (Supabase Auth)
// =====================================================================
class AuthService {
  static String? role; // 'admin' | 'barista'
  static User? get user {
    try {
      return db.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> loadRole() async {
    final u = user;
    if (u == null) {
      role = null;
      return null;
    }
    final res = await db.from('staff_accounts').select('role').eq('user_id', u.id).maybeSingle();
    role = res?['role']?.toString();
    return role;
  }

  static Future<void> signOut() async {
    try {
      await db.auth.signOut();
    } catch (_) {}
    role = null;
  }
}

Future<void> openStaffArea(BuildContext context, {required bool adminOnly}) async {
  String? role;
  if (AuthService.user != null) {
    try {
      role = await AuthService.loadRole();
    } catch (_) {}
  }
  if (role == null) {
    if (!context.mounted) return;
    role = await showDialog<String>(context: context, builder: (_) => const StaffLoginDialog());
  }
  if (role == null || !context.mounted) return;
  if (adminOnly && role != 'admin') {
    showSnack(context, 'Tài khoản này chỉ có quyền Quầy bar, không vào được phần Quản lý.', error: true);
    return;
  }
  await Navigator.push(context, MaterialPageRoute(builder: (_) => adminOnly ? const AdminDashboardScreen() : const BaristaScreen()));
}

class StaffLoginDialog extends StatefulWidget {
  const StaffLoginDialog({super.key});
  @override
  State<StaffLoginDialog> createState() => _StaffLoginDialogState();
}

class _StaffLoginDialogState extends State<StaffLoginDialog> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Nhập đủ email và mật khẩu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await db.auth.signInWithPassword(email: _email.text.trim(), password: _pass.text);
      final role = await AuthService.loadRole();
      if (role == null) {
        await AuthService.signOut();
        setState(() {
          _busy = false;
          _error = 'Tài khoản chưa được cấp quyền nhân viên.';
        });
        return;
      }
      if (mounted) Navigator.pop(context, role);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Đăng nhập nhân viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fieldLabel('Email'),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofocus: true, decoration: inputDeco('email@quan.vn')),
            fieldLabel('Mật khẩu'),
            TextField(
              controller: _pass,
              obscureText: !_show,
              decoration: inputDeco('••••••').copyWith(
                suffixIcon: IconButton(icon: Icon(_show ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: () => setState(() => _show = !_show)),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            const Text('Đăng nhập được trên nhiều thiết bị cùng lúc (điện thoại, máy tính bảng, máy tính). Phiên được ghi nhớ trên máy này.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Đăng nhập'),
        ),
      ],
    );
  }
}

// =====================================================================
//  CÔNG THỨC PHA CHẾ — tra theo MÃ MÓN (không đoán theo tên nữa)
// =====================================================================
class RecipeEngine {
  static List<Map<String, String>> calculate({
    required String itemId,
    required String size,
    required int sugarPercent,
    required int icePercent,
    required String strength,
  }) {
    final isL = size.toUpperCase() == 'L';
    final sugar = (sugarPercent / 100.0).clamp(0.0, 1.5);
    final ice = (icePercent / 100.0).clamp(0.0, 1.5);
    final strong = strength == 'Đậm vị';
    final noIce = icePercent == 0;
    final boost = 1.0 + (strong ? 0.2 : 0.0) + (noIce ? 0.2 : 0.0);
    final shots = (isL ? 2 : 1) + (strong ? 1 : 0);
    double s(double m, double l) => isL ? l : m;
    Map<String, String> r(String name, String amount) => {'name': name, 'amount': amount};
    String ml(double v) => '${_fmt(v)} ml';
    String g(double v) => '${_fmt(v)} g';

    switch (itemId) {
      case 'cf_den':
        return [r('Cốt cà phê phin', ml(s(40, 55) * boost)), r('Nước đường', ml(s(20, 30) * sugar)), r('Đá viên', g(s(150, 200) * ice))];
      case 'cf_sua':
        return [r('Cốt cà phê phin', ml(s(40, 60) * boost)), r('Sữa đặc', ml(s(30, 40) * sugar)), r('Đá viên', g(s(150, 200) * ice))];
      case 'cf_muoi':
        return [
          r('Cốt cà phê', ml(s(40, 55) * boost)),
          r('Sữa đặc', ml(s(20, 25) * sugar)),
          r('Kem muối biển', ml(s(45, 65))),
          r('Đá viên', g(s(120, 160) * ice)),
        ];
      case 'cf_espresso':
        return [
          r('Espresso shot', '$shots shot (${shots * 30} ml)'),
          r('Nước lọc', ml(s(120, 180) * (noIce ? 1.2 : 1.0))),
          r('Đá viên', g(s(150, 200) * ice)),
        ];
      case 'cf_cappuccino':
        return [r('Espresso shot', '$shots shot (${shots * 30} ml)'), r('Sữa tươi đánh bọt', ml(s(170, 240)))];
      case 'tra_dao':
        return [
          r('Cốt trà Oolong/Đen', ml(s(100, 130) * boost)),
          r('Siro đào & đường', ml(s(35, 50) * sugar)),
          r('Nước cam & sả tươi', ml(s(35, 55))),
          r('Đào ngâm miếng', '${isL ? 3 : 2} miếng'),
          r('Đá viên', g(s(150, 180) * ice)),
        ];
      case 'tra_vai':
        return [
          r('Cốt trà lài', ml(s(100, 140) * boost)),
          r('Siro & nước vải', ml(s(45, 65) * sugar)),
          r('Quả vải ngâm', '${isL ? 4 : 3} quả'),
          r('Đá viên', g(s(150, 190) * ice)),
        ];
      case 'tra_sua_thai':
        return [
          r('Trà sữa Thái nền', ml(s(160, 210) * boost)),
          r('Nước đường nấu', ml(s(20, 30) * sugar)),
          r('Thạch Thái xanh', g(s(50, 80))),
          r('Đá viên', g(s(200, 280) * ice)),
        ];
      case 'tra_sua_tc':
        return [
          r('Trà sữa nền', ml(s(175, 210) * boost)),
          r('Đường đen Hàn Quốc', ml(s(15, 25) * sugar)),
          r('Trân châu đường đen', g(s(60, 95))),
          r('Đá viên', g(s(200, 260) * ice)),
        ];
      case 'matcha_latte':
        return [
          r('Matcha cốt nước ấm', g(s(33, 45) * (strong ? 1.3 : 1.0))),
          r('Sữa tươi thanh trùng', ml(s(100, 140))),
          r('Sữa đặc / đường', ml(s(20, 30) * sugar)),
          r('Đá viên', g(s(150, 200) * ice)),
        ];
      case 'ep_thom':
        return [
          r('Cốt nước thơm tươi', ml(s(130, 200) * (noIce ? 1.2 : 1.0))),
          r('Nước đường / mật ong', ml(s(10, 20) * sugar)),
          r('Muối tinh', '0.2 g'),
          r('Đá viên', g(s(110, 180) * ice)),
        ];
      case 'ep_cam':
        return [
          r('Cốt cam tươi', ml(s(150, 200) * (noIce ? 1.2 : 1.0))),
          r('Nước đường pha sẵn', ml(s(30, 40) * sugar)),
          r('Cốt tắc thơm', ml(s(2, 5))),
          r('Đá viên', g(s(200, 280) * ice)),
        ];
      case 'st_bo':
      case 'st_dau':
        return [
          r(itemId == 'st_bo' ? 'Bơ tươi' : 'Dâu tươi', g(s(100, 140))),
          r('Sữa đặc', ml(s(40, 55) * sugar)),
          r('Sữa tươi', ml(s(40, 60))),
          r('Đá bào xay nhuyễn', g(s(180, 230) * ice)),
        ];
      case 'dx_cookie':
        return [
          r('Bánh Oreo', '${_fmt(s(35, 50))} g (~${isL ? '5' : '3.5'} bánh)'),
          r('Sữa tươi + đặc + bột Frappe', g(s(95, 130) * sugar)),
          r('Whipping Cream phủ mặt', g(s(30, 45))),
          r('Đá viên xay', g(s(180, 230) * ice)),
        ];
      case 'sc_vietquat':
        // TODO: chủ quán kiểm tra lại định lượng món này
        return [
          r('Sữa chua', g(s(100, 140))),
          r('Mứt việt quất', ml(s(30, 45) * sugar)),
          r('Sữa tươi', ml(s(40, 60))),
          r('Đá viên xay', g(s(150, 200) * ice)),
        ];
    }
    return [
      r('Cốt nguyên liệu chính', ml(s(130, 180) * boost)),
      r('Đường / Sữa ngọt', ml(s(20, 30) * sugar)),
      r('Đá viên', g(s(150, 200) * ice)),
      r('Lưu ý', 'Món mới — chưa có công thức riêng'),
    ];
  }

  static String _fmt(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }
}

// =====================================================================
//  APP
// =====================================================================
class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.brandName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary),
      ),
      // Tăng cỡ chữ toàn app thêm 10% cho dễ đọc
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: const TextScaler.linear(1.1)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const RoleSelectionScreen(),
    );
  }
}

// =====================================================================
//  WIDGET DÙNG CHUNG: đồng hồ, nền, logo, hóa đơn
// =====================================================================
const List<String> _weekdaysShort = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];

/// Đồng hồ kiểu màn hình khóa / StandBy iPhone: số to, đậm, cam, nền tối.
/// size = cỡ chữ số (nhỏ cho thanh tiêu đề, to cho màn hình chính).
class LiveClock extends StatefulWidget {
  final bool showDate;
  final double size;
  final Color color; // giữ để tương thích, không còn dùng
  const LiveClock({super.key, this.showDate = true, this.size = 34, this.color = AppColors.primary});
  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final digits = GoogleFonts.antonio(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.0,
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final date = '${_weekdaysShort[_now.weekday - 1]} ${_now.day} thg ${_now.month}';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.42, vertical: size * 0.16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF221812), Color(0xFF0F0A07)]),
        borderRadius: BorderRadius.circular(size * 0.36),
        border: Border.all(color: const Color(0x40FF7A1A)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showDate)
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.06),
              child: Text(
                date,
                style: GoogleFonts.inter(fontSize: math.max(10, size * 0.19), fontWeight: FontWeight.w600, color: const Color(0xFFFFB27A), letterSpacing: -0.2),
              ),
            ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF9A3D), Color(0xFFFF5A0F)],
            ).createShader(r),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(two(_now.hour), style: digits),
                AnimatedOpacity(
                  opacity: _now.second.isEven ? 1 : 0.35,
                  duration: const Duration(milliseconds: 300),
                  child: Text(':', style: digits),
                ),
                Text(two(_now.minute), style: digits),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nền kem ấm + họa tiết hạt cà phê mờ
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFCF7F1), Color(0xFFF5E9DC), Color(0xFFEFDFCD)],
              ),
            ),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _BeanPatternPainter())))),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _BeanPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final fill = Paint()..color = const Color(0xFF8B5E3C).withAlpha(16);
    final line = Paint()
      ..color = const Color(0xFF8B5E3C).withAlpha(26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const step = 96.0;
    int row = 0;
    for (double y = 0; y < size.height + step; y += step, row++) {
      for (double x = row.isOdd ? step / 2 : 0; x < size.width + step; x += step) {
        canvas.save();
        canvas.translate(x + rnd.nextDouble() * 24, y + rnd.nextDouble() * 24);
        canvas.rotate(rnd.nextDouble() * math.pi);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 22, height: 14), fill);
        final p = Path()
          ..moveTo(-9, 0)
          ..quadraticBezierTo(0, -4, 9, 0);
        canvas.drawPath(p, line);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo nhỏ đặt lên ảnh món / hóa đơn. Đặt AppConfig.logoUrl để dùng logo thật.
class BrandBadge extends StatelessWidget {
  final double size;
  const BrandBadge({super.key, this.size = 30});

  Widget _fallback() => Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.28, vertical: size * 0.13),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(235),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.coffee, size: size * 0.45, color: AppColors.accent),
            const SizedBox(width: 4),
            Text('QUÁN NHÀ', style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (AppConfig.logoUrl.isEmpty) return _fallback();
    // Logo quán giữ nguyên dáng (có ly cà phê nhô lên), nền trong suốt
    final px = size * 1.25;
    return SizedBox(
      width: px,
      height: px,
      child: Image.network(AppConfig.logoUrl, fit: BoxFit.contain, filterQuality: FilterQuality.high, errorBuilder: (_, __, ___) => _fallback()),
    );
  }
}

Widget bigLogo([double size = 96]) {
  if (AppConfig.logoUrl.isEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Icon(Icons.coffee, size: size * 0.46, color: AppColors.accent),
    );
  }
  return SizedBox(
    width: size,
    height: size,
    child: Image.network(
      AppConfig.logoUrl,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(Icons.coffee, size: size * 0.46, color: AppColors.accent),
    ),
  );
}

Widget noteBox(String text, {Color color = const Color(0xFFB26A00), IconData icon = Icons.info_outline}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withAlpha(22), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withAlpha(90))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600, height: 1.35))),
        ],
      ),
    );

List<Map<String, dynamic>> orderItemsOf(Map<String, dynamic> o) {
  final raw = o['items'] ?? o['order_items'];
  if (raw is! List) return [];
  return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

String toppingNames(dynamic t) =>
    t is List ? t.map((x) => x is Map ? (x['name']?.toString() ?? '') : x.toString()).where((s) => s.isNotEmpty).join(', ') : '';

bool isPaid(Map<String, dynamic> o) => o['paid_at'] != null;

String paymentLabel(Map<String, dynamic> o) => o['payment_method'] == 'cash' ? '💵 Tiền mặt' : '💳 Chuyển khoản';

class BillView extends StatelessWidget {
  final Map<String, dynamic> order;
  const BillView({super.key, required this.order});

  Widget _row(String a, String b) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            Text(b, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final items = orderItemsOf(order);
    final created = parseLocal(order['created_at']);
    final paid = isPaid(order);
    final cash = order['payment_method'] == 'cash';
    final status = order['status']?.toString() ?? '';
    final discount = toInt(order['discount']);
    final total = toInt(order['total']);
    final subtotal = toInt(order['subtotal'], total + discount);
    String stamp;
    Color stampColor;
    if (status == 'cancelled') {
      stamp = 'ĐÃ HỦY';
      stampColor = AppColors.danger;
    } else if (paid) {
      stamp = cash ? 'ĐÃ THU TIỀN MẶT' : 'ĐÃ THANH TOÁN CHUYỂN KHOẢN';
      stampColor = AppColors.baristaGreen;
    } else if (cash) {
      stamp = 'THANH TOÁN TIỀN MẶT TẠI QUẦY';
      stampColor = const Color(0xFFB26A00);
    } else {
      stamp = 'CHỜ CHUYỂN KHOẢN';
      stampColor = const Color(0xFFB26A00);
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(child: BrandBadge(size: 40)),
          const SizedBox(height: 8),
          const Text('HÓA ĐƠN', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.primary)),
          const Text(AppConfig.brandName, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
          const SizedBox(height: 6),
          Text('Mã đơn #${order['code']}  •  Bàn ${order['table_number']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(
            '${created != null ? '${fmtTime(created)}  ${fmtDate(created)}' : ''}  •  ${paymentLabel(order)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const Divider(height: 24),
          ...items.map((it) {
            final qty = toInt(it['quantity'], 1);
            final unit = toInt(it['unit_price']);
            final tops = toppingNames(it['toppings']);
            final note = it['note']?.toString() ?? '';
            final details = [
              'Size ${it['size'] ?? 'M'}',
              'Đường ${toInt(it['sugar'], 100)}%',
              'Đá ${toInt(it['ice'], 100)}%',
              if (tops.isNotEmpty) tops,
              if (note.isNotEmpty) 'Ghi chú: $note',
            ].join(' • ');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$qty × ${it['item_name']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(details, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${formatMoney(unit * qty)}đ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          _row('Tạm tính', '${formatMoney(subtotal)}đ'),
          if (discount > 0) _row('Giảm giá${order['voucher_code'] != null ? ' (${order['voucher_code']})' : ''}', '-${formatMoney(discount)}đ'),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TỔNG CỘNG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              Text('${formatMoney(total)}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Transform.rotate(
              angle: -0.03,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: stampColor, width: 2), borderRadius: BorderRadius.circular(8)),
                child: Text(stamp, textAlign: TextAlign.center, style: TextStyle(color: stampColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showBillDialog(BuildContext context, Map<String, dynamic> order) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BillView(order: order),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// =====================================================================
//  MÀN HÌNH CHỌN VAI TRÒ
// =====================================================================
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _checkedUrl = false;
  String? _lastOrderId;
  String? _staffEmail;

  @override
  void initState() {
    super.initState();
    _loadLastOrder();
    _refreshSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_checkedUrl) return;
      _checkedUrl = true;
      final n = int.tryParse(Uri.base.queryParameters['table'] ?? '');
      if (n != null && n >= 1 && n <= AppConfig.tableCount && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerMenuScreen(initialTable: two(n)))).then((_) => _loadLastOrder());
      }
    });
  }

  Future<void> _loadLastOrder() async {
    final id = await OrderHistory.lastOrderId();
    if (mounted) setState(() => _lastOrderId = id);
  }

  /// Phiên đăng nhập nhân viên được lưu lại trên mỗi thiết bị (điện thoại, máy tính bảng, máy tính)
  Future<void> _refreshSession() async {
    final u = AuthService.user;
    if (u == null) {
      if (mounted) setState(() => _staffEmail = null);
      return;
    }
    try {
      await AuthService.loadRole();
    } catch (_) {}
    if (mounted) setState(() => _staffEmail = AuthService.role == null ? null : u.email);
  }

  Future<void> _goStaff(bool adminOnly) async {
    await openStaffArea(context, adminOnly: adminOnly);
    _refreshSession();
  }

  /// Nút nhỏ trên taskbar — ẩn hẳn khu vực Quầy pha chế / Quản lý khỏi màn hình chính,
  /// chỉ còn 1 nút cho khách gọi món. Nhân viên/chủ quán bấm icon này để vào.
  Future<void> _openStaffMenu() async {
    if (_staffEmail == null) {
      final role = await showDialog<String>(context: context, builder: (_) => const StaffLoginDialog());
      if (role == null || !mounted) return;
      await _refreshSession();
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => role == 'admin' ? const AdminDashboardScreen() : const BaristaScreen()));
      _refreshSession();
      return;
    }
    final isAdmin = AuthService.role == 'admin';
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.textMuted),
              title: Text(_staffEmail!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text(isAdmin ? 'Quyền: Quản lý' : 'Quyền: Quầy bar', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.coffee_maker_outlined, color: AppColors.baristaGreen),
              title: const Text('Vào quầy nhận đơn', style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, 'barista'),
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.query_stats_outlined, color: AppColors.primary),
                title: const Text('Vào quản lý', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, 'admin'),
              ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
              onTap: () => Navigator.pop(ctx, 'logout'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'barista') {
      await _goStaff(false);
    } else if (choice == 'admin') {
      await _goStaff(true);
    } else if (choice == 'logout') {
      await AuthService.signOut();
      _refreshSession();
    }
  }

  void _selectTable() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Chọn số bàn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(AppConfig.tableCount, (i) {
                final t = two(i + 1);
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerMenuScreen(initialTable: t))).then((_) => _loadLastOrder());
                  },
                  child: Container(
                    width: 80,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accent.withAlpha(90)),
                    ),
                    child: Center(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary))),
                  ),
                );
              }),
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng', style: TextStyle(color: AppColors.textMuted)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 800) {
                return _buildDesktopBentoLayout(context);
              }
              return _buildMobileLayout(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  const Center(child: LiveClock(size: 92)),
                  const SizedBox(height: 16),
                  if (supabaseInitError != null) errorBanner('Không khởi tạo được kết nối máy chủ. Hãy tải lại trang.'),
                  bigLogo(170),
                  const SizedBox(height: 18),
                  const Text(AppConfig.brandName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  const Text('Gọi món tại bàn • Thanh toán nhanh', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  const SizedBox(height: 28),
                  _roleCard(title: 'Khách Hàng (Gọi Món)', sub: 'Chọn số bàn & thực đơn thức uống', icon: Icons.storefront_outlined, onTap: _selectTable, highlight: true),
                  if (_lastOrderId != null) ...[
                    const SizedBox(height: 12),
                    _roleCard(
                      title: 'Xem đơn & hóa đơn vừa đặt',
                      sub: 'Theo dõi trạng thái món của bạn',
                      icon: Icons.receipt_long_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: _lastOrderId!))),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Thanh taskbar nhỏ góc trên — chỗ duy nhất để nhân viên/chủ quán vào Quầy pha chế & Quản lý.
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.white.withAlpha(160),
            shape: const CircleBorder(),
            child: IconButton(
              icon: Icon(_staffEmail != null ? Icons.verified_user_outlined : Icons.lock_outline, size: 20, color: AppColors.textMuted),
              tooltip: 'Nhân viên / Quản lý',
              onPressed: _openStaffMenu,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopBentoLayout(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── LEFT 70%: Brand showcase (clean, no overlays) ──
              Expanded(
                flex: 7,
                child: _bentoCard(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      // Brand center
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (supabaseInitError != null) ...[
                              errorBanner('Không kết nối được máy chủ.'),
                              const SizedBox(height: 12),
                            ],
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF261810),
                                border: Border.all(color: AppColors.accent, width: 3),
                                boxShadow: [BoxShadow(color: AppColors.accent.withAlpha(70), blurRadius: 28, spreadRadius: 3)],
                              ),
                              child: ClipOval(child: bigLogo(130)),
                            ),
                            const SizedBox(height: 22),
                            const Text(AppConfig.brandName, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.8)),
                            const SizedBox(height: 8),
                            Text('Gọi món tại bàn  ·  Thanh toán nhanh', style: TextStyle(color: AppColors.textMuted.withAlpha(180), fontSize: 13)),
                            const SizedBox(height: 28),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _statCell('20+', 'Thức uống'),
                                    VerticalDivider(width: 1, color: AppColors.border),
                                    _statCell('${AppConfig.tableCount}', 'Bàn phục vụ'),
                                    VerticalDivider(width: 1, color: AppColors.border),
                                    _statCell('QR', 'Thanh toán'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Greeting — góc dưới trái
                      Positioned(
                        bottom: 0, left: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Xin chào 👋', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            const Text('Bạn muốn làm gì hôm nay?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // ── RIGHT 30%: Action sidebar (clock + status + actions) ──
              Expanded(
                flex: 3,
                child: _bentoCard(
                  color: const Color(0xFF1C0E05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clock pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(120),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha(18)),
                        ),
                        child: const LiveClock(size: 32),
                      ),
                      const SizedBox(height: 10),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white.withAlpha(20)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF5CB85C), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Quán đang mở', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(180))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('LỰA CHỌN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(90), letterSpacing: 1.6)),
                      const SizedBox(height: 6),
                      const Text('Chọn vai\ncủa bạn', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.25, letterSpacing: -0.3)),
                      const SizedBox(height: 20),
                      Text('VAI TRÒ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(90), letterSpacing: 1.6)),
                      const SizedBox(height: 10),
                      _roleCard(
                        title: 'Khách Hàng (Gọi Món)',
                        sub: 'Chọn số bàn & thực đơn',
                        icon: Icons.storefront_outlined,
                        onTap: _selectTable,
                        highlight: true,
                      ),
                      if (_lastOrderId != null) ...[
                        const SizedBox(height: 8),
                        _roleCard(
                          title: 'Xem đơn & hóa đơn',
                          sub: 'Theo dõi trạng thái món',
                          icon: Icons.receipt_long_outlined,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: _lastOrderId!))),
                        ),
                      ],
                      const Spacer(),
                      Divider(color: Colors.white.withAlpha(20), height: 24),
                      Row(
                        children: [
                          Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF5CB85C), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('Quán đang mở cửa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(160))),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('07:00 – 22:00 · Hàng ngày', style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(80))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Nút nhân viên ẩn góc trên phải
        Positioned(
          top: 4,
          right: 4,
          child: Opacity(
            opacity: 0.3,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(_staffEmail != null ? Icons.verified_user_outlined : Icons.lock_outline, size: 18, color: AppColors.textMuted),
                tooltip: 'Nhân viên / Quản lý',
                onPressed: _openStaffMenu,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bentoCard({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF261C14).withAlpha(18), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _statCell(String val, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.accent)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({required String title, required String sub, required IconData icon, String? badge, required VoidCallback onTap, bool highlight = false}) {
    return Material(
      color: highlight ? AppColors.primary : Colors.white,
      elevation: highlight ? 6 : 2,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: highlight ? Colors.white.withAlpha(30) : AppColors.accentLight, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: highlight ? Colors.white : AppColors.accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: highlight ? Colors.white : AppColors.textMain)),
                    const SizedBox(height: 3),
                    Text(sub, style: TextStyle(color: highlight ? Colors.white70 : AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                  child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                ),
              Icon(Icons.arrow_forward_ios, color: highlight ? Colors.white70 : const Color(0xFFC5C0BA), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  KHÁCH: MENU
// =====================================================================
class CustomerMenuScreen extends StatefulWidget {
  final String initialTable;
  const CustomerMenuScreen({super.key, this.initialTable = '01'});
  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  final List<CartItem> _cart = [];
  late String _table;
  List<MenuItem> _menu = [];
  List<Topping> _toppings = [];
  bool _loading = true;
  String? _error;
  String? _lastOrderId;

  int get _cartCount => _cart.fold<int>(0, (s, c) => s + c.quantity);
  int get _cartTotal => _cart.fold<int>(0, (s, c) => s + c.lineTotal);

  @override
  void initState() {
    super.initState();
    _table = widget.initialTable;
    _load();
    OrderHistory.lastOrderId().then((id) {
      if (mounted) setState(() => _lastOrderId = id);
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final m = await db.from('menu_items').select().eq('available', true);
      final t = await db.from('toppings').select().eq('available', true).order('sort_order', ascending: true);
      if (!mounted) return;
      setState(() {
        _menu = sortMenu(m.map((e) => MenuItem.fromDb(e)).toList());
        _toppings = t.map((e) => Topping.fromDb(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _menu.map((e) => e.category).toSet().toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 62,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppColors.border, height: 1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const BrandBadge(size: 32),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _table,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent, size: 18),
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 14),
                  items: List.generate(
                    AppConfig.tableCount,
                    (i) => DropdownMenuItem(value: two(i + 1), child: Text('Bàn ${two(i + 1)}', style: const TextStyle(color: AppColors.textMain))),
                  ),
                  onChanged: (v) {
                    if (v != null) setState(() => _table = v);
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_lastOrderId != null)
            IconButton(
              tooltip: 'Đơn & hóa đơn vừa đặt',
              icon: const Icon(Icons.receipt_long_outlined, color: AppColors.textMain),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: _lastOrderId!))),
            ),
          IconButton(
            icon: Badge(
              backgroundColor: AppColors.accent,
              isLabelVisible: _cart.isNotEmpty,
              label: Text('$_cartCount', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.textMain, size: 26),
            ),
            onPressed: _openCartSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        child: Stack(
          children: [
            _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(20), child: errorBanner(_error!, onRetry: _load)))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _welcomeHeader(),
                                  if (_menu.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Center(child: Text('Menu đang được cập nhật, vui lòng quay lại sau.', style: TextStyle(color: AppColors.textMuted))),
                                    ),
                                  ...categories.map((cat) {
                                    final items = _menu.where((i) => i.category == cat).toList();
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _categoryHeader(cat, items.length),
                                        LayoutBuilder(builder: (context, constraints) {
                                          final crossCount = (constraints.maxWidth / 200).floor().clamp(2, 6);
                                          return GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: crossCount,
                                              childAspectRatio: 0.70,
                                              crossAxisSpacing: 14,
                                              mainAxisSpacing: 14,
                                            ),
                                            itemCount: items.length,
                                            itemBuilder: (context, idx) => MenuCard(item: items[idx], onTap: () => _openCustomize(items[idx])),
                                          );
                                        }),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
            if (!_loading && _error == null)
              MascotAssistant(
                menu: _menu,
                table: _table,
                onAddToCart: (c) => setState(() => _cart.add(c)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Badge(
                      backgroundColor: AppColors.accent,
                      label: Text('$_cartCount'),
                      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng cộng', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text('${formatMoney(_cartTotal)}đ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onPressed: _openCartSheet,
                      icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                      label: const Text('Xem giỏ & thanh toán', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _welcomeHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B2A1E), Color(0xFF6B4630)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Xin chào! ☕', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text('Bạn đang ngồi Bàn $_table — chạm vào món để chọn', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const LiveClock(),
        ],
      ),
    );
  }

  Widget _categoryHeader(String cat, int count) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        child: Row(
          children: [
            Container(width: 5, height: 26, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            Flexible(child: Text(cat, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.3))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Text('$count món', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  void _openCustomize(MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => CustomizeItemSheet(
        item: item,
        toppings: _toppings,
        onAdd: (c) {
          setState(() => _cart.add(c));
          showSnack(context, 'Đã thêm ${c.quantity} × ${item.name} vào giỏ!');
        },
      ),
    );
  }

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92, maxWidth: 640),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => CartBottomSheet(
        cart: _cart,
        table: _table,
        onCartChanged: () => setState(() {}),
        onOrderPlaced: _afterOrderPlaced,
      ),
    );
  }

  void _afterOrderPlaced(Map<String, dynamic> res, String payment) {
    final id = res['id'].toString();
    setState(() => _lastOrderId = id);
    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: id)));
  }
}

// =====================================================================
//  LINH VẬT AI "BÔNG" — di chuyển tự do, chat & đặt món giúp khách
// =====================================================================
class _ChatMsg {
  final bool fromUser;
  final String text;
  _ChatMsg(this.fromUser, this.text);
}

class MascotAssistant extends StatefulWidget {
  final List<MenuItem> menu;
  final String table;
  final ValueChanged<CartItem> onAddToCart;
  const MascotAssistant({super.key, required this.menu, required this.table, required this.onAddToCart});
  @override
  State<MascotAssistant> createState() => _MascotAssistantState();
}

class _MascotAssistantState extends State<MascotAssistant> with TickerProviderStateMixin {
  static const double _size = 64;
  double _x = 16, _y = 40;
  bool _open = false;
  bool _busy = false;
  bool _placedInit = false;
  bool _faceRight = true;
  bool _blink = false;
  bool _isMoving = false;
  Timer? _moveTimer;
  Timer? _blinkTimer;
  Timer? _walkStopTimer;
  late AnimationController _bob;
  late AnimationController _tail;
  late AnimationController _walk;
  static const Duration _moveDuration = Duration(milliseconds: 1600);
  final List<_ChatMsg> _messages = [
    _ChatMsg(false, 'Gâu! Mình là Bông 🐶 — chó linh vật của quán. Bạn chưa biết uống gì thì cứ nói mình nghe (ví dụ "muốn gì ngọt mát", "ít đường ít béo"...), mình gợi ý và đặt giúp luôn nha!'),
  ];
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _tail = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    // Chu kỳ bước chân: lặp liên tục, nhưng chỉ "có tác dụng" lên hình vẽ khi _isMoving = true.
    _walk = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))..repeat();
    _moveTimer = Timer.periodic(const Duration(seconds: 6), (_) => _wander());
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 2400 + math.Random().nextInt(2600)), () async {
      if (!mounted) return;
      setState(() => _blink = true);
      await Future.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      setState(() => _blink = false);
      _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _blinkTimer?.cancel();
    _walkStopTimer?.cancel();
    _bob.dispose();
    _tail.dispose();
    _walk.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _wander([Size? bounds]) {
    if (_open || !mounted) return;
    final b = bounds ?? _lastBounds;
    if (b == null || b.width < 120 || b.height < 160) return;
    final rnd = math.Random();
    final newX = 8 + rnd.nextDouble() * (b.width - _size - 16);
    final newY = 8 + rnd.nextDouble() * (b.height - _size - 160);
    final dist = (Offset(newX, newY) - Offset(_x, _y)).distance;
    setState(() {
      _faceRight = newX >= _x;
      _x = newX;
      _y = newY;
      // Chỉ "diễn" dáng đi (chân cử động, người hơi lắc) khi quãng đường di chuyển đủ xa.
      _isMoving = dist > 18;
    });
    _walkStopTimer?.cancel();
    if (_isMoving) {
      _walkStopTimer = Timer(_moveDuration, () {
        if (mounted) setState(() => _isMoving = false);
      });
    }
  }

  Size? _lastBounds;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 120, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _messages.add(_ChatMsg(true, text));
      _busy = true;
    });
    _input.clear();
    _scrollToBottom();
    try {
      final history = _messages
          .sublist(_messages.length > 9 ? _messages.length - 9 : 0, _messages.length - 1)
          .map((m) => {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text})
          .toList();
      final res = await db.functions.invoke('mascot-chat', body: {'message': text, 'history': history, 'table': widget.table});
      final data = res.data;
      if (data is! Map) throw Exception('empty');
      final reply = data['reply']?.toString() ?? 'Mình chưa hiểu lắm, bạn nói lại giúp mình nha 🙏';
      setState(() => _messages.add(_ChatMsg(false, reply)));
      final action = data['action'];
      if (action is Map && action['type'] == 'add_to_cart') {
        final itemId = action['item_id']?.toString();
        final matches = widget.menu.where((m) => m.id == itemId).toList();
        if (matches.isNotEmpty) {
          final size = action['size']?.toString() == 'L' ? 'L' : 'M';
          final qty = toInt(action['quantity'], 1).clamp(1, 20);
          widget.onAddToCart(CartItem(item: matches.first, size: size, sugar: 100, ice: 100, strength: 'Chuẩn vị', toppings: const [], note: 'Bông AI đặt giúp', quantity: qty));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _messages.add(_ChatMsg(false, 'Xin lỗi, mình đang hơi bận, bạn thử lại sau nha 🙏')));
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final b = constraints.biggest;
      _lastBounds = b;
      if (!_placedInit && b.width > 120 && b.height > 160) {
        _placedInit = true;
        _x = b.width - _size - 20;
        _y = b.height - _size - 140;
      }
      return Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeInOut,
            left: _x.clamp(0, math.max(0, b.width - _size)),
            top: _y.clamp(0, math.max(0, b.height - _size)),
            child: GestureDetector(
              onTap: () => setState(() => _open = !_open),
              child: AnimatedBuilder(
                animation: Listenable.merge([_bob, _tail, _walk]),
                builder: (_, __) {
                  // Đứng yên: nhấp nhô thở nhẹ. Đang đi: nảy theo nhịp bước chân (2 nhịp mỗi bước).
                  final bounceY = _isMoving ? -(math.sin(_walk.value * 2 * math.pi).abs()) * 6 : -5 * _bob.value;
                  return Transform.translate(
                    offset: Offset(0, bounceY),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(_faceRight ? 1.0 : -1.0, 1.0),
                      child: _MascotFace(
                        size: _size,
                        tailWag: _isMoving ? math.sin(_walk.value * 2 * math.pi * 2) : (_tail.value * 2 - 1),
                        earTwitch: _bob.value,
                        blink: _blink,
                        talking: _open,
                        walking: _isMoving,
                        walkPhase: _walk.value,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_open)
            Positioned(
              right: 12,
              bottom: 12,
              child: _chatCard(context),
            ),
        ],
      );
    });
  }

  Widget _chatCard(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = w < 380 ? w - 24 : 320.0;
    return Material(
      color: Colors.white,
      elevation: 14,
      shadowColor: const Color(0x55000000),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: cardW,
        height: 420,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                const _MascotFace(size: 28, talking: true),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Bông — trợ lý gọi món', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
                ),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _open = false)),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length + (_busy ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _messages.length) {
                    return _bubble('Bông đang gõ...', false, muted: true);
                  }
                  final m = _messages[i];
                  return _bubble(m.text, m.fromUser);
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: 'Nhắn cho Bông...',
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _busy ? null : () => _send(_input.text)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String text, bool fromUser, {bool muted = false}) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 230),
        decoration: BoxDecoration(
          color: fromUser ? AppColors.primary : (muted ? AppColors.border : AppColors.accentLight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text, style: TextStyle(fontSize: 13, color: fromUser ? Colors.white : AppColors.textMain, fontStyle: muted ? FontStyle.italic : FontStyle.normal)),
      ),
    );
  }
}

/// Mặt linh vật Bông vẽ bằng CustomPaint — chú chó vàng dễ thương, 4 chân chạy độc lập, không cần ảnh ngoài.
/// [tailWag] -1..1 điều khiển đuôi vẫy qua lại, [earTwitch] làm tai hơi lệch theo nhịp,
/// [blink] nháy mắt, [talking] mở miệng tròn khi đang chat.
class _MascotFace extends StatelessWidget {
  final double size;
  final double tailWag;
  final double earTwitch;
  final bool blink;
  final bool talking;
  final bool walking;
  final double walkPhase;
  const _MascotFace({
    required this.size,
    this.tailWag = 0,
    this.earTwitch = 0,
    this.blink = false,
    this.talking = false,
    this.walking = false,
    this.walkPhase = 0,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.35,
      height: size * 1.15,
      child: CustomPaint(
        painter: _MascotPainter(tailWag: tailWag, earTwitch: earTwitch, blink: blink, talking: talking, walking: walking, walkPhase: walkPhase),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final double tailWag;
  final double earTwitch;
  final bool blink;
  final bool talking;
  final bool walking;
  final double walkPhase;
  _MascotPainter({
    required this.tailWag,
    required this.earTwitch,
    required this.blink,
    required this.talking,
    required this.walking,
    required this.walkPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ trong 1 ô vuông căn giữa canvas (canvas rộng hơn 1 chút để chừa chỗ cho đuôi vẫy).
    final double s = size.height; // cạnh ô vuông chính dùng làm đơn vị tỉ lệ
    final double ox = (size.width - s) / 2;
    canvas.save();
    canvas.translate(ox, 0);
    final w = s, h = s;
    final furShadow = Paint()..color = const Color(0x40000000);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.98), width: w * 0.7, height: h * 0.1), furShadow);

    const fur = Color(0xFFD9974B); // vàng bò (golden) — lông chó
    const furDark = Color(0xFFA6672A);
    const cream = Color(0xFFFFF3E2);

    final walkPhaseRad = walkPhase * 2 * math.pi;

    // --- Đuôi (vẫy qua lại, vẫy nhanh hơn khi đang chạy) ---
    final tailBase = Offset(w * 0.86, h * 0.68);
    final sway = tailWag * w * 0.22;
    final tailPath = Path()
      ..moveTo(tailBase.dx, tailBase.dy)
      ..cubicTo(
        tailBase.dx + w * 0.2 + sway, tailBase.dy - h * 0.08,
        tailBase.dx + w * 0.26 + sway, tailBase.dy - h * 0.32,
        tailBase.dx + w * 0.1 + sway * 0.6, tailBase.dy - h * 0.42,
      );
    canvas.drawPath(tailPath, Paint()
      ..color = fur
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(tailBase.dx + w * 0.1 + sway * 0.6, tailBase.dy - h * 0.42), w * 0.04, Paint()..color = cream);

    // --- Thân chó (khi chạy: hơi nghiêng/lắc theo nhịp bước cho tự nhiên) ---
    final bodyTilt = walking ? math.sin(walkPhaseRad) * 0.05 : 0.0;
    canvas.save();
    canvas.translate(w * 0.5, h * 0.72);
    canvas.rotate(bodyTilt);
    canvas.translate(-w * 0.5, -h * 0.72);
    final bodyRect = Rect.fromLTWH(w * 0.2, h * 0.52, w * 0.6, h * 0.34);
    canvas.drawRRect(RRect.fromRectAndCorners(bodyRect, topLeft: Radius.circular(w * 0.26), topRight: Radius.circular(w * 0.26), bottomLeft: Radius.circular(w * 0.14), bottomRight: Radius.circular(w * 0.14)), Paint()..color = fur);
    // bụng sáng màu
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.72), width: w * 0.3, height: h * 0.16), Paint()..color = cream);

    // --- 4 CHÂN, mỗi chân cử động độc lập (dáng chạy lục cục: 2 chân chéo nhau cùng nhịp) ---
    void drawLeg(double hipX, double phaseOffset) {
      final ph = walking ? walkPhaseRad + phaseOffset : 0.0;
      final swing = walking ? math.sin(ph) * w * 0.05 : 0.0;
      final lift = walking ? math.sin(ph).clamp(0.0, 1.0) : 0.0;
      const hipY = 0.82;
      final footX = hipX + swing;
      final footY = 0.96 - lift * 0.07;
      canvas.drawLine(
        Offset(hipX, h * hipY),
        Offset(footX, h * footY),
        Paint()
          ..color = fur
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.07
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(footX, h * (footY + 0.015)), width: w * 0.1, height: h * (0.055 - lift * 0.02)),
        Paint()..color = cream,
      );
    }

    // Trình tự trái→phải theo thân: chân sau-trái, chân trước-trái, chân trước-phải, chân sau-phải.
    // Dáng chạy đối xứng chéo: (trước-trái + sau-phải) cùng nhịp, (sau-trái + trước-phải) cùng nhịp.
    drawLeg(w * 0.30, math.pi); // sau-trái
    drawLeg(w * 0.42, 0); // trước-trái
    drawLeg(w * 0.58, math.pi); // trước-phải
    drawLeg(w * 0.70, 0); // sau-phải
    canvas.restore();

    // --- Tai cụp (tai chó, hơi phất phơ theo earTwitch) — tai trái lệch sang trái, tai phải lệch sang phải ---
    Path earPathLeft(double cx, double flap) {
      return Path()
        ..moveTo(cx + w * 0.03, h * 0.14)
        ..quadraticBezierTo(cx - w * 0.17 + flap, h * 0.2, cx - w * 0.14 + flap, h * 0.38)
        ..quadraticBezierTo(cx - w * 0.1 + flap, h * 0.46, cx - w * 0.02, h * 0.42)
        ..close();
    }

    Path earPathRight(double cx, double flap) {
      return Path()
        ..moveTo(cx - w * 0.03, h * 0.14)
        ..quadraticBezierTo(cx + w * 0.17 + flap, h * 0.2, cx + w * 0.14 + flap, h * 0.38)
        ..quadraticBezierTo(cx + w * 0.1 + flap, h * 0.46, cx + w * 0.02, h * 0.42)
        ..close();
    }

    canvas.drawPath(earPathLeft(w * 0.28, w * 0.015 * earTwitch), Paint()..color = furDark);
    canvas.drawPath(earPathRight(w * 0.72, -w * 0.015 * earTwitch), Paint()..color = furDark);

    // --- Đầu ---
    final headCenter = Offset(w * 0.5, h * 0.44);
    canvas.drawCircle(headCenter, w * 0.3, Paint()..color = fur);

    // đốm trắng nhỏ trên trán
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.3), width: w * 0.1, height: h * 0.14), Paint()..color = cream.withAlpha(150));

    // má phúng phính
    canvas.drawCircle(Offset(w * 0.28, h * 0.52), w * 0.1, Paint()..color = cream);
    canvas.drawCircle(Offset(w * 0.72, h * 0.52), w * 0.1, Paint()..color = cream);
    canvas.drawCircle(Offset(w * 0.26, h * 0.54), w * 0.04, Paint()..color = const Color(0x40FF8A8A));
    canvas.drawCircle(Offset(w * 0.74, h * 0.54), w * 0.04, Paint()..color = const Color(0x40FF8A8A));

    // --- Mắt (nháy = vẽ 1 đường cong thay vì tròn) ---
    final eyeColor = Paint()..color = const Color(0xFF3B2A1E);
    if (blink) {
      final blinkPaint = Paint()
        ..color = const Color(0xFF3B2A1E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * 0.32, h * 0.46), Offset(w * 0.40, h * 0.46), blinkPaint);
      canvas.drawLine(Offset(w * 0.60, h * 0.46), Offset(w * 0.68, h * 0.46), blinkPaint);
    } else {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.36, h * 0.46), width: w * 0.1, height: h * 0.13), Paint()..color = Colors.white);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.64, h * 0.46), width: w * 0.1, height: h * 0.13), Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w * 0.37, h * 0.47), w * 0.045, eyeColor);
      canvas.drawCircle(Offset(w * 0.65, h * 0.47), w * 0.045, eyeColor);
      canvas.drawCircle(Offset(w * 0.385, h * 0.455), w * 0.015, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(w * 0.665, h * 0.455), w * 0.015, Paint()..color = Colors.white);
    }

    // --- Mõm chó (bầu hơn mèo, nhô ra phía trước) ---
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.58), width: w * 0.28, height: h * 0.2), Paint()..color = cream);

    // --- Mũi & miệng ---
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.55), width: w * 0.1, height: h * 0.07), Paint()..color = const Color(0xFF3B2A1E));

    if (talking) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.655), width: w * 0.09, height: h * 0.07), Paint()..color = const Color(0xFF6B4630));
    } else {
      final mouthPaint = Paint()
        ..color = const Color(0xFF6B4630)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.025
        ..strokeCap = StrokeCap.round;
      final mouthPath = Path()
        ..moveTo(w * 0.5, h * 0.60)
        ..quadraticBezierTo(w * 0.44, h * 0.66, w * 0.38, h * 0.615)
        ..moveTo(w * 0.5, h * 0.60)
        ..quadraticBezierTo(w * 0.56, h * 0.66, w * 0.62, h * 0.615);
      canvas.drawPath(mouthPath, mouthPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.tailWag != tailWag ||
      oldDelegate.earTwitch != earTwitch ||
      oldDelegate.blink != blink ||
      oldDelegate.talking != talking ||
      oldDelegate.walking != walking ||
      oldDelegate.walkPhase != walkPhase;
}

/// Thẻ món nổi bật: ảnh lớn, logo quán, giá nổi, hiệu ứng khi rê chuột
class MenuCard extends StatefulWidget {
  final MenuItem item;
  final VoidCallback onTap;
  const MenuCard({super.key, required this.item, required this.onTap});
  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 160),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hover ? AppColors.accent : const Color(0xFFE6D6C3), width: _hover ? 2 : 1.4),
            boxShadow: [
              BoxShadow(color: Color(_hover ? 0x40000000 : 0x1F000000), blurRadius: _hover ? 20 : 12, offset: const Offset(0, 6)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 500,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF3E3D3), Color(0xFFE2C6A8)])),
                            child: const Center(child: Icon(Icons.coffee, color: AppColors.accent, size: 42)),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0x00000000), Color(0x8C000000)],
                              stops: [0, 0.55, 1],
                            ),
                          ),
                        ),
                        const Positioned(top: 8, left: 8, child: BrandBadge(size: 28)),
                        Positioned(
                          left: 10,
                          bottom: 8,
                          child: Text('L: ${formatMoney(item.priceL)}đ', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2))],
                            ),
                            child: Text('${formatMoney(item.priceM)}đ', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textMain, height: 1.2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  KHÁCH: TÙY CHỈNH MÓN
// =====================================================================
class CustomizeItemSheet extends StatefulWidget {
  final MenuItem item;
  final List<Topping> toppings;
  final ValueChanged<CartItem> onAdd;
  const CustomizeItemSheet({super.key, required this.item, required this.toppings, required this.onAdd});
  @override
  State<CustomizeItemSheet> createState() => _CustomizeItemSheetState();
}

class _CustomizeItemSheetState extends State<CustomizeItemSheet> {
  String _size = 'M';
  int _sugar = 100;
  int _ice = 100;
  String _strength = 'Chuẩn vị';
  int _qty = 1;
  final Set<String> _selected = {};
  final _note = TextEditingController();

  bool get _isBlended {
    const ids = {'st_bo', 'st_dau', 'dx_cookie', 'sc_vietquat'};
    final n = widget.item.name.toLowerCase();
    return ids.contains(widget.item.id) || n.contains('sinh tố') || n.contains('đá xay');
  }

  List<Topping> get _chosen => widget.toppings.where((t) => _selected.contains(t.id)).toList();
  int get _unit => (_size == 'L' ? widget.item.priceL : widget.item.priceM) + _chosen.fold<int>(0, (s, t) => s + t.price);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Widget _choices<T>(List<(String, T)> options, T current, ValueChanged<T> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.map((o) {
        final sel = o.$2 == current;
        return ChoiceChip(
          label: Text(o.$1),
          selected: sel,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textMain),
          onSelected: (_) => setState(() => onSelect(o.$2)),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCoffee = widget.item.category.contains('Cà Phê');
    final iceOptions = _isBlended
        ? <(String, int)>[('100% (Chuẩn xay)', 100), ('70% đá', 70), ('50% (Ít đá)', 50)]
        : <(String, int)>[('100% (Chuẩn)', 100), ('70% đá', 70), ('50% đá', 50), ('Không đá (+20% cốt)', 0)];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.item.imageUrl,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 68, height: 68, color: AppColors.background, child: const Icon(Icons.coffee, color: AppColors.textMuted)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textMain)),
                      const SizedBox(height: 2),
                      Text('${formatMoney(_unit)}đ / ly', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28, color: AppColors.border),
            fieldLabel('Kích cỡ'),
            _choices<String>([
              ('Size M  ${formatMoney(widget.item.priceM)}đ', 'M'),
              ('Size L  ${formatMoney(widget.item.priceL)}đ', 'L'),
            ], _size, (v) => _size = v),
            fieldLabel('Mức đường'),
            _choices<int>([('100% (Chuẩn)', 100), ('70% đường', 70), ('50% đường', 50), ('0% (Không đường)', 0)], _sugar, (v) => _sugar = v),
            fieldLabel(_isBlended ? 'Mức đá (món xay bắt buộc có đá)' : 'Mức đá'),
            _choices<int>(iceOptions, _ice, (v) => _ice = v),
            fieldLabel('Mức độ đậm'),
            _choices<String>([
              ('Chuẩn vị (100%)', 'Chuẩn vị'),
              (isCoffee ? 'Đậm vị (+1 Espresso Shot)' : 'Đậm vị (+20% Cốt)', 'Đậm vị'),
            ], _strength, (v) => _strength = v),
            if (widget.toppings.isNotEmpty) ...[
              fieldLabel('Topping thêm'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.toppings.map((t) {
                  final sel = _selected.contains(t.id);
                  return FilterChip(
                    label: Text('${t.name} (+${formatMoney(t.price)}đ)'),
                    selected: sel,
                    selectedColor: AppColors.accentLight,
                    checkmarkColor: AppColors.accent,
                    labelStyle: TextStyle(color: sel ? AppColors.accent : AppColors.textMain, fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                    onSelected: (v) => setState(() => v ? _selected.add(t.id) : _selected.remove(t.id)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            TextField(controller: _note, maxLength: 200, decoration: inputDeco('Ghi chú đặc biệt cho quầy bar...')),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Số lượng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  widget.onAdd(CartItem(
                    item: widget.item,
                    size: _size,
                    sugar: _sugar,
                    ice: _ice,
                    strength: _strength,
                    toppings: _chosen,
                    note: _note.text.trim(),
                    quantity: _qty,
                  ));
                  Navigator.pop(context);
                },
                child: Text('Thêm vào giỏ • ${formatMoney(_unit * _qty)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  const QtyStepper({super.key, required this.value, required this.onChanged, this.min = 1});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: value > min ? () => onChanged(value - 1) : null,
            child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16)),
          ),
          SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
          InkWell(
            onTap: value < 50 ? () => onChanged(value + 1) : null,
            child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16)),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  KHÁCH: GIỎ HÀNG — xóa món, mã giảm giá, 2 nút THANH TOÁN / GỌI MÓN
// =====================================================================
class CartBottomSheet extends StatefulWidget {
  final List<CartItem> cart;
  final String table;
  final VoidCallback onCartChanged;
  final void Function(Map<String, dynamic> result, String payment) onOrderPlaced;
  const CartBottomSheet({super.key, required this.cart, required this.table, required this.onCartChanged, required this.onOrderPlaced});
  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  final _voucher = TextEditingController();
  String? _appliedCode;
  int _discount = 0;
  String? _voucherMsg;
  bool _voucherError = false;
  bool _checking = false;
  String? _submitting; // 'transfer' | 'cash'
  String? _error;
  List<Map<String, dynamic>> _publicVouchers = [];

  int get _subtotal => widget.cart.fold<int>(0, (s, c) => s + c.lineTotal);

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  @override
  void dispose() {
    _voucher.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    try {
      final r = await db.rpc('list_public_vouchers');
      if (r is List && mounted) {
        setState(() => _publicVouchers = r.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {}
  }

  void _changed() {
    widget.onCartChanged();
    setState(() {
      if (_appliedCode != null) {
        _appliedCode = null;
        _discount = 0;
        _voucherMsg = 'Giỏ hàng đã thay đổi, vui lòng áp dụng mã lại.';
        _voucherError = true;
      }
    });
  }

  void _remove(CartItem c) {
    widget.cart.remove(c);
    _changed();
  }

  Future<void> _clearAll() async {
    if (await confirmDialog(context, title: 'Xóa toàn bộ giỏ hàng?', message: 'Tất cả món đã chọn sẽ bị xóa.', okLabel: 'Xóa hết', danger: true)) {
      widget.cart.clear();
      _changed();
    }
  }

  Future<void> _applyVoucher([String? preset]) async {
    if (preset != null) _voucher.text = preset;
    final code = _voucher.text.trim().toUpperCase();
    if (code.isEmpty || widget.cart.isEmpty) return;
    setState(() {
      _checking = true;
      _voucherMsg = null;
    });
    try {
      final res = await db.rpc('check_voucher', params: {'p_code': code, 'p_subtotal': _subtotal});
      setState(() {
        _appliedCode = code;
        _discount = toInt(res);
        _voucherMsg = '✓ Đã áp dụng mã $code: giảm ${formatMoney(_discount)}đ';
        _voucherError = false;
      });
    } catch (e) {
      setState(() {
        _appliedCode = null;
        _discount = 0;
        _voucherMsg = friendlyError(e);
        _voucherError = true;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _submit(String payment) async {
    if (widget.cart.isEmpty || _submitting != null) return;
    if (payment == 'transfer') {
      final ref = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TransferQrDialog(amount: _subtotal - _discount, table: widget.table, ref: ref),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _submitting = payment;
      _error = null;
    });
    try {
      final raw = await db.rpc('place_order', params: {
        'p_table': widget.table,
        'p_payment': payment,
        'p_items': widget.cart.map((c) => c.toPayload()).toList(),
        'p_voucher': _appliedCode,
      });
      final res = Map<String, dynamic>.from(raw as Map);
      await OrderHistory.save(res['id'].toString());
      widget.cart.clear();
      widget.onCartChanged();
      if (!mounted) return;
      Navigator.pop(context);
      widget.onOrderPlaced(res, payment);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = null;
          _error = 'Chưa đặt được món: ${friendlyError(e)}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _subtotal - _discount;
    final empty = widget.cart.isEmpty;
    return Padding(
      padding: EdgeInsets.only(left: 18, right: 18, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Giỏ hàng — Bàn ${widget.table}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary))),
              if (!empty)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: const Text('Xóa hết'),
                ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.textMuted)),
            ],
          ),
          if (!empty) const Text('Mẹo: vuốt món sang trái hoặc bấm 🗑 để xóa', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          if (empty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Column(children: [
                Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.border),
                SizedBox(height: 8),
                Text('Giỏ hàng trống', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
              ]),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.cart.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final c = widget.cart[idx];
                  final details = [
                    'Size ${c.size}',
                    'Đường ${c.sugar}%',
                    'Đá ${c.ice}%',
                    c.strength,
                    if (c.toppings.isNotEmpty) 'Topping: ${c.toppings.map((t) => t.name).join(', ')}',
                    if (c.note.isNotEmpty) 'Lưu ý: ${c.note}',
                  ].join(' • ');
                  return Dismissible(
                    key: ObjectKey(c),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(14)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.delete, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    onDismissed: (_) => _remove(c),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(c.item.imageUrl, width: 58, height: 58, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(width: 58, height: 58, color: AppColors.accentLight, child: const Icon(Icons.coffee, color: AppColors.accent))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textMain)),
                                const SizedBox(height: 2),
                                Text(details, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    QtyStepper(value: c.quantity, onChanged: (v) {
                                      c.quantity = v;
                                      _changed();
                                    }),
                                    const Spacer(),
                                    Text('${formatMoney(c.lineTotal)}đ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Xóa món này',
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () => _remove(c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (!empty) ...[
            const Divider(height: 24, color: AppColors.border),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _voucher,
                    textCapitalization: TextCapitalization.characters,
                    decoration: inputDeco('Nhập mã giảm giá').copyWith(prefixIcon: const Icon(Icons.local_offer_outlined, size: 18)),
                    onSubmitted: (_) => _applyVoucher(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _checking ? null : () => _applyVoucher(),
                  child: _checking ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Áp dụng'),
                ),
              ],
            ),
            if (_publicVouchers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _publicVouchers.map((v) {
                  final code = v['code'].toString();
                  final selected = _appliedCode == code;
                  return ActionChip(
                    avatar: Icon(selected ? Icons.check_circle : Icons.local_offer, size: 16, color: selected ? AppColors.baristaGreen : AppColors.accent),
                    backgroundColor: selected ? AppColors.baristaGreen.withAlpha(30) : AppColors.accentLight,
                    side: BorderSide(color: selected ? AppColors.baristaGreen : AppColors.accent.withAlpha(80)),
                    label: Text('$code • ${v['description']}', style: const TextStyle(fontSize: 12)),
                    onPressed: () => _applyVoucher(code),
                  );
                }).toList(),
              ),
            ],
            if (_voucherMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_voucherMsg!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _voucherError ? AppColors.danger : AppColors.baristaGreen)),
              ),
            const SizedBox(height: 12),
            _moneyRow('Tạm tính', '${formatMoney(_subtotal)}đ'),
            if (_discount > 0) _moneyRow('Giảm giá ($_appliedCode)', '-${formatMoney(_discount)}đ'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('${formatMoney(total)}đ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.accent)),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            _bigButton(
              type: 'transfer',
              color: AppColors.baristaGreen,
              icon: Icons.qr_code_2,
              title: 'THANH TOÁN  •  ${formatMoney(total)}đ',
              sub: 'Quét QR chuyển khoản rồi bấm "Đã chuyển khoản xong"',
            ),
            const SizedBox(height: 10),
            _bigButton(
              type: 'cash',
              color: AppColors.primary,
              icon: Icons.room_service_outlined,
              title: 'GỌI MÓN  •  trả tiền mặt',
              sub: 'Món gửi ngay tới quầy, thanh toán tiền mặt tại quầy',
            ),
          ],
        ],
      ),
    );
  }

  Widget _bigButton({required String type, required Color color, required IconData icon, required String title, required String sub}) {
    final busy = _submitting == type;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withAlpha(120),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _submitting != null ? null : () => _submit(type),
      child: Row(
        children: [
          busy
              ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Icon(icon, size: 28, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

/// Mã QR chuyển khoản — giống bản gốc: khách chuyển xong tự bấm "Đã chuyển khoản xong"
class TransferQrDialog extends StatelessWidget {
  final int amount;
  final String table;
  final String ref;
  const TransferQrDialog({super.key, required this.amount, required this.table, required this.ref});

  @override
  Widget build(BuildContext context) {
    final info = 'TT Ban $table $ref';
    final qrUrl = 'https://img.vietqr.io/image/${AppConfig.bankBin}-${AppConfig.bankAccount}-compact2.png'
        '?amount=$amount&addInfo=${Uri.encodeComponent(info)}';
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Icon(Icons.qr_code_2, size: 40, color: AppColors.accent),
          const SizedBox(height: 8),
          Text('Quét QR Thanh Toán (${AppConfig.bankName})', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text('Bàn $table', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Image.network(
                qrUrl,
                width: 230,
                height: 230,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const SizedBox(width: 230, height: 230, child: Center(child: CircularProgressIndicator(color: AppColors.accent))),
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 230,
                  height: 120,
                  child: Center(child: Text('Không tải được mã QR.\nVui lòng chuyển khoản theo thông tin bên dưới.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.red))),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('${formatMoney(amount)}đ', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.accent)),
            const SizedBox(height: 4),
            const Text('${AppConfig.bankName}: ${AppConfig.bankAccount}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
            SelectableText('Nội dung: $info', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            noteBox('LƯU Ý: Sau khi chuyển khoản, vui lòng CHỤP LẠI BILL CHUYỂN KHOẢN trong app ngân hàng rồi bấm "Đã chuyển khoản xong".', icon: Icons.photo_camera_outlined),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.baristaGreen, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Đã chuyển khoản xong', style: TextStyle(fontWeight: FontWeight.w800)),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

// =====================================================================
//  KHÁCH: ĐƠN HÀNG — hóa đơn, trạng thái
// =====================================================================
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  String? _error;
  Timer? _timer;
  bool _justPaid = false;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final res = await db.rpc('get_order_status', params: {'p_order_id': widget.orderId});
      if (!mounted) return;
      final next = res == null ? null : Map<String, dynamic>.from(res as Map);
      final wasPaid = _order != null && isPaid(_order!);
      setState(() {
        _order = next;
        _error = res == null ? 'Không tìm thấy đơn hàng.' : null;
        if (next != null && !wasPaid && _order != null && isPaid(next) && next['payment_method'] == 'transfer') _justPaid = true;
      });
      if (next != null) {
        final st = next['status'];
        if (st == 'cancelled' || (st == 'served' && isPaid(next))) _timer?.cancel();
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Đơn hàng của bạn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: Center(child: LiveClock(showDate: false, size: 24)))],
      ),
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) errorBanner(_error!, onRetry: _poll),
                if (o == null && _error == null) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                if (o != null) ...[
                  _paymentSection(o),
                  const SizedBox(height: 14),
                  if (o['status'] != 'cancelled') _progress(o),
                  const SizedBox(height: 14),
                  BillView(order: o),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Gọi thêm món', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color? border}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border ?? AppColors.border, width: border != null ? 2 : 1),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: child,
      );

  Widget _paymentSection(Map<String, dynamic> o) {
    final status = o['status'];
    final cash = o['payment_method'] == 'cash';
    final paid = isPaid(o);
    final total = toInt(o['total']);
    final code = o['code'].toString();
    const screenshotNote = 'LƯU Ý: Vui lòng CHỤP LẠI BILL CHUYỂN KHOẢN trong app ngân hàng (và màn hình hóa đơn này) để đối chiếu khi cần.';

    if (status == 'cancelled') {
      return _card(border: AppColors.danger, child: noteBox('Đơn đã bị hủy. Vui lòng liên hệ nhân viên quầy.', color: AppColors.danger, icon: Icons.cancel_outlined));
    }

    if (cash) {
      return _card(
        border: paid ? AppColors.baristaGreen : const Color(0xFFB26A00),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(paid ? Icons.check_circle : Icons.payments_outlined, size: 48, color: paid ? AppColors.baristaGreen : const Color(0xFFB26A00)),
            const SizedBox(height: 6),
            Text(paid ? 'ĐÃ THU TIỀN MẶT' : 'ĐÃ GỌI MÓN THÀNH CÔNG', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (!paid)
              noteBox('💵 THANH TOÁN TIỀN MẶT: vui lòng trả ${formatMoney(total)}đ tại quầy (đọc mã đơn #$code). Món đã được gửi tới quầy pha chế.', icon: Icons.payments),
          ],
        ),
      );
    }

    if (paid) {
      return _card(
        border: AppColors.baristaGreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedScale(
              scale: _justPaid ? 1.0 : 0.95,
              duration: const Duration(milliseconds: 400),
              child: const Icon(Icons.verified, size: 60, color: AppColors.baristaGreen),
            ),
            const SizedBox(height: 6),
            const Text('ĐÃ THANH TOÁN THÀNH CÔNG', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.baristaGreen)),
            Text('${formatMoney(total)}đ • Mã đơn #$code', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            noteBox(screenshotNote, icon: Icons.photo_camera_outlined),
          ],
        ),
      );
    }

    // Đơn cũ còn ở trạng thái chờ (trước khi đổi cách thanh toán)
    return _card(
      border: const Color(0xFFB26A00),
      child: noteBox('Đơn đang chờ quầy xác nhận thanh toán ${formatMoney(total)}đ. Vui lòng liên hệ nhân viên nếu cần.', icon: Icons.hourglass_top),
    );
  }

  Widget _progress(Map<String, dynamic> o) {
    final status = o['status'];
    final cash = o['payment_method'] == 'cash';
    final paidOrCash = cash || isPaid(o);
    final steps = <(String, IconData, bool)>[
      (cash ? 'Đã gửi đơn tới quầy' : 'Đã thanh toán', cash ? Icons.send : Icons.payments_outlined, paidOrCash),
      ('Đang pha chế', Icons.coffee_maker_outlined, status == 'pending' || status == 'served'),
      ('Đã xong — mời bạn nhận món', Icons.check_circle_outline, status == 'served'),
    ];
    final currentIdx = steps.lastIndexWhere((s) => s.$3);
    return _card(
      child: Column(
        children: List.generate(steps.length, (i) {
          final done = steps[i].$3;
          final current = i == currentIdx && status != 'served';
          return Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 12),
            child: Row(
              children: [
                Icon(steps[i].$2, color: done ? AppColors.baristaGreen : const Color(0xFFCFC8C0), size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i].$1,
                    style: TextStyle(fontSize: 15, fontWeight: done ? FontWeight.w800 : FontWeight.w500, color: done ? AppColors.textMain : AppColors.textMuted),
                  ),
                ),
                if (current) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// =====================================================================
//  QUẦY PHA CHẾ — dùng được trên điện thoại / máy tính bảng / máy tính
// =====================================================================
class BaristaScreen extends StatefulWidget {
  const BaristaScreen({super.key});
  @override
  State<BaristaScreen> createState() => _BaristaScreenState();
}

class _BaristaScreenState extends State<BaristaScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  String _tab = 'pending';
  final Set<String> _expanded = {};
  final Map<String, String> _knownStatus = {};
  bool _firstLoad = true;
  bool _busy = false;
  bool _queued = false;
  String? _flashText;
  Timer? _flashTimer;
  Timer? _timer;
  RealtimeChannel? _channel;
  bool _realtimeOk = false;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    if (_channel != null) {
      try {
        db.removeChannel(_channel!);
      } catch (_) {}
    }
    super.dispose();
  }

  void _subscribe() {
    try {
      _channel = db
          .channel('barista-orders-${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'orders', callback: (_) => _load(silent: true))
          .subscribe((status, error) {
        if (mounted) setState(() => _realtimeOk = status == RealtimeSubscribeStatus.subscribed);
      });
    } catch (_) {}
  }

  Future<void> _load({bool silent = false}) async {
    if (_busy) {
      _queued = true;
      return;
    }
    _busy = true;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final since = DateTime.now().subtract(const Duration(days: 3)).toUtc().toIso8601String();
      final rows = await db.from('orders').select('*, order_items(*)').gte('created_at', since).order('created_at', ascending: true);
      final list = List<Map<String, dynamic>>.from(rows);
      final msgs = <String>[];
      for (final o in list) {
        final id = o['id'].toString();
        final st = o['status'].toString();
        final prev = _knownStatus[id];
        if (!_firstLoad) {
          if (prev == null && st == 'pending') {
            msgs.add('🔔 ĐƠN MỚI #${o['code']} — Bàn ${o['table_number']} (${o['payment_method'] == 'cash' ? 'tiền mặt' : 'khách báo đã CK'})');
          } else if (prev == null && st == 'awaiting_payment') {
            msgs.add('🕒 Đơn #${o['code']} — Bàn ${o['table_number']} đang chờ chuyển khoản');
          } else if (prev == 'awaiting_payment' && st == 'pending') {
            msgs.add('💰 Đơn #${o['code']} — Bàn ${o['table_number']} ĐÃ NHẬN TIỀN, pha ngay!');
          }
        }
        _knownStatus[id] = st;
      }
      _firstLoad = false;
      if (msgs.isNotEmpty && mounted) _flash(msgs.join('\n'));
      if (mounted) {
        setState(() {
          _orders = list;
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _loading = false;
        });
      }
    } finally {
      _busy = false;
      if (_queued) {
        _queued = false;
        _load(silent: true);
      }
    }
  }

  void _flash(String text) {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();
    _flashTimer?.cancel();
    setState(() => _flashText = text);
    _flashTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _flashText = null);
    });
  }

  Future<void> _update(Map<String, dynamic> o, Map<String, dynamic> patch) async {
    try {
      await db.from('orders').update(patch).eq('id', o['id']);
      await _load(silent: true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _confirmTransferManually(Map<String, dynamic> o) async {
    final total = toInt(o['total']);
    final ok = await confirmDialog(
      context,
      title: 'Xác nhận tay đơn #${o['code']}?',
      message: 'Chỉ bấm khi bạn đã thấy ${formatMoney(total)}đ về tài khoản với nội dung "QN ${o['code']}". '
          'Dùng cho đơn cũ còn ở trạng thái chờ.',
      okLabel: 'Đã thấy tiền về',
    );
    if (ok) _update(o, {'status': 'pending', 'paid_at': nowUtcIso(), 'paid_via': 'manual', 'paid_amount': total});
  }

  void _collectCash(Map<String, dynamic> o) =>
      _update(o, {'paid_at': nowUtcIso(), 'paid_via': 'cash', 'paid_amount': toInt(o['total'])});

  Future<void> _complete(Map<String, dynamic> o) async {
    final patch = <String, dynamic>{'status': 'served', 'served_at': nowUtcIso()};
    if (o['payment_method'] == 'cash' && o['paid_at'] == null) {
      final ok = await confirmDialog(
        context,
        title: 'Đơn tiền mặt chưa thu',
        message: 'Bàn ${o['table_number']} đã trả ${formatMoney(toInt(o['total']))}đ tiền mặt chưa?',
        okLabel: 'Đã thu & hoàn thành',
      );
      if (!ok) return;
      patch.addAll({'paid_at': nowUtcIso(), 'paid_via': 'cash', 'paid_amount': toInt(o['total'])});
    }
    _update(o, patch);
  }

  Future<void> _toggleItemDone(Map<String, dynamic> item, bool done) async {
    setState(() => item['done'] = done);
    try {
      await db.from('order_items').update({'done': done}).eq('id', item['id']);
    } catch (e) {
      if (mounted) {
        setState(() => item['done'] = !done);
        showSnack(context, friendlyError(e), error: true);
      }
    }
  }

  bool _isToday(Map<String, dynamic> o) {
    final d = parseLocal(o['created_at']);
    final n = DateTime.now();
    return d != null && d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final awaiting = _orders.where((o) => o['status'] == 'awaiting_payment').toList();
    final pending = _orders.where((o) => o['status'] == 'pending').toList();
    final done = _orders.where((o) => o['status'] == 'served' && _isToday(o)).toList().reversed.toList();
    final unpaidCash = pending.where((o) => o['payment_method'] == 'cash' && o['paid_at'] == null).length;
    final current = _tab == 'awaiting_payment' ? awaiting : (_tab == 'pending' ? pending : done);
    final isAdmin = AuthService.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFFEFE9E1), height: 1)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QUẦY PHA CHẾ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary, letterSpacing: 0.5)),
            Text(AuthService.user?.email ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Trang quản lý',
              icon: const Icon(Icons.query_stats, color: AppColors.textMain),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
            ),
          IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh, color: AppColors.textMain), onPressed: () => _load()),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: AppColors.textMain),
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
        ],
      ),
      body: AppBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: () => _load(silent: true),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const LiveClock(),
                        _statusPill(_realtimeOk ? 'Đang nhận đơn trực tiếp' : 'Tự cập nhật mỗi 12 giây', _realtimeOk ? AppColors.baristaGreen : const Color(0xFFB26A00),
                            _realtimeOk ? Icons.wifi_tethering : Icons.sync),
                        if (unpaidCash > 0) _statusPill('$unpaidCash đơn tiền mặt chưa thu', AppColors.danger, Icons.payments_outlined),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_flashText != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active, color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_flashText!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, height: 1.4))),
                            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _flashText = null)),
                          ],
                        ),
                      ),
                    if (_error != null) errorBanner(_error!, onRetry: _load),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _tabButton('☕ Đang pha (${pending.length})', 'pending', highlight: pending.isNotEmpty),
                          const SizedBox(width: 8),
                          if (awaiting.isNotEmpty) ...[
                            _tabButton('🕒 Chờ chuyển khoản (${awaiting.length})', 'awaiting_payment', highlight: true),
                            const SizedBox(width: 8),
                          ],
                          _tabButton('✅ Xong hôm nay (${done.length})', 'served'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (current.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE8DFD4))),
                        child: const Center(child: Text('Không có đơn nào ☕', style: TextStyle(color: AppColors.textMuted, fontSize: 15))),
                      )
                    else
                      LayoutBuilder(builder: (context, box) {
                        final cols = box.maxWidth >= 1150 ? 3 : (box.maxWidth >= 740 ? 2 : 1);
                        final w = (box.maxWidth - 12 * (cols - 1)) / cols;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: current.map((o) => SizedBox(width: w, child: _orderCard(o))).toList(),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statusPill(String text, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withAlpha(120))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      );

  Widget _tabButton(String label, String value, {bool highlight = false}) {
    final sel = _tab == value;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => setState(() => _tab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: sel || highlight ? AppColors.accent : AppColors.border, width: highlight && !sel ? 2 : 1),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: sel ? Colors.white : AppColors.textMain)),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withAlpha(110))),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      );

  Widget _orderCard(Map<String, dynamic> o) {
    final items = orderItemsOf(o);
    o['order_items'] = items; // giữ tham chiếu để cập nhật 'done' tại chỗ
    final created = parseLocal(o['created_at']);
    final isCash = o['payment_method'] == 'cash';
    final paid = isPaid(o);
    final total = toInt(o['total']);
    final discount = toInt(o['discount']);
    final status = o['status'];
    final cups = items.fold<int>(0, (s, i) => s + toInt(i['quantity'], 1));
    final minutes = created == null ? 0 : DateTime.now().difference(created).inMinutes;

    Widget payChip;
    if (paid) {
      final via = o['paid_via'];
      payChip = via == 'customer'
          ? _chip('💳 KHÁCH BÁO ĐÃ CK — kiểm tra app ngân hàng', const Color(0xFF1565C0))
          : _chip(via == 'manual' ? '✍️ ĐÃ CK (xác nhận tay)' : '💵 ĐÃ THU TIỀN MẶT', AppColors.baristaGreen);
    } else if (isCash) {
      payChip = _chip('💵 CHƯA THU TIỀN', AppColors.danger);
    } else {
      payChip = _chip('🕒 CHỜ CHUYỂN KHOẢN', const Color(0xFFB26A00));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status == 'pending' ? AppColors.accent.withAlpha(150) : const Color(0xFFEFE8DE), width: status == 'pending' ? 1.6 : 1),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: status == 'pending' ? AppColors.accentLight : const Color(0xFFFCF9F3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text('BÀN ${o['table_number']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${o['code']}  •  $cups ly', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      Text(
                        '${created != null ? fmtTime(created) : '--:--'}${status != 'served' ? ' • $minutes phút trước' : ''}',
                        style: TextStyle(fontSize: 12, color: status == 'pending' && minutes >= 10 ? AppColors.danger : AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${formatMoney(total)}đ', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFB56A3E))),
                    if (discount > 0) Text('-${formatMoney(discount)}đ (${o['voucher_code']})', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Wrap(spacing: 6, runSpacing: 6, children: [payChip, _chip(isCash ? 'Tiền mặt' : 'Chuyển khoản', AppColors.textMuted)]),
          ),
          if (status == 'awaiting_payment')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: noteBox('Đơn đang chờ xác nhận chuyển khoản ${formatMoney(total)}đ. Kiểm tra app ngân hàng rồi bấm "Xác nhận tay".', icon: Icons.hourglass_top),
            ),
          ...items.map((it) => _itemTile(it, status == 'pending')),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Xem bill'),
                  onPressed: () => showBillDialog(context, o),
                ),
                if (status == 'awaiting_payment') ...[
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () async {
                      final ok = await confirmDialog(context, title: 'Hủy đơn #${o['code']}?', message: 'Đơn sẽ không được pha và không tính doanh thu.', okLabel: 'Hủy đơn', danger: true);
                      if (ok) _update(o, {'status': 'cancelled'});
                    },
                    child: const Text('Hủy đơn'),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.touch_app, size: 16),
                    label: const Text('Xác nhận tay'),
                    onPressed: () => _confirmTransferManually(o),
                  ),
                ],
                if (status == 'pending' && isCash && !paid)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('Đã thu tiền mặt'),
                    onPressed: () => _collectCash(o),
                  ),
                if (status == 'pending')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.baristaGreen, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Hoàn thành đơn', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () => _complete(o),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(Map<String, dynamic> it, bool canCheck) {
    final id = it['id'].toString();
    final expanded = _expanded.contains(id);
    final size = (it['size'] ?? 'M').toString();
    final sugar = toInt(it['sugar'], 100);
    final ice = toInt(it['ice'], 100);
    final strength = it['strength']?.toString() ?? 'Chuẩn vị';
    final qty = toInt(it['quantity'], 1);
    final note = it['note']?.toString() ?? '';
    final tops = toppingNames(it['toppings']);
    final done = it['done'] == true;
    final recipe = RecipeEngine.calculate(itemId: it['item_id']?.toString() ?? '', size: size, sugarPercent: sugar, icePercent: ice, strength: strength);
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEDE4D8)))),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expanded ? _expanded.remove(id) : _expanded.add(id)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
              child: Row(
                children: [
                  if (canCheck)
                    Checkbox(value: done, activeColor: AppColors.baristaGreen, onChanged: (v) => _toggleItemDone(it, v == true))
                  else
                    const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${qty > 1 ? '$qty × ' : ''}${it['item_name']} — $size',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary, decoration: done ? TextDecoration.lineThrough : null),
                        ),
                        Text('Đường $sugar% • Đá $ice% • $strength${tops.isNotEmpty ? ' • $tops' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        if (note.isNotEmpty) Text('Lưu ý: $note', style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: const Color(0xFF8C847B), size: 22),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFBF7F0), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CÔNG THỨC ĐỊNH LƯỢNG${qty > 1 ? ' (cho 1 ly)' : ''}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFB56A3E), letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  ...recipe.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r['name']!, style: const TextStyle(fontSize: 14, color: Color(0xFF4A4541))),
                            Text(r['amount']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      )),
                  if (tops.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Topping kèm theo', style: TextStyle(fontSize: 14, color: Color(0xFF4A4541))),
                          Flexible(child: Text(tops, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB56A3E)))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
//  QUẢN LÝ
// =====================================================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _tab = 'Tổng quan';
  bool _loading = true;
  String? _error;
  bool _isDailyView = false;
  DateTime _selectedDate = DateTime.now();
  DateTime? _loadedMonth;
  List<Map<String, dynamic>> _monthOrders = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _vouchers = [];
  List<MenuItem> _menu = [];
  List<Topping> _toppings = [];
  List<Map<String, dynamic>> _staff = [];
  String? _connStatus;
  bool _connOk = false;

  int get _totalExpense => _expenses.fold<int>(0, (s, e) => s + toInt(e['amount']));

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadData(), _loadMonthOrders(force: true)]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadData() async {
    try {
      final exp = await db.from('expenses').select().order('created_at', ascending: true);
      final vou = await db.from('vouchers').select().order('created_at', ascending: true);
      final menu = await db.from('menu_items').select();
      final tops = await db.from('toppings').select().order('sort_order', ascending: true);
      final staff = await db.from('staff').select().order('sort_order', ascending: true);
      if (!mounted) return;
      setState(() {
        _expenses = List<Map<String, dynamic>>.from(exp);
        _vouchers = List<Map<String, dynamic>>.from(vou);
        _menu = sortMenu(menu.map((e) => MenuItem.fromDb(e)).toList());
        _toppings = tops.map((e) => Topping.fromDb(e)).toList();
        _staff = List<Map<String, dynamic>>.from(staff);
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  Future<void> _loadMonthOrders({bool force = false}) async {
    final month = DateTime(_selectedDate.year, _selectedDate.month, 1);
    if (!force && _loadedMonth == month) return;
    try {
      final end = DateTime(month.year, month.month + 1, 1);
      final rows = await db
          .from('orders')
          .select('id, status, total, total_cost, created_at, payment_method, paid_at, order_items(quantity)')
          .inFilter('status', ['pending', 'served'])
          .gte('created_at', month.toUtc().toIso8601String())
          .lt('created_at', end.toUtc().toIso8601String());
      if (!mounted) return;
      setState(() {
        _monthOrders = List<Map<String, dynamic>>.from(rows);
        _loadedMonth = month;
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  /// Chạy một thao tác ghi dữ liệu, báo lỗi rõ ràng, rồi tải lại.
  Future<bool> _run(Future<void> Function() op, {String? okMsg}) async {
    try {
      await op();
      await _loadData();
      if (mounted && okMsg != null) showSnack(context, okMsg);
      return true;
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppColors.border, height: 1)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain, size: 18), onPressed: () => Navigator.pop(context)),
        title: const Text('Quản Trị Quán', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
        actions: [
          const Center(child: LiveClock(showDate: false, size: 24)),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Quầy pha chế',
            icon: const Icon(Icons.coffee_maker_outlined, color: AppColors.textMain),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BaristaScreen())),
          ),
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.textMain), onPressed: _reloadAll),
        ],
      ),
      body: AppBackground(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) errorBanner(_error!, onRetry: _reloadAll),
                      _subNav(),
                      const SizedBox(height: 20),
                      _tabContent(),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _subNav() {
    final items = <(String, IconData)>[
      ('Tổng quan', Icons.show_chart),
      ('Hóa đơn', Icons.receipt_long),
      ('Sổ chi phí', Icons.attach_money),
      ('Giảm giá', Icons.percent),
      ('Menu & Giá', Icons.menu_book),
      ('Nhân viên', Icons.badge_outlined),
      ('Mã QR bàn', Icons.qr_code),
      ('Cài đặt', Icons.settings_outlined),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF3EDE4), borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((it) {
            final sel = _tab == it.$1;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _tab = it.$1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: sel ? AppColors.baristaGreen : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(it.$2, size: 15, color: sel ? Colors.white : const Color(0xFF706A63)),
                    const SizedBox(width: 6),
                    Text(it.$1, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.w500, color: sel ? Colors.white : const Color(0xFF706A63))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab) {
      case 'Hóa đơn':
        return _billsTab();
      case 'Sổ chi phí':
        return _expenseTab();
      case 'Giảm giá':
        return _voucherTab();
      case 'Menu & Giá':
        return _menuTab();
      case 'Nhân viên':
        return _staffTab();
      case 'Mã QR bàn':
        return _qrTab();
      case 'Cài đặt':
        return _settingsTab();
      default:
        return _overviewTab();
    }
  }

  Widget _panel({required String title, String? subtitle, Widget? action, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ],
              ),
              if (action != null) action,
            ],
          ),
          const Divider(height: 28),
          ...children,
        ],
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onTap, [IconData icon = Icons.add]) => ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.baristaGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: onTap,
      );

  // ---------------------------- TỔNG QUAN ----------------------------
  Widget _overviewTab() {
    final dim = daysInMonth(_selectedDate);
    int cupsOf(Map<String, dynamic> o) => (o['order_items'] as List? ?? []).fold<int>(0, (s, i) => s + toInt((i as Map)['quantity'], 1));

    // Số liệu cả tháng (dùng cho biểu đồ & mốc hòa vốn)
    final dailyRevenue = List<int>.filled(dim, 0);
    int monthCups = 0, monthRev = 0, monthCogs = 0;
    for (final o in _monthOrders) {
      final d = parseLocal(o['created_at']);
      final rev = toInt(o['total']);
      monthCups += cupsOf(o);
      monthRev += rev;
      monthCogs += toInt(o['total_cost']);
      if (d != null && d.day <= dim) dailyRevenue[d.day - 1] += rev;
    }

    // Số liệu của kỳ đang xem
    final period = _isDailyView
        ? _monthOrders.where((o) {
            final d = parseLocal(o['created_at']);
            return d != null && d.day == _selectedDate.day;
          }).toList()
        : _monthOrders;
    final cups = period.fold<int>(0, (s, o) => s + cupsOf(o));
    final revenue = period.fold<int>(0, (s, o) => s + toInt(o['total']));
    final cogs = period.fold<int>(0, (s, o) => s + toInt(o['total_cost']));
    final operating = _isDailyView ? (_totalExpense / dim).round() : _totalExpense;
    final net = revenue - cogs - operating;
    final cashRev = period.where((o) => o['payment_method'] == 'cash').fold<int>(0, (s, o) => s + toInt(o['total']));
    final transferRev = period.where((o) => o['payment_method'] != 'cash').fold<int>(0, (s, o) => s + toInt(o['total']));

    // Mốc hòa vốn tự tính = chi phí cố định / lãi gộp trung bình mỗi ly
    double avgMargin;
    if (monthCups > 0) {
      avgMargin = (monthRev - monthCogs) / monthCups;
    } else if (_menu.isNotEmpty) {
      avgMargin = _menu.fold<int>(0, (s, m) => s + (m.priceM - m.costM)) / _menu.length;
    } else {
      avgMargin = 0;
    }
    final breakEvenMonth = avgMargin > 0 ? (_totalExpense / avgMargin).ceil() : 0;
    final breakEvenDay = (breakEvenMonth / dim).ceil();
    final target = _isDailyView ? breakEvenDay : breakEvenMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _filterButton('Theo ngày', _isDailyView, () => setState(() => _isDailyView = true)),
            _filterButton('Theo tháng', !_isDailyView, () => setState(() => _isDailyView = false)),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2024), lastDate: DateTime(2035));
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _loadMonthOrders();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isDailyView ? fmtDate(_selectedDate) : 'Tháng ${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                    const SizedBox(width: 10),
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('* Tính đơn chuyển khoản và tiền mặt đã gọi (không tính đơn đã hủy).', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, box) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statBox(box.maxWidth, Icons.coffee, 'SỐ LY ĐÃ BÁN', '$cups'),
              _statBox(box.maxWidth, Icons.receipt_long, 'DOANH THU', '${formatMoney(revenue)}đ'),
              _statBox(box.maxWidth, Icons.electric_bolt, 'CHI PHÍ NVL\n(COGS)', '${formatMoney(cogs)}đ'),
              _statBox(box.maxWidth, Icons.store, _isDailyView ? 'CHI PHÍ VẬN HÀNH\nPHÂN BỔ/NGÀY' : 'CHI PHÍ VẬN HÀNH\nTHÁNG', '${formatMoney(operating)}đ'),
              _statBox(box.maxWidth, Icons.trending_up, 'LỢI NHUẬN RÒNG', '${formatMoney(net)}đ', negative: net < 0),
            ],
          );
        }),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _payBox('💳 Chuyển khoản', transferRev, () => setState(() { _tab = 'Hóa đơn'; _billMode = 'transfer'; })),
            _payBox('💵 Tiền mặt', cashRev, () => setState(() { _tab = 'Hóa đơn'; _billMode = 'cash'; })),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFFFFFBF7), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF1E6D8))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.track_changes, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_isDailyView ? 'Tiến độ hòa vốn trong ngày' : 'Tiến độ hòa vốn trong tháng',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain)),
                  ),
                  Text('$cups / $target ly', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: target > 0 ? (cups / target).clamp(0.0, 1.0).toDouble() : 0.0,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFEFE8E0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2B1E16)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Mốc tự tính: chi phí cố định ${formatMoney(_totalExpense)}đ/tháng ÷ lãi gộp TB ${formatMoney(avgMargin)}đ/ly '
                '= $breakEvenMonth ly/tháng (~$breakEvenDay ly/ngày)'
                '${monthCups == 0 ? ' — đang ước tính theo giá menu vì tháng này chưa có đơn.' : ''}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFFFFFBF7), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF1E6D8))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doanh thu theo ngày — tháng ${_selectedDate.month}/${_selectedDate.year} (triệu đồng)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMain)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(painter: RevenueChartPainter(values: dailyRevenue, highlightDay: _isDailyView ? _selectedDate.day : 0)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterButton(String label, bool selected, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textMain)),
        ),
      );

  Widget _statBox(double w, IconData icon, String label, String value, {bool negative = false}) {
    final width = w > 600 ? (w - 40) / 5 : (w - 10) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFFBF7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1E6D8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8C7F72))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: negative ? const Color(0xFFD6453D) : AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ---------------------------- SỔ HÓA ĐƠN ----------------------------
  DateTime _billDate = DateTime.now();
  bool _billWholeMonth = false;
  String _billMode = 'transfer'; // transfer | cash
  List<Map<String, dynamic>> _bills = [];
  bool _billsLoading = false;
  String? _billsLoadedKey;

  String get _billKey => '${_billDate.year}-${_billDate.month}-${_billWholeMonth ? 0 : _billDate.day}';

  Future<void> _loadBills() async {
    setState(() {
      _billsLoading = true;
      _billsLoadedKey = _billKey;
    });
    try {
      final start = _billWholeMonth ? DateTime(_billDate.year, _billDate.month, 1) : DateTime(_billDate.year, _billDate.month, _billDate.day);
      final end = _billWholeMonth ? DateTime(start.year, start.month + 1, 1) : start.add(const Duration(days: 1));
      final s = start.toUtc().toIso8601String();
      final e = end.toUtc().toIso8601String();
      final rows = await db.from('orders').select('*, order_items(*)').gte('created_at', s).lt('created_at', e).order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _bills = List<Map<String, dynamic>>.from(rows);
      });
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _billsLoading = false);
    }
  }

  Widget _billsTab() {
    if (_billsLoadedKey != _billKey && !_billsLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _billsLoadedKey != _billKey) _loadBills();
      });
    }
    bool counted(Map<String, dynamic> o) => o['status'] != 'cancelled' && !(o['payment_method'] == 'transfer' && o['paid_at'] == null);
    int sum(List<Map<String, dynamic>> l) => l.where(counted).fold<int>(0, (s, o) => s + toInt(o['total']));
    final transfer = _bills.where((o) => o['payment_method'] == 'transfer').toList();
    final cash = _bills.where((o) => o['payment_method'] == 'cash').toList();
    final list = _billMode == 'cash' ? cash : transfer;
    final unpaidCash = cash.where((o) => o['status'] != 'cancelled' && o['paid_at'] == null).length;

    return _panel(
      title: 'Sổ hóa đơn',
      subtitle: 'Hóa đơn tách riêng Chuyển khoản / Tiền mặt. Bấm vào một dòng để xem bill chi tiết.',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _filterButton('Theo ngày', !_billWholeMonth, () => setState(() => _billWholeMonth = false)),
          _filterButton('Cả tháng', _billWholeMonth, () => setState(() => _billWholeMonth = true)),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 14),
            label: Text(_billWholeMonth ? 'Tháng ${_billDate.month}/${_billDate.year}' : fmtDate(_billDate)),
            onPressed: () async {
              final p = await showDatePicker(context: context, initialDate: _billDate, firstDate: DateTime(2024), lastDate: DateTime(2035));
              if (p != null) setState(() => _billDate = p);
            },
          ),
          IconButton(tooltip: 'Tải lại', icon: const Icon(Icons.refresh), onPressed: _loadBills),
        ],
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _modeChip('transfer', '💳 Chuyển khoản', '${transfer.length} đơn • ${formatMoney(sum(transfer))}đ'),
            _modeChip('cash', '💵 Tiền mặt', '${cash.length} đơn • ${formatMoney(sum(cash))}đ'),
          ],
        ),
        if (_billMode == 'cash' && unpaidCash > 0) ...[
          const SizedBox(height: 10),
          noteBox('Có $unpaidCash đơn tiền mặt chưa được đánh dấu "đã thu tiền".', color: AppColors.danger),
        ],
        const SizedBox(height: 12),
        if (_billsLoading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Không có hóa đơn trong khoảng thời gian này.', style: TextStyle(color: AppColors.textMuted))),
          )
        else
          ...list.map(_billTile),
      ],
    );
  }

  Widget _modeChip(String mode, String title, String sub) {
    final sel = _billMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _billMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: sel ? Colors.white : AppColors.textMain)),
            Text(sub, style: TextStyle(fontSize: 12, color: sel ? Colors.white70 : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _billTile(Map<String, dynamic> o) {
    final created = parseLocal(o['created_at']);
    final items = orderItemsOf(o);
    final summary = items.map((i) => '${toInt(i['quantity'], 1)}× ${i['item_name']}').join(', ');
    final status = o['status'];
    final paid = isPaid(o);
    String label;
    Color color;
    if (status == 'cancelled') {
      label = 'Đã hủy';
      color = AppColors.danger;
    } else if (paid) {
      label = o['payment_method'] == 'cash' ? 'Đã thu' : (o['paid_via'] == 'customer' ? 'Khách báo đã CK' : 'Đã CK');
      color = AppColors.baristaGreen;
    } else {
      label = o['payment_method'] == 'cash' ? 'Chưa thu' : 'Chờ CK';
      color = const Color(0xFFB26A00);
    }
    final time = created == null ? '' : (_billWholeMonth ? '${fmtTime(created)} ${fmtDate(created)}' : fmtTime(created));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: ListTile(
        onTap: () => showBillDialog(context, o),
        leading: CircleAvatar(
          backgroundColor: AppColors.accentLight,
          child: Text('${o['table_number']}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
        title: Text('#${o['code']}  •  $time', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        subtitle: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${formatMoney(toInt(o['total']))}đ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, decoration: status == 'cancelled' ? TextDecoration.lineThrough : null),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(6)),
              child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payBox(String label, int amount, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Text('${formatMoney(amount)}đ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ]),
        ),
      );

  // ---------------------------- CHI PHÍ ----------------------------
  Widget _expenseTab() {
    return _panel(
      title: 'Dự toán chi phí hằng tháng (${formatMoney(_totalExpense)}đ)',
      subtitle: 'Chi phí vận hành & định phí định kỳ — bấm vào dòng để sửa',
      action: _addButton('Thêm chi phí', () => _expenseDialog()),
      children: _expenses.map((e) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => _expenseDialog(e),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.receipt_outlined, color: AppColors.accent),
          ),
          title: Text(e['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('${e['description']} • ${e['type']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('-${formatMoney(toInt(e['amount']))}đ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: () async {
                  if (await confirmDialog(context, title: 'Xóa khoản chi?', message: e['name'].toString(), okLabel: 'Xóa', danger: true)) {
                    _run(() => db.from('expenses').delete().eq('id', e['id']));
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _expenseDialog([Map<String, dynamic>? e]) {
    final name = TextEditingController(text: e?['name']?.toString() ?? '');
    final desc = TextEditingController(text: e?['description']?.toString() ?? '');
    final amount = TextEditingController(text: e == null ? '' : toInt(e['amount']).toString());
    String type = e?['type']?.toString() ?? 'Vận hành';
    const types = ['Cố định', 'Lương', 'Vận hành', 'Dịch vụ', 'Phát sinh'];
    if (!types.contains(type)) type = 'Vận hành';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(e == null ? 'Thêm khoản chi phí' : 'Sửa khoản chi phí', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fieldLabel('Tên khoản chi'),
                TextField(controller: name, decoration: inputDeco('Mua đá viên...')),
                fieldLabel('Số tiền mỗi tháng (đ)'),
                numberField(amount, '1500000'),
                fieldLabel('Phân loại'),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: inputDeco(),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setD(() => type = v ?? type),
                ),
                fieldLabel('Diễn giải'),
                TextField(controller: desc, decoration: inputDeco()),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.baristaGreen, foregroundColor: Colors.white),
              onPressed: () async {
                final a = int.tryParse(amount.text) ?? 0;
                if (name.text.trim().isEmpty || a <= 0) {
                  showSnack(context, 'Nhập tên và số tiền lớn hơn 0.', error: true);
                  return;
                }
                final data = {'name': name.text.trim(), 'description': desc.text.trim(), 'type': type, 'amount': a};
                final ok = await _run(() => e == null ? db.from('expenses').insert(data) : db.from('expenses').update(data).eq('id', e['id']));
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------- VOUCHER ----------------------------
  Widget _voucherTab() {
    return _panel(
      title: 'Chương trình khuyến mãi & voucher',
      subtitle: 'Khách nhập mã ở giỏ hàng — hệ thống tự kiểm tra điều kiện và tính giảm giá',
      action: _addButton('Tạo mã mới', () => _voucherDialog()),
      children: _vouchers.map((v) {
        final active = v['active'] == true;
        final pct = toInt(v['discount_percent']);
        final amt = toInt(v['discount_amount']);
        final rule = [
          if (pct > 0) 'Giảm $pct%',
          if (amt > 0) 'Giảm ${formatMoney(amt)}đ',
          if (v['max_discount'] != null) 'tối đa ${formatMoney(toInt(v['max_discount']))}đ',
          if (toInt(v['min_order']) > 0) 'đơn từ ${formatMoney(toInt(v['min_order']))}đ',
          if (v['start_hour'] != null && v['end_hour'] != null) '${v['start_hour']}h–${v['end_hour']}h',
        ].join(' • ');
        return ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => _voucherDialog(v),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(6)),
            child: Text(v['code'].toString(), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          title: Text(v['description'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          subtitle: Text(rule, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: active,
                activeColor: AppColors.baristaGreen,
                onChanged: (val) => _run(() => db.from('vouchers').update({'active': val}).eq('code', v['code'])),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: () async {
                  if (await confirmDialog(context, title: 'Xóa mã ${v['code']}?', message: 'Khách sẽ không dùng được mã này nữa.', okLabel: 'Xóa', danger: true)) {
                    _run(() => db.from('vouchers').delete().eq('code', v['code']));
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _voucherDialog([Map<String, dynamic>? v]) {
    final isNew = v == null;
    final code = TextEditingController(text: v?['code']?.toString() ?? '');
    final desc = TextEditingController(text: v?['description']?.toString() ?? '');
    final pct = TextEditingController(text: v == null ? '' : toInt(v['discount_percent']).toString());
    final amt = TextEditingController(text: v == null ? '' : toInt(v['discount_amount']).toString());
    final maxD = TextEditingController(text: v?['max_discount']?.toString() ?? '');
    final minO = TextEditingController(text: v == null ? '' : toInt(v['min_order']).toString());
    final startH = TextEditingController(text: v?['start_hour']?.toString() ?? '');
    final endH = TextEditingController(text: v?['end_hour']?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(isNew ? 'Tạo mã khuyến mãi' : 'Sửa mã ${v['code']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fieldLabel('Mã voucher'),
                TextField(controller: code, enabled: isNew, textCapitalization: TextCapitalization.characters, decoration: inputDeco('COFFEE20')),
                fieldLabel('Mô tả hiển thị'),
                TextField(controller: desc, decoration: inputDeco('Giảm 20% cho mọi đơn')),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Giảm %'), numberField(pct, '0')])),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Giảm tiền (đ)'), numberField(amt, '0')])),
                ]),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Giảm tối đa (đ)'), numberField(maxD, 'bỏ trống = không giới hạn')])),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Đơn tối thiểu (đ)'), numberField(minO, '0')])),
                ]),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Từ giờ (0-23)'), numberField(startH, 'cả ngày')])),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Đến giờ (1-24)'), numberField(endH, 'cả ngày')])),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              final c = code.text.trim().toUpperCase();
              final p = int.tryParse(pct.text) ?? 0;
              final a = int.tryParse(amt.text) ?? 0;
              final sH = int.tryParse(startH.text);
              final eH = int.tryParse(endH.text);
              if (c.isEmpty || (p == 0 && a == 0) || p > 100) {
                showSnack(context, 'Nhập mã và mức giảm hợp lệ (% từ 1–100 hoặc số tiền).', error: true);
                return;
              }
              if ((sH == null) != (eH == null) || (sH != null && eH != null && (sH < 0 || sH > 23 || eH < 1 || eH > 24 || sH >= eH))) {
                showSnack(context, 'Khung giờ chưa hợp lệ (nhập cả hai, giờ bắt đầu < giờ kết thúc).', error: true);
                return;
              }
              final data = {
                'code': c,
                'description': desc.text.trim(),
                'discount_percent': p,
                'discount_amount': a,
                'max_discount': int.tryParse(maxD.text),
                'min_order': int.tryParse(minO.text) ?? 0,
                'start_hour': sH,
                'end_hour': eH,
              };
              final ok = await _run(() => isNew ? db.from('vouchers').insert(data) : db.from('vouchers').update(data).eq('code', c));
              if (ok && ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ---------------------------- MENU & TOPPING ----------------------------
  Widget _menuTab() {
    return Column(
      children: [
        _panel(
          title: 'Danh mục món & giá vốn (COGS)',
          subtitle: 'COGS nên gồm cả bao bì (ly, nắp, ống hút...). Tắt công tắc = tạm hết món.',
          action: _addButton('Thêm món mới', () => _menuItemDialog(), Icons.add_photo_alternate),
          children: _menu.map((m) {
            final marginM = m.priceM > 0 ? ((m.priceM - m.costM) / m.priceM * 100).toStringAsFixed(1) : '0';
            final marginL = m.priceL > 0 ? ((m.priceL - m.costL) / m.priceL * 100).toStringAsFixed(1) : '0';
            return Opacity(
              opacity: m.available ? 1.0 : 0.5,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _menuItemDialog(m),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(m.imageUrl, width: 44, height: 44, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 44, height: 44, color: AppColors.background, child: const Icon(Icons.coffee, size: 20, color: AppColors.textMuted))),
                ),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(
                  '${m.category}\nM: ${formatMoney(m.priceM)}đ (vốn ${formatMoney(m.costM)}đ, lãi $marginM%) • L: ${formatMoney(m.priceL)}đ (vốn ${formatMoney(m.costL)}đ, lãi $marginL%)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: m.available,
                      activeColor: AppColors.baristaGreen,
                      onChanged: (v) => _run(() => db.from('menu_items').update({'available': v}).eq('id', m.id)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                      onPressed: () async {
                        if (await confirmDialog(context, title: 'Xóa món "${m.name}"?', message: 'Nếu chỉ tạm hết, hãy tắt công tắc thay vì xóa.', okLabel: 'Xóa', danger: true)) {
                          _run(() => db.from('menu_items').delete().eq('id', m.id), okMsg: 'Đã xóa ${m.name}');
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _panel(
          title: 'Topping',
          subtitle: 'Bấm để sửa giá; tắt công tắc khi hết topping',
          action: _addButton('Thêm topping', () => _toppingDialog()),
          children: _toppings.map((t) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => _toppingDialog(t),
              title: Text(t.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.available ? AppColors.textMain : AppColors.textMuted)),
              subtitle: Text('Giá bán ${formatMoney(t.price)}đ • Vốn ${formatMoney(t.cost)}đ', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: t.available,
                    activeColor: AppColors.baristaGreen,
                    onChanged: (v) => _run(() => db.from('toppings').update({'available': v}).eq('id', t.id)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                    onPressed: () async {
                      if (await confirmDialog(context, title: 'Xóa topping?', message: t.name, okLabel: 'Xóa', danger: true)) {
                        _run(() => db.from('toppings').delete().eq('id', t.id));
                      }
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _menuItemDialog([MenuItem? m]) {
    final isNew = m == null;
    final name = TextEditingController(text: m?.name ?? '');
    final image = TextEditingController(text: m?.imageUrl ?? '');
    final pM = TextEditingController(text: m?.priceM.toString() ?? '');
    final pL = TextEditingController(text: m?.priceL.toString() ?? '');
    final cM = TextEditingController(text: m?.costM.toString() ?? '');
    final cL = TextEditingController(text: m?.costL.toString() ?? '');
    final cats = {...AppConfig.defaultCategories, ..._menu.map((e) => e.category)}.toList();
    String category = m?.category ?? cats.first;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(isNew ? 'Thêm món mới' : 'Sửa: ${m.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Tên món'),
                  TextField(controller: name, decoration: inputDeco()),
                  fieldLabel('Nhóm món'),
                  DropdownButtonFormField<String>(
                    value: category,
                    isExpanded: true,
                    decoration: inputDeco(),
                    items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setD(() => category = v ?? category),
                  ),
                  fieldLabel('Link ảnh (URL)'),
                  TextField(controller: image, decoration: inputDeco('https://...')),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Giá bán M'), numberField(pM)])),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Giá bán L'), numberField(pL)])),
                  ]),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Giá vốn M'), numberField(cM)])),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [fieldLabel('Giá vốn L'), numberField(cL)])),
                  ]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.baristaGreen, foregroundColor: Colors.white),
              onPressed: () async {
                final priceM = int.tryParse(pM.text) ?? 0;
                final priceL = int.tryParse(pL.text) ?? 0;
                if (name.text.trim().isEmpty || priceM <= 0 || priceL <= 0) {
                  showSnack(context, 'Nhập tên món và giá bán M, L.', error: true);
                  return;
                }
                final item = MenuItem(
                  id: m?.id ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
                  name: name.text.trim(),
                  category: category,
                  priceM: priceM,
                  priceL: priceL,
                  costM: int.tryParse(cM.text) ?? 0,
                  costL: int.tryParse(cL.text) ?? 0,
                  imageUrl: image.text.trim(),
                  available: m?.available ?? true,
                  sortOrder: m?.sortOrder ?? (_menu.isEmpty ? 1 : _menu.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1),
                );
                final ok = await _run(() => db.from('menu_items').upsert(item.toDb()), okMsg: 'Đã lưu ${item.name}');
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _toppingDialog([Topping? t]) {
    final name = TextEditingController(text: t?.name ?? '');
    final price = TextEditingController(text: t?.price.toString() ?? '');
    final cost = TextEditingController(text: t?.cost.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(t == null ? 'Thêm topping' : 'Sửa topping', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fieldLabel('Tên topping'),
            TextField(controller: name, decoration: inputDeco('Thạch dừa (50g)')),
            fieldLabel('Giá bán (đ)'),
            numberField(price),
            fieldLabel('Giá vốn (đ)'),
            numberField(cost),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.baristaGreen, foregroundColor: Colors.white),
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final data = {
                'id': t?.id ?? 'tp_${DateTime.now().millisecondsSinceEpoch}',
                'name': name.text.trim(),
                'price': int.tryParse(price.text) ?? 0,
                'cost': int.tryParse(cost.text) ?? 0,
                'available': t?.available ?? true,
                'sort_order': t?.sortOrder ?? _toppings.length + 1,
              };
              final ok = await _run(() => db.from('toppings').upsert(data));
              if (ok && ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ---------------------------- NHÂN VIÊN ----------------------------
  Widget _staffTab() {
    return _panel(
      title: 'Danh sách nhân viên',
      subtitle: 'Hồ sơ & ca làm việc. Tài khoản đăng nhập POS tạo trong Supabase → Authentication.',
      action: _addButton('Thêm nhân sự', () => _staffDialog(), Icons.person_add_alt),
      children: _staff.asMap().entries.map((entry) {
        final s = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accentLight,
                child: Text('${entry.key + 1}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s['name']}${(s['code'] ?? '').toString().isNotEmpty ? '  •  Mã NV: ${s['code']}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('${s['role']} • Ca: ${s['shift']}', style: const TextStyle(fontSize: 12)),
                    Text('SĐT: ${s['phone']} • Ngày sinh: ${s['dob']}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              TextButton.icon(icon: const Icon(Icons.edit, size: 14), label: const Text('Sửa'), onPressed: () => _staffDialog(s)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Xóa nhân viên (đã nghỉ)',
                onPressed: () async {
                  if (await confirmDialog(context, title: 'Xóa ${s['name']}?', message: 'Hồ sơ nhân viên sẽ bị xóa.', okLabel: 'Xóa', danger: true)) {
                    _run(() => db.from('staff').delete().eq('id', s['id']));
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _staffDialog([Map<String, dynamic>? s]) {
    final name = TextEditingController(text: s?['name']?.toString() ?? '');
    final code = TextEditingController(text: s?['code']?.toString() ?? '');
    final phone = TextEditingController(text: s?['phone']?.toString() ?? '');
    final dob = TextEditingController(text: s?['dob']?.toString() ?? '');
    final shift = TextEditingController(text: s?['shift']?.toString() ?? '');
    const roles = ['Quản lý', 'Trưởng quầy', 'Pha chế chính', 'Nhân viên phụ hỗ trợ'];
    String role = s?['role']?.toString() ?? 'Pha chế chính';
    if (!roles.contains(role)) role = 'Pha chế chính';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(s == null ? 'Thêm nhân sự' : 'Sửa: ${s['name']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Họ tên'),
                  TextField(controller: name, decoration: inputDeco()),
                  fieldLabel('Mã nhân viên'),
                  TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: inputDeco('PC999X')),
                  fieldLabel('Vị trí'),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: inputDeco(),
                    items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setD(() => role = v ?? role),
                  ),
                  fieldLabel('Số điện thoại'),
                  TextField(controller: phone, keyboardType: TextInputType.phone, decoration: inputDeco('09...')),
                  fieldLabel('Ngày sinh'),
                  TextField(controller: dob, decoration: inputDeco('dd/mm/yyyy')),
                  fieldLabel('Ca làm việc'),
                  TextField(controller: shift, decoration: inputDeco('Ca Sáng (06:30 - 14:30)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.baristaGreen, foregroundColor: Colors.white),
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  showSnack(context, 'Nhập họ tên.', error: true);
                  return;
                }
                final data = {
                  'name': name.text.trim(),
                  'code': code.text.trim().toUpperCase(),
                  'role': role,
                  'phone': phone.text.trim(),
                  'dob': dob.text.trim(),
                  'shift': shift.text.trim(),
                  if (s == null) 'sort_order': _staff.length + 1,
                };
                final ok = await _run(() => s == null ? db.from('staff').insert(data) : db.from('staff').update(data).eq('id', s['id']));
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------- MÃ QR BÀN ----------------------------
  String get _siteUrl => Uri.base.scheme.startsWith('http') ? '${Uri.base.origin}${Uri.base.path}' : AppConfig.fallbackSiteUrl;

  Widget _qrTab() {
    return _panel(
      title: 'Mã QR đặt món cho ${AppConfig.tableCount} bàn',
      subtitle: 'Khách quét bằng Zalo hoặc Camera để tự động nhận bàn. Bấm vào mã để phóng to / sao chép link.',
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(AppConfig.tableCount, (i) {
            final t = two(i + 1);
            final url = '$_siteUrl?table=$t';
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _largeQr(t, url),
              child: Container(
                width: 155,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                child: Column(
                  children: [
                    Image.network('https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${Uri.encodeComponent(url)}', width: 120, height: 120),
                    const SizedBox(height: 8),
                    Text('BÀN $t', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _largeQr(String t, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Center(child: Text('Mã QR Bàn $t', style: const TextStyle(fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network('https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=${Uri.encodeComponent(url)}', width: 240, height: 240),
            const SizedBox(height: 10),
            SelectableText(url, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (ctx.mounted) showSnack(ctx, 'Đã sao chép link bàn $t');
            },
            child: const Text('Sao chép link'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  // ---------------------------- CÀI ĐẶT ----------------------------
  Future<void> _checkConnection() async {
    setState(() => _connStatus = 'Đang kiểm tra...');
    try {
      await db.from('menu_items').select('id').limit(1);
      setState(() {
        _connOk = true;
        _connStatus = 'Kết nối bình thường (${fmtTime(DateTime.now())})';
      });
    } catch (e) {
      setState(() {
        _connOk = false;
        _connStatus = friendlyError(e);
      });
    }
  }

  Widget _settingsTab() {
    if (_connStatus == null) WidgetsBinding.instance.addPostFrameCallback((_) => _checkConnection());
    return _panel(
      title: 'Cài đặt hệ thống',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined, color: AppColors.accent),
          title: Text(AuthService.user?.email ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('Quyền: ${AuthService.role == 'admin' ? 'Quản lý' : 'Quầy bar'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          trailing: OutlinedButton.icon(
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Đăng xuất'),
            onPressed: () async {
              await AuthService.signOut();
              if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_reset, color: AppColors.accent),
          title: const Text('Đổi mật khẩu tài khoản của bạn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: const Text('Mật khẩu tài khoản nhân viên khác đổi trong Supabase → Authentication', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0),
            onPressed: _changePasswordDialog,
            child: const Text('Đổi mật khẩu'),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(_connOk ? Icons.cloud_done : Icons.cloud_off, color: _connOk ? Colors.green : AppColors.danger),
          title: const Text('Kết nối Supabase Cloud', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(_connStatus ?? '...', style: TextStyle(fontSize: 12, color: _connOk ? Colors.green : AppColors.danger)),
          trailing: TextButton(onPressed: _checkConnection, child: const Text('Kiểm tra lại')),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 10),
        const Text('Khu vực nguy hiểm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 4),
        const Text('Xóa toàn bộ đơn hàng (ví dụ đơn thử nghiệm). Menu, chi phí, nhân sự được giữ nguyên.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade700,
            elevation: 0,
            side: BorderSide(color: Colors.red.shade200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.delete_forever_outlined, size: 18),
          label: const Text('Xóa tất cả đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _deleteAllOrders,
        ),
      ],
    );
  }

  void _changePasswordDialog() {
    final p1 = TextEditingController();
    final p2 = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Đổi mật khẩu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fieldLabel('Mật khẩu mới (ít nhất 8 ký tự)'),
            TextField(controller: p1, obscureText: true, decoration: inputDeco()),
            fieldLabel('Nhập lại'),
            TextField(controller: p2, obscureText: true, decoration: inputDeco()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (p1.text.length < 8 || p1.text != p2.text) {
                showSnack(context, 'Mật khẩu phải từ 8 ký tự và hai lần nhập phải khớp.', error: true);
                return;
              }
              try {
                await db.auth.updateUser(UserAttributes(password: p1.text));
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showSnack(context, 'Đã đổi mật khẩu.');
              } catch (e) {
                if (mounted) showSnack(context, friendlyError(e), error: true);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllOrders() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Xóa TẤT CẢ đơn hàng?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.danger)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doanh thu và lịch sử đơn sẽ mất vĩnh viễn. Gõ XOA để xác nhận:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(controller: ctrl, textCapitalization: TextCapitalization.characters, decoration: inputDeco('XOA')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().toUpperCase() == 'XOA'),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await db.from('orders').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await _loadMonthOrders(force: true);
      if (mounted) showSnack(context, 'Đã xóa toàn bộ đơn hàng.');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }
}

// =====================================================================
//  BIỂU ĐỒ DOANH THU THEO NGÀY
// =====================================================================
class RevenueChartPainter extends CustomPainter {
  final List<int> values; // phần tử 0 = ngày 1
  final int highlightDay; // 0 = không tô
  RevenueChartPainter({required this.values, this.highlightDay = 0});

  static double _niceMax(double v) {
    if (v <= 0) return 1000000;
    final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final f = v / exp;
    final nf = f <= 1 ? 1 : (f <= 2 ? 2 : (f <= 5 ? 5 : 10));
    return nf * exp;
  }

  static String _label(double v) {
    final m = v / 1000000;
    final s = m.toStringAsFixed(m >= 10 ? 0 : 1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0, bottom = 22.0, top = 8.0, right = 10.0;
    final n = values.length;
    if (n == 0) return;
    final grid = Paint()
      ..color = const Color(0xFFE8DFD4)
      ..strokeWidth = 1;
    final line = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const ts = TextStyle(fontSize: 10, color: Color(0xFF9E9892));
    final maxV = _niceMax(values.fold<int>(0, (a, b) => a > b ? a : b).toDouble());
    final h = size.height - top - bottom;
    final w = size.width - left - right;

    for (int i = 0; i <= 4; i++) {
      final y = top + h - i * h / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      final tp = TextPainter(text: TextSpan(text: _label(maxV * i / 4), style: ts), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(left - tp.width - 6, y - 6));
    }

    double xOf(int day) => left + (n == 1 ? 0 : (day - 1) / (n - 1) * w);
    double yOf(int v) => top + h - (v / maxV).clamp(0.0, 1.0) * h;

    for (int d = 1; d <= n; d++) {
      if (d == 1 || d % 5 == 0 || d == n) {
        final tp = TextPainter(text: TextSpan(text: '$d', style: ts), textDirection: TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(xOf(d) - tp.width / 2, size.height - bottom + 6));
      }
    }

    final path = Path();
    for (int d = 1; d <= n; d++) {
      final p = Offset(xOf(d), yOf(values[d - 1]));
      if (d == 1) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = AppColors.accent;
    for (int d = 1; d <= n; d++) {
      if (values[d - 1] > 0) canvas.drawCircle(Offset(xOf(d), yOf(values[d - 1])), 2.5, dot);
    }
    if (highlightDay >= 1 && highlightDay <= n) {
      canvas.drawCircle(Offset(xOf(highlightDay), yOf(values[highlightDay - 1])), 5, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(covariant RevenueChartPainter old) => old.values != values || old.highlightDay != highlightDay;
}
