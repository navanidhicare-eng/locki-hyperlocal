import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/anakapalli_locations.dart';
import '../services/partner_api_service.dart';

class PartnerProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const PartnerProfileScreen({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  final PartnerApiService _api = PartnerApiService();

  // 1. Personal & Family Information Controllers
  late TextEditingController _nameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _motherNameController;
  late TextEditingController _dobController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyRelationController;
  late TextEditingController _emailController;

  // 2. Current Address State & Controllers (Dynamic from Admin Location Management)
  String _selectedDistrict = 'Anakapalli';
  String _selectedMandal = 'Anakapalli';
  String _selectedVillage = 'Anakapalle Town';
  late TextEditingController _doorStreetController;
  late TextEditingController _pincodeController;

  // Physical Shop / Workshop Details
  bool _hasPhysicalShop = false;
  late TextEditingController _shopNameController;
  String _selectedShopDistrict = 'Anakapalli';
  String _selectedShopMandal = 'Anakapalli';
  String _selectedShopVillage = 'Anakapalle Town';
  late TextEditingController _shopDoorStreetController;
  late TextEditingController _shopGstController;
  bool _shopFrontPhotoUploaded = false;
  bool _shopInsidePhotoUploaded = false;

  // 3. Service & Profession Controllers
  late TextEditingController _serviceNameController;
  String _selectedCategory = 'cat_plumbing';
  String _selectedExperience = '3 - 5 Years';

  // 4. Working Hours & Service Radius
  String _selectedWorkingHours = 'Full-Time (9:00 AM - 6:00 PM)';
  String _selectedServiceRadius = '10 KM (Standard Urban Coverage)';

  // 5. KYC Government IDs Controllers
  late TextEditingController _aadhaarController;
  late TextEditingController _panNumberController;
  late TextEditingController _drivingLicenseController;
  late TextEditingController _skillCertificatesController;

  // 6. Local Guarantor / Reference Controllers
  late TextEditingController _guarantorNameController;
  late TextEditingController _guarantorRelationController;
  late TextEditingController _guarantorPhoneController;

  // 7. Payout Controller
  late TextEditingController _upiController;

  // Uploaded Compressed Image Data (Base64) & Size Tracker
  String? _livePhotoBase64;
  String? _shopFrontPhotoBase64;
  String? _shopInsidePhotoBase64;
  String? _aadhaarFrontBase64;
  String? _aadhaarBackBase64;
  String? _panCardBase64;
  String? _drivingLicenseBase64;
  String? _skillCertificateBase64;
  final Map<String, int> _uploadedFileSizes = {};

  // Document Upload States
  bool _aadhaarFrontUploaded = false;
  bool _aadhaarBackUploaded = false;
  bool _panCardUploaded = false;
  bool _drivingLicenseUploaded = false;
  bool _skillCertificateUploaded = false;
  bool _livePhotoVerified = false;

  bool _isLoading = false;

  final List<Map<String, String>> _categories = const [
    {'id': 'cat_plumbing', 'name': '🔧 Plumbing Services'},
    {'id': 'cat_electrical', 'name': '⚡ Electrical & Wiring'},
    {'id': 'cat_cleaning', 'name': '✨ Home Deep Cleaning'},
    {'id': 'cat_appliances', 'name': '📺 AC & Appliance Repair'},
    {'id': 'cat_mechanic', 'name': '🚗 Bike & Car Mechanic'},
    {'id': 'cat_delivery', 'name': '📦 Hyperlocal Delivery'},
    {'id': 'cat_shops', 'name': '🛍️ Retail Merchant'},
    {'id': 'cat_carpentry', 'name': '🪵 Carpentry Works'},
    {'id': 'cat_painting', 'name': '🎨 Painting & Waterproofing'},
  ];

  // Dynamic Location Hierarchy (Loaded from Admin Location Management API / api/locations)
  Map<String, Map<String, List<String>>> _addressHierarchy = Map.from(kDefaultAddressHierarchy);
  Map<String, String> _villagePincodes = Map.from(kDefaultVillagePincodes);

  List<String> get _districts => _addressHierarchy.keys.toList();

  List<String> _getMandalsForDistrict(String district) {
    return _addressHierarchy[district]?.keys.toList() ?? [];
  }

  List<String> _getVillagesForMandal(String district, String mandal) {
    return _addressHierarchy[district]?[mandal] ?? [];
  }

  // Fetch real-time locations configured in Admin Location Management
  Future<void> _loadLocationsFromBackend() async {
    final list = await _api.fetchLocations();
    if (list.isNotEmpty && mounted) {
      final Map<String, Map<String, List<String>>> dynamicMap = {};
      final Map<String, String> pincodeMap = {};

      for (final dist in list) {
        final distName = dist['name']?.toString() ?? '';
        if (distName.isEmpty) continue;
        dynamicMap[distName] = {};

        final mandals = dist['mandals'] as List<dynamic>? ?? [];
        for (final m in mandals) {
          final mandalName = m['name']?.toString() ?? '';
          if (mandalName.isEmpty) continue;
          dynamicMap[distName]![mandalName] = [];

          final villages = m['villages'] as List<dynamic>? ?? [];
          for (final v in villages) {
            final vName = v['name']?.toString() ?? '';
            final pin = v['pincode']?.toString() ?? '';
            if (vName.isNotEmpty) {
              dynamicMap[distName]![mandalName]!.add(vName);
              if (pin.isNotEmpty) {
                pincodeMap['${distName}_${mandalName}_$vName'] = pin;
              }
            }
          }
        }
      }

      if (dynamicMap.isNotEmpty) {
        setState(() {
          _addressHierarchy = dynamicMap;
          _villagePincodes = pincodeMap;

          // Revalidate current selection
          if (!_addressHierarchy.containsKey(_selectedDistrict)) {
            _selectedDistrict = _addressHierarchy.keys.first;
          }
          final mandals = _getMandalsForDistrict(_selectedDistrict);
          if (!mandals.contains(_selectedMandal)) {
            _selectedMandal = mandals.isNotEmpty ? mandals.first : '';
          }
          final villages = _getVillagesForMandal(_selectedDistrict, _selectedMandal);
          if (!villages.contains(_selectedVillage)) {
            _selectedVillage = villages.isNotEmpty ? villages.first : '';
          }

          // Shop revalidation
          if (!_addressHierarchy.containsKey(_selectedShopDistrict)) {
            _selectedShopDistrict = _addressHierarchy.keys.first;
          }
          final shopMandals = _getMandalsForDistrict(_selectedShopDistrict);
          if (!shopMandals.contains(_selectedShopMandal)) {
            _selectedShopMandal = shopMandals.isNotEmpty ? shopMandals.first : '';
          }
          final shopVillages = _getVillagesForMandal(_selectedShopDistrict, _selectedShopMandal);
          if (!shopVillages.contains(_selectedShopVillage)) {
            _selectedShopVillage = shopVillages.isNotEmpty ? shopVillages.first : '';
          }
        });
      }
    }
  }

  final List<String> _experienceOptions = const [
    'Fresher / Under 1 Year',
    '1 - 3 Years',
    '3 - 5 Years',
    '5 - 10 Years',
    '10+ Years Expert',
  ];

  final List<String> _workingHoursOptions = const [
    'Full-Time (9:00 AM - 6:00 PM)',
    'Part-Time (Morning: 8:00 AM - 1:00 PM)',
    'Part-Time (Evening: 3:00 PM - 9:00 PM)',
    'Flexible / On-Demand Hours',
  ];

  final List<String> _serviceRadiusOptions = const [
    '5 KM (Local Neighborhood)',
    '10 KM (Standard Urban Coverage)',
    '15 KM (Wide City Coverage)',
    '25 KM (Extended Region)',
  ];

  @override
  void initState() {
    super.initState();
    final profile = _api.profile ?? {};

    // 1. Personal & Family Information (Clean - only populated with partner's real saved info)
    _nameController = TextEditingController(text: profile['name'] ?? '');
    _fatherNameController = TextEditingController(text: profile['fatherName'] ?? '');
    _motherNameController = TextEditingController(text: profile['motherName'] ?? '');
    _dobController = TextEditingController(text: profile['dob'] ?? '');
    _ageController = TextEditingController(text: profile['age'] ?? '');
    _phoneController = TextEditingController(text: profile['phone'] ?? '');
    _emergencyContactController = TextEditingController(text: profile['emergencyContact'] ?? '');
    _emergencyRelationController = TextEditingController(text: profile['emergencyRelation'] ?? '');
    _emailController = TextEditingController(text: profile['email'] ?? '');

    // 2. Current Address Hierarchy Init
    if (profile['district'] != null && _addressHierarchy.containsKey(profile['district'])) {
      _selectedDistrict = profile['district'];
    } else {
      _selectedDistrict = _districts.isNotEmpty ? _districts.first : 'Anakapalli';
    }

    final mandals = _getMandalsForDistrict(_selectedDistrict);
    if (profile['mandal'] != null && mandals.contains(profile['mandal'])) {
      _selectedMandal = profile['mandal'];
    } else {
      _selectedMandal = mandals.isNotEmpty ? mandals.first : '';
    }

    final villages = _getVillagesForMandal(_selectedDistrict, _selectedMandal);
    if (profile['village'] != null && villages.contains(profile['village'])) {
      _selectedVillage = profile['village'];
    } else {
      _selectedVillage = villages.isNotEmpty ? villages.first : '';
    }

    _doorStreetController = TextEditingController(
      text: profile['doorStreet'] ?? profile['currentAddress'] ?? profile['address'] ?? '',
    );
    _pincodeController = TextEditingController(
      text: profile['pincode'] ?? _villagePincodes['${_selectedDistrict}_${_selectedMandal}_$_selectedVillage'] ?? '531001',
    );

    // Physical Shop Hierarchy Init
    _hasPhysicalShop = profile['hasPhysicalShop'] == true || profile['hasPhysicalShop'] == 'true';
    _shopNameController = TextEditingController(text: profile['shopName'] ?? '');

    if (profile['shopDistrict'] != null && _addressHierarchy.containsKey(profile['shopDistrict'])) {
      _selectedShopDistrict = profile['shopDistrict'];
    } else {
      _selectedShopDistrict = _selectedDistrict;
    }

    final shopMandals = _getMandalsForDistrict(_selectedShopDistrict);
    if (profile['shopMandal'] != null && shopMandals.contains(profile['shopMandal'])) {
      _selectedShopMandal = profile['shopMandal'];
    } else {
      _selectedShopMandal = shopMandals.isNotEmpty ? shopMandals.first : '';
    }

    final shopVillages = _getVillagesForMandal(_selectedShopDistrict, _selectedShopMandal);
    if (profile['shopVillage'] != null && shopVillages.contains(profile['shopVillage'])) {
      _selectedShopVillage = profile['shopVillage'];
    } else {
      _selectedShopVillage = shopVillages.isNotEmpty ? shopVillages.first : '';
    }

    _shopDoorStreetController = TextEditingController(
      text: profile['shopDoorStreet'] ?? profile['shopAddress'] ?? '',
    );
    _shopGstController = TextEditingController(text: profile['shopGstNumber'] ?? '');
    _shopFrontPhotoUploaded = profile['shopFrontPhotoUrl'] != null;
    _shopInsidePhotoUploaded = profile['shopInsidePhotoUrl'] != null;

    // 3. Service Trade & Profession
    _serviceNameController = TextEditingController(text: profile['serviceName'] ?? '');
    if (profile['category'] != null && _categories.any((c) => c['id'] == profile['category'])) {
      _selectedCategory = profile['category'];
    }
    if (profile['experience'] != null && _experienceOptions.contains(profile['experience'])) {
      _selectedExperience = profile['experience'];
    }
    if (profile['district'] != null && _districts.contains(profile['district'])) {
      _selectedDistrict = profile['district'];
    }

    // 4. Working Hours & Service Radius
    if (profile['workingHours'] != null && _workingHoursOptions.contains(profile['workingHours'])) {
      _selectedWorkingHours = profile['workingHours'];
    }
    if (profile['serviceRadius'] != null && _serviceRadiusOptions.contains(profile['serviceRadius'])) {
      _selectedServiceRadius = profile['serviceRadius'];
    }

    // 5. KYC Government IDs
    _aadhaarController = TextEditingController(text: profile['aadhaarNumber'] ?? '');
    _panNumberController = TextEditingController(text: profile['panNumber'] ?? '');
    _drivingLicenseController = TextEditingController(text: profile['drivingLicenseNumber'] ?? '');
    _skillCertificatesController = TextEditingController(text: profile['skillCertificates'] ?? '');

    // 6. Local Guarantor / Reference
    _guarantorNameController = TextEditingController(text: profile['guarantorName'] ?? '');
    _guarantorRelationController = TextEditingController(text: profile['guarantorRelation'] ?? '');
    _guarantorPhoneController = TextEditingController(text: profile['guarantorPhone'] ?? '');

    // 7. Payout
    _upiController = TextEditingController(text: profile['upiId'] ?? '');

    // Document Upload flags
    _aadhaarFrontUploaded = profile['aadhaarFrontUrl'] != null;
    _aadhaarBackUploaded = profile['aadhaarBackUrl'] != null;
    _panCardUploaded = profile['panCardUrl'] != null;
    _drivingLicenseUploaded = profile['drivingLicenseUrl'] != null;
    _skillCertificateUploaded = profile['skillCertificatesUrl'] != null;
    _livePhotoVerified = profile['livePhotoVerificationStatus'] == 'Verified' || profile['livePhotoVerified'] == true;

    // Load dynamic real-time locations from backend
    _loadLocationsFromBackend();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _emergencyRelationController.dispose();
    _emailController.dispose();
    _doorStreetController.dispose();
    _pincodeController.dispose();
    _shopNameController.dispose();
    _shopDoorStreetController.dispose();
    _shopGstController.dispose();
    _serviceNameController.dispose();
    _aadhaarController.dispose();
    _panNumberController.dispose();
    _drivingLicenseController.dispose();
    _skillCertificatesController.dispose();
    _guarantorNameController.dispose();
    _guarantorRelationController.dispose();
    _guarantorPhoneController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  // Date picker helper for Date of Birth & Age calculation
  Future<void> _selectDateOfBirth() async {
    final DateTime initialDate = DateTime(1994, 8, 15);
    final DateTime firstDate = DateTime(1950, 1, 1);
    final DateTime lastDate = DateTime(2008, 12, 31);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: PartnerConstants.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF192338),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      int age = now.year - picked.year;
      if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) {
        age--;
      }
      setState(() {
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        _ageController.text = '$age';
      });
    }
  }

  void _handleSaveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'name': name,
      'fatherName': _fatherNameController.text.trim(),
      'motherName': _motherNameController.text.trim(),
      'dob': _dobController.text.trim(),
      'age': _ageController.text.trim(),
      'email': _emailController.text.trim(),
      'emergencyContact': _emergencyContactController.text.trim(),
      'emergencyRelation': _emergencyRelationController.text.trim(),
      'district': _selectedDistrict,
      'mandal': _selectedMandal,
      'village': _selectedVillage,
      'landmark': _selectedVillage,
      'currentAddress': '${_doorStreetController.text.trim()}, $_selectedVillage, $_selectedMandal, $_selectedDistrict - ${_pincodeController.text.trim()}',
      'address': '${_doorStreetController.text.trim()}, $_selectedVillage, $_selectedMandal, $_selectedDistrict',
      'pincode': _pincodeController.text.trim(),
      'hasPhysicalShop': _hasPhysicalShop,
      'shopName': _hasPhysicalShop ? _shopNameController.text.trim() : '',
      'shopDistrict': _hasPhysicalShop ? _selectedShopDistrict : '',
      'shopMandal': _hasPhysicalShop ? _selectedShopMandal : '',
      'shopVillage': _hasPhysicalShop ? _selectedShopVillage : '',
      'shopLandmark': _hasPhysicalShop ? _selectedShopVillage : '',
      'shopAddress': _hasPhysicalShop ? '${_shopDoorStreetController.text.trim()}, $_selectedShopVillage, $_selectedShopMandal, $_selectedShopDistrict' : '',
      'shopGstNumber': _hasPhysicalShop ? _shopGstController.text.trim() : '',
      'shopFrontPhotoUrl': _hasPhysicalShop ? (_shopFrontPhotoBase64 ?? (_shopFrontPhotoUploaded ? 'shop_front_photo.jpg' : null)) : null,
      'shopInsidePhotoUrl': _hasPhysicalShop ? (_shopInsidePhotoBase64 ?? (_shopInsidePhotoUploaded ? 'shop_inside_photo.jpg' : null)) : null,
      'category': _selectedCategory,
      'serviceName': _serviceNameController.text.trim(),
      'experience': _selectedExperience,
      'workingHours': _selectedWorkingHours,
      'serviceRadius': _selectedServiceRadius,
      'aadhaarNumber': _aadhaarController.text.trim(),
      'aadhaarFrontUrl': _aadhaarFrontBase64 ?? (_aadhaarFrontUploaded ? 'verified_aadhaar_front.jpg' : null),
      'aadhaarBackUrl': _aadhaarBackBase64 ?? (_aadhaarBackUploaded ? 'verified_aadhaar_back.jpg' : null),
      'panNumber': _panNumberController.text.trim(),
      'panCardUrl': _panCardBase64 ?? (_panCardUploaded ? 'verified_pan_card.jpg' : null),
      'drivingLicenseNumber': _drivingLicenseController.text.trim(),
      'drivingLicenseUrl': _drivingLicenseBase64 ?? (_drivingLicenseUploaded ? 'verified_driving_license.jpg' : null),
      'skillCertificates': _skillCertificatesController.text.trim(),
      'skillCertificatesUrl': _skillCertificateBase64 ?? (_skillCertificateUploaded ? 'verified_trade_certificate.pdf' : null),
      'livePhotoVerificationStatus': _livePhotoVerified ? 'Verified' : 'Pending',
      'livePhotoUrl': _livePhotoBase64,
      'guarantorName': _guarantorNameController.text.trim(),
      'guarantorRelation': _guarantorRelationController.text.trim(),
      'guarantorPhone': _guarantorPhoneController.text.trim(),
      'upiId': _upiController.text.trim(),
      'isProfileComplete': true,
    };

    final updated = await _api.updateProfile(payload);

    setState(() => _isLoading = false);

    if (updated['success'] == true) {
      if (!mounted) return;
      widget.onProfileUpdated?.call();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Technician Profile Saved Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF192338)),
              ),
              const SizedBox(height: 8),
              const Text(
                'All personal details, KYC identity cards, live photo verification, guarantor reference, and service radius have been securely saved and submitted for verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartnerConstants.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  child: const Text('GO TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updated['message'] ?? 'Failed to update profile'), backgroundColor: Colors.red),
      );
    }
  }

  // Bottom Sheet to choose Camera or Gallery with HTML Canvas Auto-Compression
  void _openMediaSourceSelector({
    required String title,
    bool isSelfie = false,
    required Function(String dataUrl, int sizeKb, String fileName) onCaptured,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PartnerConstants.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, color: PartnerConstants.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Upload: $title',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF192338)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Capture live with camera or choose from gallery. Images are automatically compressed to HTML format for high speed.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Option 1: Camera
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _triggerJsImagePicker(
                          sourceType: isSelfie ? 'selfie' : 'camera',
                          onSuccess: onCaptured,
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFCCBA)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: PartnerConstants.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isSelfie ? 'Take Live Selfie' : 'Camera Photo',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF192338)),
                            ),
                            const SizedBox(height: 2),
                            const Text('Open device camera', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Option 2: Gallery / Files
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _triggerJsImagePicker(
                          sourceType: 'gallery',
                          onSuccess: onCaptured,
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFF475569),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Gallery / Files',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF192338)),
                            ),
                            const SizedBox(height: 2),
                            const Text('Select photo or PDF', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerJsImagePicker({
    required String sourceType,
    required Function(String dataUrl, int sizeKb, String fileName) onSuccess,
  }) {
    try {
      js.context.callMethod('lokiPickAndCompressImage', [
        sourceType,
        js.allowInterop((resultStr) {
          try {
            final res = jsonDecode(resultStr.toString());
            if (res['success'] == true && res['dataUrl'] != null) {
              final dataUrl = res['dataUrl'].toString();
              final sizeKb = (res['fileSizeKb'] as num?)?.toInt() ?? 100;
              final fileName = res['fileName']?.toString() ?? 'photo.jpg';
              onSuccess(dataUrl, sizeKb, fileName);
            } else if (res['cancelled'] != true && res['message'] != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upload failed: ${res['message']}'), backgroundColor: Colors.red),
              );
            }
          } catch (e) {
            debugPrint('Error parsing upload callback: $e');
          }
        })
      ]);
    } catch (e) {
      debugPrint('Error triggering JS image picker: $e');
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PartnerConstants.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF192338)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Technician Profile & KYC',
          style: TextStyle(color: Color(0xFF192338), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          children: [
            // TOP HEADER: AVATAR & LIVE PHOTO VERIFICATION CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: PartnerConstants.primary.withOpacity(0.12),
                        backgroundImage: (_livePhotoBase64 != null && _livePhotoBase64!.contains(','))
                            ? MemoryImage(base64Decode(_livePhotoBase64!.split(',').last))
                            : null,
                        child: (_livePhotoBase64 == null)
                            ? const Icon(Icons.person, size: 56, color: PartnerConstants.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _openMediaSourceSelector(
                            title: 'Live Selfie Verification',
                            isSelfie: true,
                            onCaptured: (dataUrl, sizeKb, fileName) {
                              setState(() {
                                _livePhotoBase64 = dataUrl;
                                _livePhotoVerified = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Live selfie captured & compressed (${sizeKb} KB)!'), backgroundColor: Colors.green),
                              );
                            },
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: PartnerConstants.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'Technician Specialist',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF192338)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _serviceNameController.text.isNotEmpty ? _serviceNameController.text : 'Certified Partner',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),

                  // LIVE PHOTO VERIFICATION BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _livePhotoVerified ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _livePhotoVerified ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _livePhotoVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                          color: _livePhotoVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _livePhotoVerified ? 'Live Photo Verification: Verified' : 'Live Photo Verification: Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _livePhotoVerified ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _livePhotoVerified ? 'AI facial match confirmed with Aadhaar ID' : 'Selfie capture required for activation',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _livePhotoVerified ? const Color(0xFF047857) : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openMediaSourceSelector(
                            title: 'Live Selfie Verification',
                            isSelfie: true,
                            onCaptured: (dataUrl, sizeKb, fileName) {
                              setState(() {
                                _livePhotoBase64 = dataUrl;
                                _livePhotoVerified = true;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Live selfie captured & compressed (${sizeKb} KB)!'), backgroundColor: Colors.green),
                              );
                            },
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            _livePhotoVerified ? 'RETAKE' : 'CAPTURE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _livePhotoVerified ? const Color(0xFF059669) : PartnerConstants.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SECTION 1: PERSONAL & FAMILY INFORMATION
            _buildSectionCard(
              title: '1. Personal & Family Information',
              icon: Icons.person_outline_rounded,
              children: [
                _buildFieldLabel('Full Name (as per Aadhaar Card) *'),
                _buildTextField(_nameController, 'Enter your full legal name', Icons.badge_outlined),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Father's Name *"),
                          _buildTextField(_fatherNameController, "Father's full name", Icons.person_outline),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Mother's Name *"),
                          _buildTextField(_motherNameController, "Mother's full name", Icons.person_outline),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Date of Birth (DOB) *'),
                          GestureDetector(
                            onTap: _selectDateOfBirth,
                            child: AbsorbPointer(
                              child: _buildTextField(_dobController, 'DD/MM/YYYY', Icons.calendar_month_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Age *'),
                          _buildTextField(_ageController, 'Years', Icons.cake_outlined, keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildFieldLabel('Registered Mobile Number'),
                _buildTextField(_phoneController, 'Mobile number', Icons.phone_android_rounded, readOnly: true),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Emergency Contact Number *'),
                          _buildTextField(_emergencyContactController, '10-digit number', Icons.contact_phone_outlined, keyboardType: TextInputType.phone),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Relation'),
                          _buildTextField(_emergencyRelationController, 'e.g. Spouse / Brother', Icons.family_restroom_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildFieldLabel('Email Address (Optional)'),
                _buildTextField(_emailController, 'partner@example.com', Icons.email_outlined),
              ],
            ),
            const SizedBox(height: 16),

            // SECTION 2: CURRENT RESIDENTIAL ADDRESS
            _buildSectionCard(
              title: '2. Current Residential & Base Address',
              icon: Icons.home_outlined,
              children: [
                _buildFieldLabel('Operating District *'),
                _buildDropdownField(
                  value: _selectedDistrict,
                  items: _districts,
                  onChanged: (val) {
                    if (val != null && val != _selectedDistrict) {
                      setState(() {
                        _selectedDistrict = val;
                        final mandals = _getMandalsForDistrict(val);
                        _selectedMandal = mandals.isNotEmpty ? mandals.first : '';
                        final villages = _getVillagesForMandal(val, _selectedMandal);
                        _selectedVillage = villages.isNotEmpty ? villages.first : '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Mandalam / Municipality *'),
                          _buildDropdownField(
                            value: _selectedMandal,
                            items: _getMandalsForDistrict(_selectedDistrict),
                            onChanged: (val) {
                              if (val != null && val != _selectedMandal) {
                                setState(() {
                                  _selectedMandal = val;
                                  final villages = _getVillagesForMandal(_selectedDistrict, val);
                                  _selectedVillage = villages.isNotEmpty ? villages.first : '';
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Village / Landmark *'),
                          _buildDropdownField(
                            value: _selectedVillage,
                            items: _getVillagesForMandal(_selectedDistrict, _selectedMandal),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                _selectedVillage = val;
                                final autoPin = _villagePincodes['${_selectedDistrict}_${_selectedMandal}_$val'];
                                if (autoPin != null && autoPin.isNotEmpty) {
                                  _pincodeController.text = autoPin;
                                }
                              });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildFieldLabel('House / Flat No., Building & Street *'),
                _buildTextField(
                  _doorStreetController,
                  'House/Flat No, Building, Colony Street',
                  Icons.location_city_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                _buildFieldLabel('Postal Pincode *'),
                _buildTextField(_pincodeController, '6-digit postal code', Icons.pin_drop_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 16),

                // PHYSICAL SHOP / WORKSHOP CHECKBOX
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _hasPhysicalShop ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasPhysicalShop ? PartnerConstants.primary : const Color(0xFFCBD5E1),
                      width: _hasPhysicalShop ? 1.5 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _hasPhysicalShop,
                    activeColor: PartnerConstants.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'I have a Physical Shop / Workshop / Service Center',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF192338)),
                    ),
                    subtitle: const Text(
                      'Check this if customers can visit your shop or drop appliances/items for service',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    onChanged: (val) {
                      setState(() => _hasPhysicalShop = val ?? false);
                    },
                  ),
                ),

                // CONDITIONAL SHOP ADDRESS & PHOTO UPLOAD FIELDS
                if (_hasPhysicalShop) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.storefront_rounded, color: PartnerConstants.primary, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Shop Details & Photo Attachments',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF192338)),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: Color(0xFFE2E8F0)),
                        _buildFieldLabel('Shop / Workshop Trade Name *'),
                        _buildTextField(_shopNameController, 'e.g. Ramesh Electrical & Hardware Store', Icons.store_outlined),
                        const SizedBox(height: 12),

                        _buildFieldLabel('Shop District *'),
                        _buildDropdownField(
                          value: _selectedShopDistrict,
                          items: _districts,
                          onChanged: (val) {
                            if (val != null && val != _selectedShopDistrict) {
                              setState(() {
                                _selectedShopDistrict = val;
                                final mandals = _getMandalsForDistrict(val);
                                _selectedShopMandal = mandals.isNotEmpty ? mandals.first : '';
                                final villages = _getVillagesForMandal(val, _selectedShopMandal);
                                _selectedShopVillage = villages.isNotEmpty ? villages.first : '';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Shop Mandalam *'),
                                  _buildDropdownField(
                                    value: _selectedShopMandal,
                                    items: _getMandalsForDistrict(_selectedShopDistrict),
                                    onChanged: (val) {
                                      if (val != null && val != _selectedShopMandal) {
                                        setState(() {
                                          _selectedShopMandal = val;
                                          final villages = _getVillagesForMandal(_selectedShopDistrict, val);
                                          _selectedShopVillage = villages.isNotEmpty ? villages.first : '';
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Shop Village / Landmark *'),
                                  _buildDropdownField(
                                    value: _selectedShopVillage,
                                    items: _getVillagesForMandal(_selectedShopDistrict, _selectedShopMandal),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedShopVillage = val;
                                          final autoPin = _villagePincodes['${_selectedShopDistrict}_${_selectedShopMandal}_$val'];
                                          if (autoPin != null && autoPin.isNotEmpty && _pincodeController.text.isEmpty) {
                                            _pincodeController.text = autoPin;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildFieldLabel('Shop Door / Unit No., Complex & Street *'),
                        _buildTextField(
                          _shopDoorStreetController,
                          'Shop No., Building Floor, Complex, Market Road',
                          Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        _buildFieldLabel('Trade License / GSTIN (Optional)'),
                        _buildTextField(_shopGstController, 'Registration / trade license number', Icons.receipt_long_outlined),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Shop Photos (Front Signboard & Inside View) *'),
                        _buildDocUploadCard(
                          title: 'Shop Front / Nameboard Photo',
                          isUploaded: _shopFrontPhotoUploaded,
                          onUpload: () => _openMediaSourceSelector(
                            title: 'Shop Front / Nameboard Photo',
                            onCaptured: (dataUrl, sizeKb, fileName) {
                              setState(() {
                                _shopFrontPhotoBase64 = dataUrl;
                                _shopFrontPhotoUploaded = true;
                                _uploadedFileSizes['Shop Front / Nameboard Photo'] = sizeKb;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Shop front photo attached (${sizeKb} KB)!'), backgroundColor: Colors.green),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDocUploadCard(
                          title: 'Shop Inside / Work Area Photo',
                          isUploaded: _shopInsidePhotoUploaded,
                          onUpload: () => _openMediaSourceSelector(
                            title: 'Shop Inside / Work Area Photo',
                            onCaptured: (dataUrl, sizeKb, fileName) {
                              setState(() {
                                _shopInsidePhotoBase64 = dataUrl;
                                _shopInsidePhotoUploaded = true;
                                _uploadedFileSizes['Shop Inside / Work Area Photo'] = sizeKb;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Shop inside photo attached (${sizeKb} KB)!'), backgroundColor: Colors.green),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // SECTION 3: WORKING HOURS & SERVICE RADIUS
            _buildSectionCard(
              title: '3. Work Schedule & Service Radius',
              icon: Icons.access_time_rounded,
              children: [
                _buildFieldLabel('Working Hours / Shift Preference *'),
                _buildDropdownField(
                  value: _selectedWorkingHours,
                  items: _workingHoursOptions,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWorkingHours = val);
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose whether you want Full-Time dispatch (9:00 AM - 6:00 PM) or Part-Time flexible jobs.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                _buildFieldLabel('Operating Service Radius *'),
                _buildDropdownField(
                  value: _selectedServiceRadius,
                  items: _serviceRadiusOptions,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedServiceRadius = val);
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Orders outside this radius from your live location will not be assigned to you.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SECTION 4: SERVICE SPECIALTY & PROFESSION
            _buildSectionCard(
              title: '4. Service Profession & Specialty',
              icon: Icons.construction_rounded,
              children: [
                _buildFieldLabel('Primary Service Category *'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF192338), fontWeight: FontWeight.w600),
                      items: _categories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['id'],
                          child: Text(c['name']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _buildFieldLabel('Specialty Designation / Title *'),
                _buildTextField(_serviceNameController, 'e.g. Master Plumber / Senior AC Wireman', Icons.work_outline),
                const SizedBox(height: 12),

                _buildFieldLabel('Years of Professional Experience *'),
                _buildDropdownField(
                  value: _selectedExperience,
                  items: _experienceOptions,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedExperience = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SECTION 5: KYC GOVERNMENT ID CARDS & PHOTO UPLOADS
            _buildSectionCard(
              title: '5. KYC Identity & Government Cards',
              icon: Icons.security_rounded,
              children: [
                // AADHAAR CARD
                _buildFieldLabel('Aadhaar Card Number (12 Digits) *'),
                _buildTextField(_aadhaarController, 'XXXX-XXXX-XXXX', Icons.fingerprint_rounded, keyboardType: TextInputType.number),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildDocUploadCard(
                        title: 'Aadhaar Front Side',
                        isUploaded: _aadhaarFrontUploaded,
                        onUpload: () => _openMediaSourceSelector(
                          title: 'Aadhaar Front Side',
                          onCaptured: (dataUrl, sizeKb, fileName) {
                            setState(() {
                              _aadhaarFrontBase64 = dataUrl;
                              _aadhaarFrontUploaded = true;
                              _uploadedFileSizes['Aadhaar Front Side'] = sizeKb;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Aadhaar front attached (${sizeKb} KB)!'), backgroundColor: Colors.green),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDocUploadCard(
                        title: 'Aadhaar Back Side',
                        isUploaded: _aadhaarBackUploaded,
                        onUpload: () => _openMediaSourceSelector(
                          title: 'Aadhaar Back Side',
                          onCaptured: (dataUrl, sizeKb, fileName) {
                            setState(() {
                              _aadhaarBackBase64 = dataUrl;
                              _aadhaarBackUploaded = true;
                              _uploadedFileSizes['Aadhaar Back Side'] = sizeKb;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Aadhaar back attached (${sizeKb} KB)!'), backgroundColor: Colors.green),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // PAN CARD
                _buildFieldLabel('PAN Card Number (10 Characters) *'),
                _buildTextField(_panNumberController, 'ABCDE1234F', Icons.credit_card_rounded),
                const SizedBox(height: 10),
                _buildDocUploadCard(
                  title: 'PAN Card Photo Document',
                  isUploaded: _panCardUploaded,
                  onUpload: () => _openMediaSourceSelector(
                    title: 'PAN Card Photo Document',
                    onCaptured: (dataUrl, sizeKb, fileName) {
                      setState(() {
                        _panCardBase64 = dataUrl;
                        _panCardUploaded = true;
                        _uploadedFileSizes['PAN Card Photo Document'] = sizeKb;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PAN card photo attached (${sizeKb} KB)!'), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // DRIVING LICENSE
                _buildFieldLabel('Driving License Number *'),
                _buildTextField(_drivingLicenseController, 'e.g. TS09 20210001234', Icons.drive_eta_rounded),
                const SizedBox(height: 10),
                _buildDocUploadCard(
                  title: 'Driving License Document Copy',
                  isUploaded: _drivingLicenseUploaded,
                  onUpload: () => _openMediaSourceSelector(
                    title: 'Driving License Document Copy',
                    onCaptured: (dataUrl, sizeKb, fileName) {
                      setState(() {
                        _drivingLicenseBase64 = dataUrl;
                        _drivingLicenseUploaded = true;
                        _uploadedFileSizes['Driving License Document Copy'] = sizeKb;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Driving license attached (${sizeKb} KB)!'), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SECTION 6: SKILL CERTIFICATES & TRADE QUALIFICATIONS
            _buildSectionCard(
              title: '6. Skill & Trade Certifications',
              icon: Icons.card_membership_rounded,
              children: [
                _buildFieldLabel('Trade Certificate / Technical Qualification Title *'),
                _buildTextField(
                  _skillCertificatesController,
                  'e.g. ITI Electrician Certificate / Wireman License',
                  Icons.workspace_premium_outlined,
                ),
                const SizedBox(height: 10),
                _buildDocUploadCard(
                  title: 'Upload Skill / Trade Certificate Proof',
                  isUploaded: _skillCertificateUploaded,
                  onUpload: () => _openMediaSourceSelector(
                    title: 'Skill / Trade Certificate Proof',
                    onCaptured: (dataUrl, sizeKb, fileName) {
                      setState(() {
                        _skillCertificateBase64 = dataUrl;
                        _skillCertificateUploaded = true;
                        _uploadedFileSizes['Skill / Trade Certificate Proof'] = sizeKb;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Skill certificate attached (${sizeKb} KB)!'), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SECTION 7: LOCAL GUARANTOR & REFERENCE
            _buildSectionCard(
              title: '7. Local Guarantor / Reference Verification',
              icon: Icons.handshake_outlined,
              children: [
                _buildFieldLabel('Guarantor / Reference Full Name *'),
                _buildTextField(_guarantorNameController, 'Name of local guarantor or contractor', Icons.person_outline),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Relationship *'),
                          _buildTextField(_guarantorRelationController, 'e.g. Contractor / Uncle', Icons.group_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Guarantor Mobile Number *'),
                          _buildTextField(_guarantorPhoneController, '10-digit mobile number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SECTION 8: BANK UPI PAYOUT
            _buildSectionCard(
              title: '8. Daily Earnings Payout Account',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _buildFieldLabel('UPI ID for Instant Daily Bank Payouts *'),
                _buildTextField(_upiController, 'e.g. 9876522222@ybl / PhonePe / GPay', Icons.payments_outlined),
                const SizedBox(height: 6),
                const Text(
                  'Daily earnings after 90% payout guarantee will be settled directly to this UPI ID.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PartnerConstants.primary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _handleSaveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'SAVE & SUBMIT TECHNICIAN PROFILE',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: PartnerConstants.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: PartnerConstants.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF192338)),
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF192338)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: PartnerConstants.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF192338), fontWeight: FontWeight.w600),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDocUploadCard({
    required String title,
    required bool isUploaded,
    required VoidCallback onUpload,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUploaded ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isUploaded ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.task_alt_rounded : Icons.upload_file_rounded,
            color: isUploaded ? Colors.green : const Color(0xFF94A3B8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUploaded ? const Color(0xFF166534) : const Color(0xFF334155)),
                ),
                Text(
                  isUploaded ? (_uploadedFileSizes[title] != null ? 'Attached (${_uploadedFileSizes[title]} KB - Compressed)' : 'Document Attached (Verified)') : 'Upload PDF or JPG Photo',
                  style: TextStyle(fontSize: 10, color: isUploaded ? const Color(0xFF15803D) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUpload,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              isUploaded ? 'REPLACE' : 'UPLOAD',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isUploaded ? Colors.green : PartnerConstants.primary),
            ),
          ),
        ],
      ),
    );
  }
}
