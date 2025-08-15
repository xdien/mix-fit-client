import 'package:auth/domain/usecase/is_logged_in_usecase.dart';
import 'package:constants/app_routes.dart';
import 'package:core/domain/usecase/use_case.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../di/service_locator.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  final IsLoggedInUseCase isLoggedInUseCase = getIt<IsLoggedInUseCase>();
  WebSocketManager? _webSocketManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _webSocketManager?.handleAppLifecycle(state);
  }

  _checkAuthAndNavigate() async {
    await Future.delayed(Duration(seconds: 2));

    if (await isLoggedInUseCase.call(params: NoParams())) {
      // Initialize WebSocket connection for authenticated user
      await _initializeWebSocket();
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      print('Initializing WebSocket connection...');
      _webSocketManager = getIt<WebSocketManager>();
      
      // Get the actual authentication token
      final sharedPrefHelper = getIt<SharedPreferenceHelper>();
      String? authToken = await sharedPrefHelper.authToken;
      
      if (authToken == null || authToken.isEmpty) {
        print('No authentication token available, using development token for WebSocket');
        // Use development token for testing
        authToken = 'development-token';
      }
      
      // Initialize with proper configuration
      _webSocketManager!.initialize(
        config: const WebSocketConfig(
          url: 'http://localhost:3000/socket.io', // Use correct Socket.IO URL
          reconnectInterval: Duration(seconds: 5),
          maxReconnectAttempts: 5,
          heartbeatInterval: Duration(seconds: 30),
          autoReconnect: true,
        ),
        getAuthToken: () async => authToken, // Use actual auth token
      );
      
      // Listen to connection state changes
      _webSocketManager!.connectionState.listen((state) {
        print('WebSocket connection state: $state');
      });
      
      // Connect to WebSocket
      print('Connecting to WebSocket...');
      await _webSocketManager!.connect();
      
      // Subscribe to relevant channels
      _webSocketManager!.subscribe('inventory', (data) {
        print('Received inventory update: $data');
      });
      
      _webSocketManager!.subscribe('customers', (data) {
        print('Received customer update: $data');
      });
      
      _webSocketManager!.subscribe('orders', (data) {
        print('Received order update: $data');
      });
      
      print('WebSocket initialized successfully');
      
    } catch (e) {
      print('Failed to initialize WebSocket: $e');
      // Continue without WebSocket - app can still function
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/ic_appicon.png'),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
