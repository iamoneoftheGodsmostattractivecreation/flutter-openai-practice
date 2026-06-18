import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; //인터넷 요청 보내는 패키지
import 'package:flutter_dotenv/flutter_dotenv.dart'; //.env 파일에서 API 키 읽는 패키지
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

Future<void> main() async {
  await dotenv.load(fileName: ".env"); //env 파일 다 읽을때까지 기다림
  runApp(const MyApp());
}

Future<String> askGPTWithImage(XFile image) async {
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  final Uint8List imageBytes = await image.readAsBytes();
  final String base64Image = base64Encode(imageBytes);

  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': '''
이 이미지는 공지사항 캡처입니다.

이미지 안의 글자를 읽고, 모든 일정을 추출해줘.

반드시 JSON 객체만 반환해.
설명 금지.
마크다운 금지.

형식:
{
  "events": [
    {
      "date": "날짜",
      "task": "해야 할 일",
      "location": "장소"
    }
  ]
}
'''
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/png;base64,$base64Image',
              }
            }
          ]
        }
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
  XFile? selectedImage;
  String answer = '아직 호출 안 함';

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    setState(() {
      selectedImage = image;
      answer = '이미지 선택 완료: ${image.name}';
    });
  }

  Future<void> analyzeSelectedImage() async {
    if (selectedImage == null) {
      setState(() {
        answer = '먼저 이미지를 선택해줘.';
      });
      return;
    }

    setState(() {
      answer = '이미지 분석 중...';
    });

    final result = await askGPTWithImage(selectedImage!);

    final extractedData = jsonDecode(result);
    final events = extractedData['events'];

    setState(() {
      answer = events.map((event) {
        return '''
날짜: ${event['date']}
해야 할 일: ${event['task']}
장소: ${event['location']}
''';
      }).join('\n');
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
                SizedBox(height: 24),
                Text(answer),
                ElevatedButton(
                  onPressed: pickImage,
                  child: Text('이미지 선택'),
                ),
                ElevatedButton(
                  onPressed: analyzeSelectedImage,
                  child: Text('이미지 분석'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
