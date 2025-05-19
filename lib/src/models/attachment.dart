class Attachment {
  final String id;
  final String name;
  final String url;
  final String type;

  Attachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'url': url, 'type': type};
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
    );
  }
}
