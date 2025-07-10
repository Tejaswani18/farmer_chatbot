import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'models/message.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Roboto', color: Colors.black87),
          bodyMedium: TextStyle(fontFamily: 'Roboto', color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _status = '';
  bool _isSignUp = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Color(0xFF8BC34A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/farm_logo.png', height: 100),
                const SizedBox(height: 20),
                Text(
                  _isSignUp ? 'Join Farmer Support' : 'Welcome Back, Farmer!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isSignUp
                      ? 'Create an account to get agricultural support'
                      : 'Sign in to access your chatbot',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.green),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.green),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();
                    if (email.isEmpty || password.isEmpty) {
                      if (mounted) {
                        setState(() {
                          _status = 'Please enter email and password';
                        });
                      }
                      return;
                    }
                    User? user;
                    if (_isSignUp) {
                      user = await _authService.signUp(email, password);
                      if (mounted) {
                        setState(() {
                          _status = user != null
                              ? 'Signed up: ${user.uid}'
                              : 'Sign-up failed';
                        });
                      }
                    } else {
                      user = await _authService.signIn(email, password);
                      if (mounted) {
                        setState(() {
                          _status = user != null
                              ? 'Signed in: ${user.uid}'
                              : 'Sign-in failed';
                        });
                      }
                    }
                    if (user != null && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    }
                  },
                  child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _status = '';
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Need an account? Sign Up',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const AuthScreen();
        }
        final user = snapshot.data!;
        debugPrint('Current user: ${user.uid}');
        return Scaffold(
          appBar: AppBar(
            title: const Text('Farmer Support Chatbot'),
            backgroundColor: Colors.green[700],
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/farm_background.jpg'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: _firestoreService.getMessages(user.uid),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (userSnapshot.hasError) {
                        debugPrint(
                          'User snapshot error: ${userSnapshot.error}',
                        );
                        return Center(
                          child: Text(
                            'Error loading user messages: ${userSnapshot.error}',
                          ),
                        );
                      }
                      final userDocs = userSnapshot.data ?? [];
                      debugPrint('User snapshot docs: ${userDocs.length}');
                      return StreamBuilder<List<Message>>(
                        stream: _firestoreService.getMessages('bot'),
                        builder: (context, botSnapshot) {
                          if (botSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (botSnapshot.hasError) {
                            debugPrint(
                              'Bot snapshot error: ${botSnapshot.error}',
                            );
                            return Center(
                              child: Text(
                                'Error loading bot messages: ${botSnapshot.error}',
                              ),
                            );
                          }
                          final botDocs = botSnapshot.data ?? [];
                          debugPrint('Bot snapshot docs: ${botDocs.length}');
                          final allMessages = [
                            ...userDocs,
                            ...botDocs,
                          ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                          debugPrint(
                            'All messages count: ${allMessages.length}, Texts: ${allMessages.map((m) => m.text).join(', ')}',
                          );
                          if (allMessages.isEmpty) {
                            return const Center(
                              child: Text(
                                'Start chatting with the Farmer Bot!',
                              ),
                            );
                          }
                          return ListView.builder(
                            reverse: true,
                            itemCount: allMessages.length,
                            itemBuilder: (context, index) {
                              final message = allMessages[index];
                              try {
                                final isUserMessage =
                                    message.userId == user.uid;
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: isUserMessage
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.7,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isUserMessage
                                              ? Colors.green[100]
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isUserMessage
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.text,
                                              style: TextStyle(
                                                color: isUserMessage
                                                    ? Colors.green[900]
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              _formatTimestamp(
                                                message.timestamp,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                debugPrint(
                                  'Error rendering message at index $index: $e',
                                );
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 10,
                                  ),
                                  child: Text(
                                    'Error: Failed to render message',
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText:
                                'Ask about crops, weather, or farming tips...',
                            filled: true,
                            fillColor: Colors.green[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.green[700],
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            if (_messageController.text.isNotEmpty) {
                              final message = Message(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                userId: user.uid,
                                text: _messageController.text.trim(),
                                timestamp: DateTime.now(),
                              );
                              debugPrint('Sending message: ${message.toMap()}');
                              await _firestoreService.addMessage(message);
                              if (mounted) {
                                _messageController.clear();
                                setState(() {}); // Force UI refresh
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
