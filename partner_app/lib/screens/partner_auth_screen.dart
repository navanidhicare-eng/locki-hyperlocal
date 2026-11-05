import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/partner_api_service.dart';
import 'partner_main_nav_screen.dart';

class PartnerAuthScreen extends StatefulWidget {
  const PartnerAuthScreen({Key? key}) : super(key: key);

  @override
  State<PartnerAuthScreen> createState() => _PartnerAuthScreenState();
}

class _PartnerAuthScreenState extends State<PartnerAuthScreen> {
  final PartnerApiService _api = PartnerApiService();

  bool _isLogin = true; // true = Login, false = Register
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Controllers for Login
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Controllers for Register
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regSkillController = TextEditingController();
  final TextEditingController _regAadhaarController = TextEditingController();
  String _selectedCategory = 'cat_plumbing';

  final List<Map<String, String>> _categories = const [
    {'id': 'cat_plumbing', 'name': '🔧 Plumbing Services'},
    {'id': 'cat_electrical', 'name': '⚡ Electrical & Wiring'},
    {'id': 'cat_cleaning', 'name': '✨ Home Deep Cleaning'},
    {'id': 'cat_appliances', 'name': '📺 AC & Appliance Repair'},
    {'id': 'cat_mechanic', 'name': '🚗 Bike & Car Mechanic'},
    {'id': 'cat_delivery', 'name': '📦 Hyperlocal Delivery'},
    {'id': 'cat_shops', 'name': '🛍️ Retail Merchant'},
  ];

  @override
  void dispose() {
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    _regSkillController.dispose();
    _regAadhaarController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final phone = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text;

    if (phone.isEmpty || password.isEmpty) {
      _showSnackbar('Please enter your mobile number and password', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await _api.loginPartner(phone: phone, password: password);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PartnerMainNavScreen()),
      );
    } else {
      _showSnackbar(result['message'] ?? 'Login failed', isError: true);
    }
  }

  void _handleRegister() async {
    final name = _regNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final password = _regPasswordController.text;
    final aadhaar = _regAadhaarController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackbar('Please fill all required fields (Name, Mobile, Password)', isError: true);
      return;
    }

    if (phone.length < 10) {
      _showSnackbar('Please enter a valid 10-digit mobile number', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await _api.registerPartner(
      name: name,
      phone: phone,
      password: password,
      category: 'services',
      serviceName: 'Service Specialist',
      aadhaarNumber: aadhaar.isNotEmpty ? aadhaar : 'PENDING_UPLOAD',
    );
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      _showSnackbar('Account created successfully! Welcome to Locki Partner Fleet.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PartnerMainNavScreen()),
      );
    } else {
      _showSnackbar(result['message'] ?? 'Registration failed', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : PartnerConstants.statusOnline,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Logo & Title
                  Center(
                    child: Image.asset(
                      PartnerConstants.logoAsset,
                      height: 54,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: PartnerConstants.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.flash_on_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4EF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFD3C2)),
                      ),
                      child: Text(
                        'PARTNER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: PartnerConstants.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '0% Commission • Yearly Subscription Fleet for Specialists',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // Segmented Switcher (Login / Register)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isLogin = true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLogin ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _isLogin
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              child: Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: _isLogin ? FontWeight.w700 : FontWeight.w600,
                                  color: _isLogin ? PartnerConstants.primary : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isLogin = false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isLogin ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_isLogin
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              child: Text(
                                'Register',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: !_isLogin ? FontWeight.w700 : FontWeight.w600,
                                  color: !_isLogin ? PartnerConstants.primary : const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // FORM CONTENT
                  if (_isLogin) _buildLoginForm() else _buildRegisterForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // LOGIN FORM
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mobile Number
        const Text(
          'Mobile Number',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _loginPhoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 14, color: Color(0xFF192338)),
          decoration: InputDecoration(
            hintText: 'Enter 10-digit mobile number',
            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20, color: Color(0xFF94A3B8)),
            prefixText: '+91 ',
            prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF192338), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: PartnerConstants.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Password
        const Text(
          'Password',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 14, color: Color(0xFF192338)),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: PartnerConstants.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 20),

        // Login Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: PartnerConstants.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'LOGIN TO DASHBOARD',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
        ),
        const SizedBox(height: 20),

        // Switch to Register
        Center(
          child: TextButton(
            onPressed: () => setState(() => _isLogin = false),
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Register Here',
                    style: TextStyle(color: PartnerConstants.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // REGISTER FORM
  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full Name
        const Text(
          'Full Name *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _regNameController,
          style: const TextStyle(fontSize: 14, color: Color(0xFF192338)),
          decoration: InputDecoration(
            hintText: 'e.g. Shiva Kumar',
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: PartnerConstants.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Mobile Number
        const Text(
          'Mobile Number *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _regPhoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 14, color: Color(0xFF192338)),
          decoration: InputDecoration(
            hintText: '10-digit mobile number',
            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20, color: Color(0xFF94A3B8)),
            prefixText: '+91 ',
            prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF192338), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: PartnerConstants.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),



        // Aadhaar Number
        const Text(
          'Aadhaar Number (KYC Verification)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _regAadhaarController,
          style: const TextStyle(fontSize: 14, color: Color(0xFF192338)),
          decoration: InputDecoration(
            hintText: 'e.g. 8492-4819-3019',
            prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: PartnerConstants.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),

        // Password
        const Text(
          'Password *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _regPasswordController,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 14, color: Color(0xFF192338)),
          decoration: InputDecoration(
            hintText: 'Create a secure password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: PartnerConstants.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 22),

        // Register Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: PartnerConstants.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'REGISTER AS PARTNER',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
        ),
        const SizedBox(height: 14),

        // Switch to Login
        Center(
          child: TextButton(
            onPressed: () => setState(() => _isLogin = true),
            child: RichText(
              text: TextSpan(
                text: 'Already registered? ',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Login with Mobile',
                    style: TextStyle(color: PartnerConstants.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
