//my_home_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger('MyApp');

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? customKey}) : super(key: customKey);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class WhatsAppUtils {
  static String getWhatsAppFileName(String url) {
    try {
      final Uri uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final fileNameWithExtension = uri.pathSegments.last;
        final fileName = fileNameWithExtension.split('.').first;
        if (kDebugMode) {
          print('URL: $url, FileName: $fileName');
        }
        return fileName;
      } else {
        if (kDebugMode) {
          print('No path segments in the URL');
        }
        return '';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing URL: $e');
      }
      return '';
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> imageUrls = [];
  List<String> whatsappLinks = [];
  late ScrollController _scrollController;
  late SharedPreferences _preferences;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initializePreferences();
    fetchImageLinks();
    fetchWhatsAppLinks();
  }

  Future<void> initializePreferences() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Future<void> fetchImageLinks() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/dalimahjoub-07/travel-guide-tunisia/contents/images'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<String> imageUrls = [];

        for (var item in data) {
          if (item['type'] == 'file' &&
              item['name'] != null &&
              item['download_url'] != null &&
              (item['name'].endsWith('.jpeg') ||
                  item['name'].endsWith('.jpg'))) {
            final imageUrl = item['download_url'];
            imageUrls.add(imageUrl);
            await precacheImage(CachedNetworkImageProvider(imageUrl), context);
            // Save the image URL to SharedPreferences for future use
            _preferences.setString(imageUrl, imageUrl);
          }
        }

        setState(() {
          this.imageUrls = imageUrls;
        });
      } else {
        _logger.warning('Failed to load image links');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching image links'),
          ),
        );
      }
    } catch (e) {
      _logger.warning('Error fetching image links: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred'),
        ),
      );
    }
  }

  Future<void> fetchWhatsAppLinks() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/dalimahjoub-07/travel-guide-tunisia/contents/whatsapp_Links'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<String> whatsappLinks = [];

        for (var item in data) {
          if (item['type'] == 'file' &&
              item['name'] != null &&
              item['download_url'] != null &&
              item['name'].endsWith('.link')) {
            whatsappLinks.add(item['download_url']);
          }
        }

        setState(() {
          this.whatsappLinks = whatsappLinks;
        });
      } else {
        print('Failed to load WhatsApp links');
      }
    } catch (e) {
      print('Error fetching WhatsApp links: $e');
      // Show an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 35, 195, 250),
        title: const Center(
          child: Text(
            'Camp, Rando, Gîte, Resto, Hostel',
          ),
        ),
      ),
      body: Container(
        color: const Color.fromARGB(255, 0, 114, 190),
        padding: const EdgeInsets.all(3.0),
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (imageUrls.length + whatsappLinks.length) * 2,
                    itemBuilder: (context, index) {
                      if (index.isOdd) {
                        final whatsappIndex = index ~/ 2;
                        if (whatsappIndex < whatsappLinks.length) {
                          return Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: ListTile(
                              title: Center(
                                child: GestureDetector(
                                  onTap: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Ouvrir le lien'),
                                        content: Text(
                                            'Voulez-vous ouvrir ce lien dans votre navigateur ?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final redirectLink =
                                                  'https://wa.me/+21658154422/';

                                              if (await canLaunchUrl(
                                                  Uri.parse(redirectLink))) {
                                                await launchUrl(
                                                    Uri.parse(redirectLink));
                                              } else {
                                                print(
                                                    'Could not launch $redirectLink');
                                              }
                                              Navigator.pop(context);
                                            },
                                            child: Text('Open'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    constraints: kIsWeb
                                        ? BoxConstraints(maxWidth: 400)
                                        : null, // No constraints for other platforms
                                    padding:
                                        const EdgeInsets.fromLTRB(9, 1, 9, 1),
                                    color:
                                        const Color.fromARGB(255, 7, 189, 62),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          WhatsAppUtils.getWhatsAppFileName(
                                            whatsappIndex < whatsappLinks.length
                                                ? whatsappLinks[whatsappIndex]
                                                : '',
                                          ),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 23),
                                        ),
                                        SizedBox(
                                          width: kIsWeb ? 30 : 25,
                                        ),
                                        const Image(
                                          image: AssetImage(
                                              'lib/assets/logo-whatsapp-128.png'),
                                          width: 60.0,
                                          height: 60.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox(); // Return an empty SizedBox for indices beyond whatsappLinks.length
                        }
                      } else {
                        final itemIndex = index ~/ 2;
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: ListTile(
                            title: Center(
                              child: Container(
                                constraints: kIsWeb
                                    ? BoxConstraints(maxWidth: 400)
                                    : null,
                                child: itemIndex < imageUrls.length
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrls[itemIndex],
                                        fit: BoxFit.cover,
                                        memCacheWidth: 600,
                                        memCacheHeight: 600,
                                      )
                                    : const SizedBox(),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
