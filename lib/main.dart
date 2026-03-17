import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DeviceMotorolaApp());
}

class DeviceMotorolaApp extends StatelessWidget {
  const DeviceMotorolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Motorola',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const String _validUsername = 'karishma';
  static const String _validPassword = 'pd143@grv';

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username == _validUsername && password == _validPassword) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween<Offset>(
              begin: const Offset(0.2, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            );
          },
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid username or password'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Device Motorola',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const MethodChannel _mockChannel =
      MethodChannel('com.example.device_motorola/mock_location');
  static const double _baseLatitude = 25.791440;
  static const double _baseLongitude = 85.838427;
  static const double _radiusMeters = 15;

  bool _isOn = false;
  bool _isMockSetupReady = false;
  bool _isLoading = false;
  String _statusMessage = 'Tap Turn ON to set mock location';

  @override
  void initState() {
    super.initState();
    _refreshMockStatus();
  }

  Future<void> _refreshMockStatus() async {
    try {
      final response = await _mockChannel.invokeMapMethod<String, dynamic>(
        'getMockStatus',
      );
      if (!mounted) return;
      setState(() {
        _isMockSetupReady = (response?['isMockSetupReady'] as bool?) ?? false;
        _isOn = (response?['isMockActive'] as bool?) ?? false;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _isMockSetupReady = false;
      });
    }
  }

  Future<void> _togglePower() async {
    if (_isLoading) {
      return;
    }

    if (_isOn) {
      setState(() {
        _isOn = false;
        _statusMessage = 'Mock location OFF';
      });
      try {
        await _mockChannel.invokeMethod<void>('clearMockLocation');
      } on PlatformException {
        // Ignore provider clear failures when toggling off in UI.
      }
      await _refreshMockStatus();
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting mock location...';
    });

    try {
      final response = await _mockChannel.invokeMapMethod<String, dynamic>(
        'setMockLocation',
        <String, dynamic>{
          'latitude': _baseLatitude,
          'longitude': _baseLongitude,
          'radiusMeters': _radiusMeters,
        },
      );

      final lat = (response?['latitude'] as num?)?.toDouble() ?? _baseLatitude;
      final lng = (response?['longitude'] as num?)?.toDouble() ?? _baseLongitude;

      if (!mounted) return;
      setState(() {
        _isOn = true;
        _statusMessage =
            'Mock location ON: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      });
      await _refreshMockStatus();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _isOn = false;
        _statusMessage = e.message ??
            'Failed. Enable Developer Options -> Select mock location app -> Device Motorola.';
      });
      await _refreshMockStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_statusMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Motorola')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatusDot(
                  label: 'Setup',
                  isOn: _isMockSetupReady,
                ),
                const SizedBox(width: 28),
                _StatusDot(
                  label: 'Active',
                  isOn: _isOn,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _isOn ? 'ON' : 'OFF',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isLoading ? null : _togglePower,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isOn ? 'Turn OFF' : 'Turn ON'),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.label,
    required this.isOn,
  });

  final String label;
  final bool isOn;

  @override
  Widget build(BuildContext context) {
    final color = isOn ? Colors.green : Colors.red;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
