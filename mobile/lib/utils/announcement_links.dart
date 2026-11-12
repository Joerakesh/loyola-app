import 'package:url_launcher/url_launcher.dart';

Future<bool> openAnnouncementLink(String value) async {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
    return false;
  }

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
