class Dealer {
  final int id;
  final String name;
  final String shopName;
  final String whatsappNumber;
  final String address;
  final int taluka;
  final String createdAt;

  Dealer({
    required this.id,
    required this.name,
    required this.shopName,
    required this.whatsappNumber,
    required this.address,
    required this.taluka,
    required this.createdAt,
  });

  factory Dealer.fromJson(Map<String, dynamic> json) {
    return Dealer(
      id: json['id'],
      name: json['name'],
      shopName: json['shop_name'],
      whatsappNumber: json['whatsapp_number'],
      address: json['address'],
      taluka: json['taluka'],
      createdAt: json['created_at'],
    );
  }
}