import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

Future<String> askGPT(String prompt) async {
  final apiKey = dotenv.env['OPENAI_API_KEY'];

  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    }),
  );

  print(response.statusCode);
  print(response.body);

  final data = jsonDecode(response.body);

  if (response.statusCode != 200) {
    return '에러 발생: ${response.statusCode}\n${response.body}';
  }

  return data['choices'][0]['message']['content'];
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String answer = '아직 호출 안 함';

  Future<void> callGPT() async {
    setState(() {
      answer = 'GPT 호출 중...';
    });

    final result = await askGPT('안녕? 너는 누구야?');

    setState(() {
      answer = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('OpenAI API Practice')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: callGPT,
                  child: Text('GPT 호출'),
                ),
                SizedBox(height: 24),
                Text(answer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
