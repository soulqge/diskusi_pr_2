import 'dart:io';
import 'package:diskusi_pr_2/models/image_models.dart';
import 'package:diskusi_pr_2/models/image_service.dart';
import 'package:diskusi_pr_2/pages/detail.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:process_run/process_run.dart'; // Import process_run

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

      // Limit size to 2MB (2 * 1024 * 1024 bytes)
      int maxSizeInBytes = 2 * 1024 * 1024;

      if (imageSize <= maxSizeInBytes) {
        setState(() {
          _image = imageFile;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ukuran gambar tidak boleh lebih dari 2MB')),
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

    // Check for hidden messages using Python script
    try {
      final result = await run(
        'python', // Ensure Python is installed and available in the PATH
        ['C:/Users/Ahmad Arfa/Documents/Magang/diskusi_pr_2/lib/python/steganography_check.py', _image!.path],
      );
      print('Python script output: ${result.stdout}');
      print('Python script errors: ${result.stderr}');

      if (result.stdout.contains('Hidden message detected')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hidden message detected!')),
        );
        return;
      }
    } catch (e) {
      print('Error running Python script: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check image for hidden messages!')),
      );
      return;
    }

    try {
      final imageUrl = await uploadImage(_image!);
      if (imageUrl == null) {
        throw Exception('Failed to get image URL');
      }

      final imageModel = ImageModel(url: imageUrl);

      print(imageModel.url);

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
