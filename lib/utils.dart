import 'package:url_launcher/url_launcher.dart';

Future<void> launchGoogleSearch(String query) async {
  final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}
