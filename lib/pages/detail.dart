import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class DetailPage extends StatefulWidget {
  final int index;
  final Map questionData;

  const DetailPage({
    super.key,
    required this.index,
    required this.questionData,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final jSoal = TextEditingController();
  late Box box;

  @override
  void initState() {
    super.initState();
    box = Hive.box('savedDataBox');
  }

  void simpanJawab() async {
    if (jSoal.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jawaban Tidak Boleh Kosong!')),
      );
      return;
    }

    final soalJawab = jSoal.text;
    final newAnswer = {'jawab': soalJawab};

    setState(() {
      final updatedQuestion = widget.questionData;
      List answers = updatedQuestion['answers'] ?? [];
      answers.add(newAnswer);
      updatedQuestion['answers'] = answers;
      box.putAt(widget.index, updatedQuestion); 
      jSoal.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Berhasil Menjawab')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answers = widget.questionData['answers'] as List;

    return Scaffold(
      appBar: AppBar(title: Text('Detail Page')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.questionData['imagePath'] != null
                ? Image.network(
                    widget.questionData['imagePath'],
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(child: Text('No Image Available')),
                  ),
            SizedBox(height: 20),
            Text(
              widget.questionData['text'] ?? 'No Text Available',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Expanded(
              child: answers.isEmpty
                  ? Center(child: Text('Belum ada jawaban.'))
                  : ListView.builder(
                      itemCount: answers.length,
                      itemBuilder: (context, index) {
                        final data = answers[index];
                        return Card(
                          child: ListTile(
                            title: Text(data['jawab'] ?? ''),
                          ),
                        );
                      },
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: jSoal,
                    decoration: InputDecoration(hintText: 'Ketik Jawaban Kamu...'),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: simpanJawab,
                  child: Text('Jawab'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
