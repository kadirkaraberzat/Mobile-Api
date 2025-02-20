import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İşaret Dili Destekli Uygulama',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(), // Burada HomeScreen widget
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/sign_language_guide.mp4')
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ana Sayfa')),
      body: Center(
        child: FadeIn(
          duration: Duration(milliseconds: 1000),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : CircularProgressIndicator(),
              SizedBox(height: 20),
              BounceInUp(
                duration: Duration(milliseconds: 1000),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: Text('Kayıt Ol'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kayıt Ol')),
      body: Center(
        child: ZoomIn(
          duration: Duration(milliseconds: 1000),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NormalRegisterScreen()),
                  );
                },
                child: Text('Okur Yazarım - Normal Kayıt'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CustomerServiceScreen()),
                  );
                },
                child: Text('Okur Yazar Değilim - Müşteri Hizmetleri'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NormalRegisterScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> registerUser() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );
      if (response.statusCode == 200) {
        print('Kayıt başarılı');
      } else {
        print('Kayıt başarısız');
      }
    } catch (e) {
      print('Hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Normal Kayıt')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: FadeInDown(
          duration: Duration(milliseconds: 1000),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerUser,
                child: Text('Kayıt Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerServiceScreen extends StatefulWidget {
  @override
  _CustomerServiceScreenState createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen> {
  late RTCVideoRenderer _remoteRenderer;
  late RTCVideoRenderer _localRenderer;
  late WebSocketChannel _channel; // WebSocket
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;

  @override
  void initState() {
    super.initState();
    _remoteRenderer = RTCVideoRenderer();
    _localRenderer = RTCVideoRenderer();
    initializeRenderers();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    _peerConnection.dispose();
    _channel.sink.close();
    super.dispose();
  }

  void initializeRenderers() async {
    await _remoteRenderer.initialize();
    await _localRenderer.initialize();
  }

  // WebSocket bağlantısını başlatma
  void _initializeWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080'),
    );

    _channel.stream.listen((message) {
      print('WebSocket message: $message');
    });
  }

  Future<void> _startLocalStream() async {
    MediaStream stream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });
    _localStream = stream;
    _localRenderer.srcObject = _localStream;
    _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    _peerConnection.onIceCandidate = (candidate) {
      if (candidate != null) {
        _sendMessage({'type': 'candidate', 'candidate': candidate.toMap()});
      }
    };

    _peerConnection.onAddStream = (stream) {
      _remoteRenderer.srcObject = stream;
    };

    _peerConnection.addStream(_localStream);
  }

  void connectToCustomerService() async {
    await _startLocalStream();
    RTCSessionDescription offer = await _peerConnection.createOffer();
    await _peerConnection.setLocalDescription(offer);
    _sendMessage({'type': 'offer', 'sdp': offer.sdp});
  }

  void _sendMessage(Map<String, dynamic> message) {
    _channel.sink.add(message);
  }

  void _endCall() {
    _peerConnection.close();
    _channel.sink.close();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Müşteri Hizmetleri')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Draggable(
              feedback: Container(
                width: 150,
                height: 200,
                color: Colors.white,
                child: RTCVideoView(_remoteRenderer),
              ),
              childWhenDragging: Container(),
              child: Container(
                width: 150,
                height: 200,
                color: Colors.white,
                child: RTCVideoView(_remoteRenderer),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: connectToCustomerService,
            child: Icon(Icons.call),
            backgroundColor: Colors.green,
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _endCall,
            child: Icon(Icons.call_end),
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
