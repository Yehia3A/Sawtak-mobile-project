class AdvertisementRequest {
  final String id;
  final String posterId;
  final String posterName;
  final String title;
  final String description;
  final String imageUrl;
  final String city;
  final String area;
  final String link;
  final String status;
  final DateTime createdAt;

  AdvertisementRequest({
    required this.id,
    required this.posterId,
    required this.posterName,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.city,
    required this.area,
    required this.link,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'posterId': posterId,
      'posterName': posterName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'city': city,
      'area': area,
      'link': link,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AdvertisementRequest.fromMap(Map<String, dynamic> map) {
    return AdvertisementRequest(
      id: map['id'],
      posterId: map['posterId'],
      posterName: map['posterName'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      city: map['city'],
      area: map['area'],
      link: map['link'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
