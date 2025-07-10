import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/message.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMessage(Message message) async {
    try {
      debugPrint('Saving user message: ${message.toMap()}');
      await _firestore
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());
      debugPrint('User message saved successfully');

      await dotenv.load(fileName: '.env');
      final apiKey = dotenv.env['GEMINI_API_KEY']!;
      if (apiKey.isEmpty) throw Exception('API key not found');

      debugPrint('Calling Gemini API with message: ${message.text}');
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': message.text},
                  ],
                },
              ],
              'generationConfig': {'maxOutputTokens': 150, 'temperature': 0.7},
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              return http.Response('Timeout', 408);
            },
          );

      debugPrint(
        'API Response - Status: ${response.statusCode}, Body: ${response.body}',
      );
      String botResponse;
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        botResponse =
            decodedResponse['candidates'][0]['content']['parts'][0]['text'] ??
            'No response from AI';
      } else {
        botResponse = 'API Error: ${response.statusCode} - ${response.body}';
      }

      final botMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_bot',
        userId: 'bot',
        text: botResponse,
        timestamp: DateTime.now(),
      );
      debugPrint('Saving bot message: ${botMessage.toMap()}');
      await _firestore
          .collection('messages')
          .doc(botMessage.id)
          .set(botMessage.toMap());
      debugPrint('Bot message saved successfully');
    } catch (e) {
      debugPrint('Error in addMessage: ${e.toString()}');
    }
  }

  Stream<List<Message>> getMessages(String userId) {
    debugPrint('Fetching messages for userId: $userId');
    return _firestore
        .collection('messages')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'Snapshot data: ${snapshot.docs.map((doc) => doc.data())}',
          );
          return snapshot.docs
              .map((doc) => Message.fromMap(doc.data()))
              .toList();
        });
  }
}
