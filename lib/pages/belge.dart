import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:onderliftmobil/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BelgeScreen extends StatefulWidget {
  @override
  _BelgeScreenState createState() => _BelgeScreenState();
}

class _BelgeScreenState extends State<BelgeScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DocumentsScreen(),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => KVKKScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.grey, // Buton rengi
                ),
                child: Text(
                  'KVKK Politikası',
                  style: TextStyle(
                    fontSize: 18, // Yazı boyutu
                    color: Color(0xFF222F5A), // Yazı rengi
                  ),
                ),
              ),
              SizedBox(height: 20), // Boşluk ekleyin
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PrivacyScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.grey, // Buton rengi
                ),
                child: Text(
                  'Gizlilik Politikası',
                  style: TextStyle(
                    fontSize: 18, // Yazı boyutu
                    color: Color(0xFF222F5A), // Yazı rengi
                  ),
                ),
              ),
              SizedBox(height: 20), // Boşluk ekleyin
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DestructionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.grey, // Buton rengi
                ),
                child: Text(
                  'Veri Saklama ve İmha',
                  style: TextStyle(
                    fontSize: 18, // Yazı boyutu
                    color: Color(0xFF222F5A), // Yazı rengi
                  ),
                ),
              ),
              SizedBox(height: 20), // Boşluk ekleyin
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManualScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20), backgroundColor: Colors.grey, // Buton rengi
                ),
                child: Text(
                  'Kullanma Kılavuzu',
                  style: TextStyle(
                    fontSize: 18, // Yazı boyutu
                    color: Color(0xFF222F5A), // Yazı rengi
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KVKKScreen extends StatefulWidget {
  @override
  _KVKKScreenState createState() => _KVKKScreenState();
}

class _KVKKScreenState extends State<KVKKScreen> {
  late InAppWebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KVKK'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://www.ondergrup.com/kvkk-politikasi/')),
        onWebViewCreated: (InAppWebViewController webViewController) {
          _controller = webViewController;
        },
        onLoadStart: (controller, url) {
          // Sayfa yüklenirken yapılacak işlemler
        },
        onLoadStop: (controller, url) {
          // Sayfa yüklendikten sonra yapılacak işlemler
        },
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            useOnDownloadStart: true,
          ),
        ),
        onProgressChanged: (controller, progress) {
          // Sayfa yüklenme ilerlemesi değiştiğinde yapılacak işlemler
        },
        onDownloadStart: (controller, url) {
          // İndirme başladığında yapılacak işlemler
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.goBack();
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}

class PrivacyScreen extends StatefulWidget {
  @override
  _PrivacyScreenState createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late InAppWebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gizlilik Politikası'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://www.ondergrup.com/gizlilik-politikasi/')),
        onWebViewCreated: (InAppWebViewController webViewController) {
          _controller = webViewController;
        },
        onLoadStart: (controller, url) {
          // Sayfa yüklenirken yapılacak işlemler
        },
        onLoadStop: (controller, url) {
          // Sayfa yüklendikten sonra yapılacak işlemler
        },
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            useOnDownloadStart: true,
          ),
        ),
        onProgressChanged: (controller, progress) {
          // Sayfa yüklenme ilerlemesi değiştiğinde yapılacak işlemler
        },
        onDownloadStart: (controller, url) {
          // İndirme başladığında yapılacak işlemler
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.goBack();
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}

class DestructionScreen extends StatefulWidget {
  @override
  _DestructionScreenState createState() => _DestructionScreenState();
}

class _DestructionScreenState extends State<DestructionScreen> {
  late InAppWebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Veri Saklama ve İmha Politikası'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://www.ondergrup.com/veri-saklama-ve-imha-politikasi/')),
        onWebViewCreated: (InAppWebViewController webViewController) {
          _controller = webViewController;
        },
        onLoadStart: (controller, url) {
          // Sayfa yüklenirken yapılacak işlemler
        },
        onLoadStop: (controller, url) {
          // Sayfa yüklendikten sonra yapılacak işlemler
        },
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            useOnDownloadStart: true,
          ),
        ),
        onProgressChanged: (controller, progress) {
          // Sayfa yüklenme ilerlemesi değiştiğinde yapılacak işlemler
        },
        onDownloadStart: (controller, url) {
          // İndirme başladığında yapılacak işlemler
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.goBack();
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}

class ManualScreen extends StatefulWidget {
  @override
  _ManualScreenState createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  late InAppWebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kılavuz'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri("https://docs.google.com/gview?embedded=true&url=https://hidirektor.com.tr/manual/manual.pdf")),
        onWebViewCreated: (InAppWebViewController webViewController) {
          _controller = webViewController;
        },
        onLoadStart: (controller, url) {
          // Sayfa yüklenirken yapılacak işlemler
        },
        onLoadStop: (controller, url) {
          // Sayfa yüklendikten sonra yapılacak işlemler
        },
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            useOnDownloadStart: true,
          ),
        ),
        onProgressChanged: (controller, progress) {
          // Sayfa yüklenme ilerlemesi değiştiğinde yapılacak işlemler
        },
        onDownloadStart: (controller, url) {
          // İndirme başladığında yapılacak işlemler
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.goBack();
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}

