class ImageModel {
  final String url;

  ImageModel({required this.url});

  // Factory constructor to create an instance of ImageModel from JSON
  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      url: json['data']?['url'] ?? json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}
