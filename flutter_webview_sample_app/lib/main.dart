import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Login',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      routes: {'/home': (_) => const HomeScreen()},
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          // ..clearCache()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                _handleUrlChange(request.url);
                return NavigationDecision.navigate;
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                _showError("Failed to load page: ${error.description}");
              },
            ),
          )
          ..loadRequest(
            Uri.parse(
              "https://auth-server-sample-app-production.up.railway.app/login",
            ),
          );
  }

  Future<void> _handleUrlChange(String url) async {
    if (url.startsWith('myapp://success')) {
      final Uri uri = Uri.parse(url);
      final String? token = uri.queryParameters['token'];
      if (token != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        _showError("Token not found in URL");
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Login Error'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      // Remove AppBar by not including it in Scaffold.
      child: Scaffold(
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkboxValue = false;
  String _selectedRadio = 'Option 1';
  String _dropdownValue = 'Item 1';

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // No appBar means no title bar at the top.
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _getToken(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Logout button placed at the top right within UI content.
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      tooltip: "Logout",
                    ),
                  ),
                  Text(
                    "Logged in. Token:\n${snapshot.data}",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Button pressed")),
                      );
                    },
                    child: const Text("Press Me"),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: _checkboxValue,
                        onChanged: (bool? value) {
                          setState(() {
                            _checkboxValue = value ?? false;
                          });
                        },
                      ),
                      const Text("Checkbox"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Radio Options:"),
                      ListTile(
                        title: const Text("Option 1"),
                        leading: Radio<String>(
                          value: "Option 1",
                          groupValue: _selectedRadio,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedRadio = value ?? "Option 1";
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text("Option 2"),
                        leading: Radio<String>(
                          value: "Option 2",
                          groupValue: _selectedRadio,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedRadio = value ?? "Option 1";
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButton<String>(
                    value: _dropdownValue,
                    items: const [
                      DropdownMenuItem(value: "Item 1", child: Text("Item 1")),
                      DropdownMenuItem(value: "Item 2", child: Text("Item 2")),
                      DropdownMenuItem(value: "Item 3", child: Text("Item 3")),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _dropdownValue = newValue ?? "Item 1";
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
