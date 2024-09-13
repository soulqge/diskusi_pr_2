import 'dart:io';
import 'package:diskusi_pr_2/models/image_models.dart';
import 'package:diskusi_pr_2/models/image_service.dart';
import 'package:diskusi_pr_2/pages/detail.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final picker = ImagePicker();
  final tSoal = TextEditingController();
  late Box box;

  @override
  void initState() {
    super.initState();
    box = Hive.box('savedDataBox');
  }

  void pilihFoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      int imageSize = await imageFile.length(); // Size in bytes

      int maxSizeInBytes = 5 * 1024 * 1024;

      if (imageSize <= maxSizeInBytes) {
        setState(() {
          _image = imageFile;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ukuran gambar tidak boleh lebih dari 5MB')),
        );
      }
    } else {
      print('No image was selected.');
    }
  }

  Future<void> simpanFoto() async {
    if (_image == null || tSoal.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto dan teks harus diisi!')),
      );
      return;
    }

    try {
      // Read image as bytes
      var imageAsBytes = await _image!.readAsBytes();

      // Convert bytes to hex values
      List<String> hexList = imageAsBytes.map((byte) {
        return byte
            .toRadixString(16)
            .padLeft(2, '0'); // Convert each byte to hex
      }).toList();

      print("Hex Values: $hexList");
      print("Hex Values Length: ${hexList.length}");
      print("Image Path: ${_image!.path}");

      // Define a map of suspicious SQL keywords with their hex values
      Map<String, String> suspiciousWordsHex = {
        "SELECT": "53454c454354",
        "INSERT": "494e53455254",
        "UPDATE": "555044415445",
        "DELETE": "44454c455445",
        "DROP": "44524f50",
        "ALTER": "414c544552",
        "UNION": "554e494f4e",
        "CREATE": "435245415445",
        "EXEC": "45584543",
        "EXECUTE": "45584543555445",
      };
  
      // Iterate over the hex list and check for any suspicious word patterns
      for (int i = 0; i < hexList.length; i++) {
        for (var word in suspiciousWordsHex.keys) {
          // Get the hex representation of the current word
          String wordHex = suspiciousWordsHex[word]!;

          // Calculate the required slice length for the word
          int sliceLength = wordHex.length ~/ 2;

          // Ensure that there's enough room to slice
          if (i <= hexList.length - sliceLength) {
            // Slice the hex values for the current word length
            List<String> hexSlice = hexList.sublist(i, i + sliceLength);

            // Check if the current hex slice matches the word's hex representation
            if (hexSlice.join('') == wordHex) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("File is Suspicious! (Contains '$word')")),
              );
              return; // Stop processing if a suspicious word is detected
            }
          }
        }
      }

      // Continue with uploading and saving the image if no hidden messages or errors
      final imageUrl = await uploadImage(_image!);
      if (imageUrl == null) {
        throw Exception('Gagal mendapatkan URL gambar');
      }

      final imageModel = ImageModel(url: imageUrl);

      final savedData = {
        'imagePath': imageModel.url,
        'text': tSoal.text,
        'answers': [],
      };

      setState(() {
        box.add(savedData);
        _image = null;
        tSoal.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto dan teks berhasil disimpan!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Gagal menyimpan foto dan teks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan foto dan teks!')),
      );
    }
  }

  void tanyaSoal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Tanya Soal"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tSoal,
                decoration: InputDecoration(hintText: 'Mau Tanya Apa?'),
              ),
              _image == null
                  ? Text("Tidak Ada Foto Yang Dipilih")
                  : Image.file(_image!),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: pilihFoto,
                child: Text("Pilih Foto"),
              ),
            ],
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              Navigator.pop(context);
              tSoal.clear();
            },
            child: Text("Batal"),
          ),
          MaterialButton(
            onPressed: simpanFoto,
            child: Text("Tanya"),
          ),
        ],
      ),
    );
  }

  void navigateToDetailPage(int index) async {
    final questionData = box.getAt(index) as Map;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailPage(index: index, questionData: questionData),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Diskusi PR")),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box box, _) {
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                final data = box.getAt(index) as Map;
                print('Image URL: ${data['imagePath']}');
                return InkWell(
                  onTap: () => navigateToDetailPage(index),
                  child: Card(
                      child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        data['imagePath'] != null
                            ? CachedNetworkImage(
                                imageUrl: data['imagePath'],
                                height: 150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                              )
                            : Container(
                                height: 150,
                                color: Colors.grey[300],
                                child:
                                    Center(child: Text('No Image Available')),
                              ),
                        SizedBox(height: 10),
                        Text(
                          data['text'] ?? 'No Text Available',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: tanyaSoal,
        child: Icon(Icons.add),
      ),
    );
  }
}
