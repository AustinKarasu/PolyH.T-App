class Branch {
  Branch({required this.id, required this.name, required this.code});

  final int id;
  final String name;
  final String code;

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}
