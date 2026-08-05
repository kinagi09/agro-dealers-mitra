class Licence {
  final int id;
  final int dealer;
  final String dealerName;
  final int licenceType;
  final String licenceTypeName;
  final int financialYear;
  final String licenceNumber;
  final String issueDate;
  final String expiryDate;
  final String status;

  Licence({
    required this.id,
    required this.dealer,
    required this.dealerName,
    required this.licenceType,
    required this.licenceTypeName,
    required this.financialYear,
    required this.licenceNumber,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
  });

  factory Licence.fromJson(Map<String, dynamic> json) {
    return Licence(
      id: json['id'],
      dealer: json['dealer'],
      dealerName: json['dealer_name'],
      licenceType: json['licence_type'],
      licenceTypeName: json['licence_type_name'],
      financialYear: json['financial_year'],
      licenceNumber: json['licence_number'],
      issueDate: json['issue_date'],
      expiryDate: json['expiry_date'],
      status: json['status'],
    );
  }

  int get daysUntilExpiry {
    final expiry = DateTime.parse(expiryDate);
    return expiry.difference(DateTime.now()).inDays;
  }
}