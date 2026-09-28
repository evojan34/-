import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const GitHubFinderApp());
}

class GitHubFinderApp extends StatelessWidget {
  const GitHubFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GitHub Finder',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF238636),
        cardColor: const Color(0xFF161B22),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _userData;
  List<dynamic> _repos = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> fetchGitHubData(String username) async {
    if (username.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _userData = null;
      _repos = [];
    });

    try {
      // 1. جلب بيانات الملف الشخصي
      final userResponse = await http.get(
        Uri.parse('https://api.github.com/users/$username'),
      );

      if (userResponse.statusCode == 404) {
        setState(() {
          _errorMessage = 'المستخدم غير موجود!';
          _isLoading = false;
        });
        return;
      }

      final userData = json.decode(userResponse.body);

      // 2. جلب مستودعات المستخدم (أحدث 10 مستودعات)
      final reposResponse = await http.get(
        Uri.parse('https://api.github.com/users/$username/repos?sort=updated&per_page=10'),
      );
      final reposData = json.decode(reposResponse.body);

      setState(() {
        _userData = userData;
        _repos = reposData is List ? reposData : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء الاتصال بالإنترنت';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مستكشف حسابات GitHub'),
        centerTitle: true,
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // حقل البحث
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'اكتب اسم مستخدم GitHub...',
                        filled: true,
                        fillColor: const Color(0xFF161B22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: fetchGitHubData,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => fetchGitHubData(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF238636),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('بحث', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // حالة التحميل والخطأ والنتائج
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 16))
              else if (_userData != null)
                Expanded(
                  child: ListView(
                    children: [
                      // بطاقة المستخدم
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundImage: NetworkImage(_userData!['avatar_url']),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _userData!['name'] ?? _userData!['login'],
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '@${_userData!['login']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            if (_userData!['bio'] != null)
                              Text(
                                _userData!['bio'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStat('المستودعات', '${_userData!['public_repos']}'),
                                _buildStat('المتابعون', '${_userData!['followers']}'),
                                _buildStat('يتابع', '${_userData!['following']}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'أحدث المستودعات:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // قائمة المستودعات
                      ..._repos.map((repo) => Card(
                            color: const Color(0xFF161B22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFF30363D)),
                            ),
                            child: ListTile(
                              title: Text(repo['name'], style: const TextStyle(color: Color(0xFF58A6FF))),
                              subtitle: Text(
                                repo['description'] ?? 'لا يوجد وصف',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_border, size: 18, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text('${repo['stargazers_count']}'),
                                ],
                              ),
                              onTap: () async {
                                final uri = Uri.parse(repo['html_url']);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
