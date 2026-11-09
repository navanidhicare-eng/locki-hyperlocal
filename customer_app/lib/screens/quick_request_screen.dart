import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import 'order_tracking_screen.dart';

class QuickRequestScreen extends StatefulWidget {
  final ServiceCategory? preselectedCategory;
  final Map<String, dynamic>? preselectedProvider;

  const QuickRequestScreen({
    Key? key,
    this.preselectedCategory,
    this.preselectedProvider,
  }) : super(key: key);

  @override
  State<QuickRequestScreen> createState() => _QuickRequestScreenState();
}

class _QuickRequestScreenState extends State<QuickRequestScreen> {
  final ApiService _api = ApiService();

  List<ServiceCategory> _categories = [];
  bool _loadingCategories = true;

  ServiceCategory? _selectedCategory;
  Map<String, dynamic>? _selectedSubCategory;
  Map<String, dynamic>? _selectedChildTask;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(text: 'Station Road, Chodavaram Town');
  final TextEditingController _mandalController = TextEditingController(text: 'Chodavaram');
  final TextEditingController _phoneController = TextEditingController(text: '9010737882');
  final TextEditingController _nameController = TextEditingController(text: 'Gandepalli Prasad');

  String _selectedPaymentMethod = 'Cash on Service / Direct UPI';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final cats = await _api.fetchCategories();
    if (!mounted) return;

    setState(() {
      _categories = cats;
      _loadingCategories = false;

      if (widget.preselectedCategory != null) {
        _selectedCategory = cats.firstWhere(
          (c) => c.id == widget.preselectedCategory!.id,
          orElse: () => widget.preselectedCategory!,
        );
        _autoSelectFirstSub();
      } else if (cats.isNotEmpty) {
        _selectedCategory = cats.first;
        _autoSelectFirstSub();
      }
    });
  }

  void _autoSelectFirstSub() {
    if (_selectedCategory != null && _selectedCategory!.subCategories.isNotEmpty) {
      _selectedSubCategory = _selectedCategory!.subCategories.first;
      _autoSelectFirstChild();
    } else {
      _selectedSubCategory = null;
      _selectedChildTask = null;
    }
  }

  void _autoSelectFirstChild() {
    if (_selectedSubCategory != null &&
        _selectedSubCategory!['childCategories'] != null &&
        (_selectedSubCategory!['childCategories'] as List).isNotEmpty) {
      _selectedChildTask = (_selectedSubCategory!['childCategories'] as List).first;
    } else {
      _selectedChildTask = null;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _mandalController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service category')),
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your service address')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final res = await _api.submitQuickRequest(
      categoryId: _selectedCategory!.id,
      subCategoryId: _selectedSubCategory?['id']?.toString(),
      childTaskId: _selectedChildTask?['id']?.toString(),
      childTaskName: _selectedChildTask?['name']?.toString(),
      problemDescription: _descriptionController.text.trim(),
      customerAddress: _addressController.text.trim(),
      customerMandal: _mandalController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerName: _nameController.text.trim(),
      providerId: widget.preselectedProvider?['id']?.toString(),
      paymentMethod: _selectedPaymentMethod,
      amount: 0.0,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res != null && res['success'] == true && res['order'] != null) {
      final order = OrderModel.fromJson(res['order']);
      final matchedCount = res['matchedCount'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.preselectedProvider != null
              ? 'Request sent directly to ${widget.preselectedProvider!['name']}!'
              : (matchedCount > 0
                  ? 'Request broadcasted to $matchedCount active specialists in ${_mandalController.text}!'
                  : 'Request posted! Searching nearby specialists...'),
          ),
          backgroundColor: AppConstants.accentEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['message'] ?? 'Failed to send request. Please try again.'),
          backgroundColor: AppConstants.accentRose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDirectHire = widget.preselectedProvider != null;
    final subList = _selectedCategory?.subCategories ?? [];
    final childList = (_selectedSubCategory?['childCategories'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isDirectHire ? 'Direct Hire Specialist' : 'Quick Service Request',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.secondary,
        elevation: 0.5,
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Direct Hire Banner (if applicable)
                  if (isDirectHire)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppConstants.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_pin_rounded, color: AppConstants.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Direct Technician Booking',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                                ),
                                Text(
                                  widget.preselectedProvider!['name']?.toString() ?? 'Specialist',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  '📞 ${widget.preselectedProvider!['phone']} • ${widget.preselectedProvider!['mandal'] ?? 'Chodavaram'}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // STEP 1: Category Selection
                  _buildSectionHeader('1. Choose Service Category *', Icons.category_rounded),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ServiceCategory>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppConstants.primary),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<ServiceCategory>(
                            value: cat,
                            child: Row(
                              children: [
                                _buildCategoryThumb(cat),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                              _autoSelectFirstSub();
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // STEP 2: Sub-Category Selection
                  if (subList.isNotEmpty) ...[
                    _buildSectionHeader('2. Sub-Category / Trade Specialty *', Icons.layers_rounded),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          value: subList.contains(_selectedSubCategory) ? _selectedSubCategory : subList.first,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppConstants.primary),
                          items: subList.map((sub) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: sub,
                              child: Text(
                                sub['name']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSubCategory = val;
                                _autoSelectFirstChild();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // STEP 3: Child Task Selection (if available)
                  if (childList.isNotEmpty) ...[
                    _buildSectionHeader('3. Specific Task / Issue (Optional)', Icons.checklist_rounded),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: childList.map((ch) {
                        final isSelected = _selectedChildTask != null && _selectedChildTask!['id'] == ch['id'];
                        return ChoiceChip(
                          label: Text(
                            ch['name']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppConstants.primary,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppConstants.primary : const Color(0xFFCBD5E1),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedChildTask = selected ? ch : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // STEP 4: Problem Description
                  _buildSectionHeader('4. Describe Your Issue', Icons.description_rounded),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Water leaking from bathroom tap / DTH no-signal issue, need urgent service...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        contentPadding: EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // STEP 5: Service Location & Phone
                  _buildSectionHeader('5. Service Address & Location *', Icons.location_on_rounded),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Door No, Street & Landmark *',
                            labelStyle: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _mandalController,
                                decoration: const InputDecoration(
                                  labelText: 'Mandal / Town *',
                                  labelStyle: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Customer Phone *',
                                  labelStyle: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // STEP 6: Payment Preference
                  _buildSectionHeader('6. Payment Mode', Icons.payments_rounded),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppConstants.accentEmerald, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Cash on Service / Direct UPI',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Pay to Partner',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // SUBMIT ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Broadcasting to Specialists...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flash_on_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isDirectHire
                                      ? 'SEND DIRECT REQUEST TO ${widget.preselectedProvider!['name']?.toString().toUpperCase()}'
                                      : 'SEND SERVICE REQUEST NOW',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      '🔒 Verified Local Technicians • 0% Platform Cut • Fast Doorstep Service',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppConstants.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
      ],
    );
  }

  Widget _buildCategoryThumb(ServiceCategory cat) {
    if (cat.iconUrl != null && cat.iconUrl!.isNotEmpty) {
      return Image.network(
        cat.iconUrl!,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(cat.getIconData(), size: 20, color: cat.color),
      );
    }
    return Icon(cat.getIconData(), size: 20, color: cat.color);
  }
}

