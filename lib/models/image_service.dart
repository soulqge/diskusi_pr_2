import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';


Future<String?> uploadImage(File imageFile) async {
  final url = Uri.parse('https://api.imgbb.com/1/upload'); 

  try {

    final mimeTypeData = lookupMimeType(imageFile.path, headerBytes: [0xFF, 0xD8])?.split('/');
    if (mimeTypeData == null || mimeTypeData.length != 2) {
      throw Exception('Could not determine MIME type of the image.');
    }

    final request = http.MultipartRequest('POST', url)
      ..fields['key'] = 'ddec36ac8e6d7fbb68d6bf93e277e19f'
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
        ),
      );


    final response = await request.send();


    final responseData = await http.Response.fromStream(response);
        final jsonData = jsonDecode(responseData.body);
    print('API Response: $jsonData');

    if (response.statusCode == 200 && jsonData['success']) {
      return jsonData['data']['url'];
    } else {
      print('Error from API: ${jsonData['error']['message']}');
      return null;
    }
  } catch (e) {
    print('Error occurred while uploading image: $e');
    return null;
  }
}
