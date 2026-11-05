class OrderModel {
  final String id;
  final String serviceName;
  final String providerName;
  final String? providerPhone;
  final String customerAddress;
  final double amount;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String otp;
  final String notes;
  final String createdAt;
  final String? problemDescription;
  final String? categoryName;

  OrderModel({
    required this.id,
    required this.serviceName,
    required this.providerName,
    this.providerPhone,
    required this.customerAddress,
    required this.amount,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.otp,
    required this.notes,
    required this.createdAt,
    this.problemDescription,
    this.categoryName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      serviceName: json['serviceName'] ?? json['childTaskName'] ?? json['subCategoryName'] ?? json['categoryName'] ?? 'General Service',
      providerName: json['providerName'] ?? 'Searching for nearby specialist...',
      providerPhone: json['providerPhone'],
      customerAddress: json['customerAddress'] ?? 'Your Location',
      amount: (json['amount'] ?? 0).toDouble(),
      orderStatus: json['orderStatus'] ?? 'PENDING',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      paymentMethod: json['paymentMethod'] ?? 'Cash on Delivery',
      otp: json['otp'] ?? '0000',
      notes: json['notes'] ?? json['problemDescription'] ?? '',
      createdAt: json['createdAt'] ?? '',
      problemDescription: json['problemDescription'],
      categoryName: json['categoryName'],
    );
  }
}
