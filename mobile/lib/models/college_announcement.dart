class CollegeAnnouncement {
  const CollegeAnnouncement({
    required this.id,
    required this.title,
    required this.url,
    required this.source,
  });

  final String id;
  final String title;
  final String url;
  final String source;

  bool get isPdf {
    final uri = Uri.tryParse(url);
    return uri?.path.toLowerCase().endsWith('.pdf') ?? false;
  }

  factory CollegeAnnouncement.fromJson(Map<String, dynamic> json) {
    return CollegeAnnouncement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'College announcement',
      url: json['url']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Loyola College',
    );
  }
}
