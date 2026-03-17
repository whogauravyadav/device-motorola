import 'dart:async';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8383)),
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
  static const String _validUsername =
      String.fromEnvironment('APP_USERNAME', defaultValue: 'karishma');
  static const String _validPassword =
      String.fromEnvironment('APP_PASSWORD', defaultValue: 'pd143@grv');

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

    if (_validUsername.isEmpty || _validPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Login credentials are not configured. Start app with --dart-define values.',
          ),
        ),
      );
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
    final borderColor = Colors.white.withValues(alpha: 0.2);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFFF8383),
              Color(0xFFFF9A9A),
              Color(0xFFFFB3B3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: borderColor),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.24),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Hello Moto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Login to continue',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.08),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.white),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.08),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Colors.white),
                                  ),
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
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 52,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFFF8383),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  onPressed: _login,
                                  child: const Text('Login'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const MethodChannel _mockChannel =
      MethodChannel('com.example.device_motorola/mock_location');
  static const double _baseLatitude = 25.791440;
  static const double _baseLongitude = 85.838427;
  static const double _radiusMeters = 15;
  static const List<String> _topGifs = <String>[
    'lib/krishna.gif',
    'lib/maha.gif',
  ];

  bool _isOn = false;
  bool _isMockSetupReady = false;
  bool _isLoading = false;
  bool _hasRedirectedToMockSettings = false;
  int _currentGifIndex = 0;
  Timer? _gifSwapTimer;
  String _statusMessage = 'Tap Turn ON to set mock location';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startGifRotation();
    _refreshMockStatus();
  }

  @override
  void dispose() {
    _gifSwapTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startGifRotation() {
    _gifSwapTimer?.cancel();
    _gifSwapTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _currentGifIndex = (_currentGifIndex + 1) % _topGifs.length;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshMockStatus();
    }
  }

  Future<void> _refreshMockStatus() async {
    try {
      final response = await _mockChannel.invokeMapMethod<String, dynamic>(
        'getMockStatus',
      );
      if (!mounted) return;
      final isSetupReady = (response?['isMockSetupReady'] as bool?) ?? false;
      final isMockActive = (response?['isMockActive'] as bool?) ?? false;
      setState(() {
        _isMockSetupReady = isSetupReady;
        _isOn = isMockActive;
      });
      if (!isSetupReady) {
        await _redirectToMockLocationSettings();
      } else {
        _hasRedirectedToMockSettings = false;
      }
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _isMockSetupReady = false;
      });
    }
  }

  Future<void> _redirectToMockLocationSettings({bool force = false}) async {
    if (!force && _hasRedirectedToMockSettings) {
      return;
    }

    _hasRedirectedToMockSettings = true;
    setState(() {
      _statusMessage =
          'Select this app in Developer Options -> Select mock location app.';
    });

    try {
      final opened =
          await _mockChannel.invokeMethod<bool>('openMockLocationSettings') ??
          false;
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open settings automatically. Open Developer Options manually.',
            ),
          ),
        );
      }
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open settings. Please open Developer Options manually.'),
        ),
      );
    }
  }

  Future<void> _togglePower() async {
    if (_isLoading) {
      return;
    }

    await _refreshMockStatus();
    if (!mounted) return;

    if (!_isMockSetupReady) {
      await _redirectToMockLocationSettings(force: true);
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
      final debugInfo = await _getNativeDebugInfo();
      if (!mounted) return;
      setState(() {
        _isOn = false;
        _statusMessage =
            '${e.message ?? 'Failed to set mock location.'} ${debugInfo.isNotEmpty ? '\n$debugInfo' : ''}';
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

  Future<String> _getNativeDebugInfo() async {
    try {
      final info = await _mockChannel.invokeMapMethod<String, dynamic>(
        'getMockDebugInfo',
      );
      final lastEvent = (info?['lastEvent'] as String?) ?? '';
      final pref = (info?['isMockActivePref'] as bool?) ?? false;
      final mem = (info?['isMockActiveMem'] as bool?) ?? false;
      if (lastEvent.isEmpty) {
        return '';
      }
      return 'Debug: pref=$pref mem=$mem event=$lastEvent';
    } on PlatformException {
      return '';
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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Image.asset(
                  _topGifs[_currentGifIndex],
                  key: ValueKey<int>(_currentGifIndex),
                  width: 300,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),
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
                color: color.withValues(alpha: 0.5),
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
