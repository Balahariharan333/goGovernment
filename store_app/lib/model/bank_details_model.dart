class BankDetailsModel {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;

  BankDetailsModel({
    this.bankName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.accountHolderName = '',
  });

  factory BankDetailsModel.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) return BankDetailsModel();
    return BankDetailsModel(
      bankName: json['bankName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
    };
  }
}
