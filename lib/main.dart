import 'dart:async';  // 非同期操作を行うためのパッケージをインポート
import 'package:flutter/foundation.dart';  // Flutterアプリの動作環境に関する情報を提供するパッケージをインポート
import 'package:flutter/material.dart';  // FlutterのUIコンポーネントを提供するパッケージをインポート
import 'package:flutter_inappwebview/flutter_inappwebview.dart';  // WebViewを表示するためのパッケージをインポート
import 'package:url_launcher/url_launcher.dart';  // URLを開くためのパッケージをインポート

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Flutterアプリの初期化を確認

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);  // AndroidのWebViewでデバッグモードを有効にする
  }

  runApp(const MaterialApp(home: MyApp()));  // アプリを実行
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();  // WebViewのキーを作成

  InAppWebViewController? webViewController;  // WebViewのコントローラを定義

  PullToRefreshController? pullToRefreshController;  // プルダウン更新のコントローラを定義
  String url = "";  // 現在のURLを保持する変数を定義
  double progress = 0;  // ページの読み込み進捗を保持する変数を定義
  final urlController = TextEditingController();  // URL入力用のテキストコントローラを定義

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("InAppWebView")),  // アプリバーを作成
        body: SafeArea(
            child: Column(children: <Widget>[
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search)),  // 検索用のテキストフィールドを作成
            controller: urlController,
            keyboardType: TextInputType.url,
            onSubmitted: (value) {
              var url = Uri.parse(value);  // 入力された値をURLとしてパースする
              if (url.scheme.isEmpty) {
                url = Uri.parse("https://www.google.com/search?q=$value");  // URLにスキームがない場合、Google検索のURLを生成する
              }
              webViewController?.loadUrl(urlRequest: URLRequest(url: url));  // WebViewでURLをロードする
            },
          ),
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  key: webViewKey,  // WebViewを作成し、キーを設定する
                  initialUrlRequest:
                      URLRequest(url: Uri.parse("https://www.digital.go.jp/")),  // 初期表示するURLを指定する
                  pullToRefreshController: pullToRefreshController,  // プルダウン更新のコントローラを設定する
                  onWebViewCreated: (controller) {
                    webViewController = controller;  // WebViewが作成されたときにコントローラを取得する
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      this.url = url.toString();  // ページの読み込みが開始されたときにURLを更新する
                      urlController.text = this.url;
                    });
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    var uri = navigationAction.request.url!;

                    if (![
                      "http",
                      "https",
                      "file",
                      "chrome",
                      "data",
                      "javascript",
                      "about"
                    ].contains(uri.scheme)) {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                        );  // アプリを起動する
                        return NavigationActionPolicy.CANCEL;  // リクエストをキャンセルする
                      }
                    }

                    return NavigationActionPolicy.ALLOW;  // ナビゲーションを許可する
                  },
                  onLoadStop: (controller, url) async {
                    pullToRefreshController?.endRefreshing();
                    setState(() {
                      this.url = url.toString();  // ページの読み込みが停止したときにURLを更新する
                      urlController.text = this.url;
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      pullToRefreshController?.endRefreshing();
                    }
                    setState(() {
                      this.progress = progress / 100;  // ページの読み込みの進捗を更新する
                      urlController.text = url;
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    setState(() {
                      this.url = url.toString();  // ページの履歴が更新されたときにURLを更新する
                      urlController.text = this.url;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint(consoleMessage.toString());  // コンソールメッセージをデバッグ出力する
                  },
                ),
                progress < 1.0
                    ? LinearProgressIndicator(value: progress)  // ページの読み込み進捗を表示する
                    : Container(),
              ],
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                child: const Icon(Icons.arrow_back),  // 戻るボタンを作成
                onPressed: () {
                  webViewController?.goBack();  // WebViewで前のページに戻る
                },
              ),
              ElevatedButton(
                child: const Icon(Icons.arrow_forward),  // 進むボタンを作成
                onPressed: () {
                  webViewController?.goForward();  // WebViewで次のページに進む
                },
              ),
              ElevatedButton(
                child: const Icon(Icons.refresh),  // リフレッシュボタンを作成
                onPressed: () {
                  webViewController?.reload(); 
webViewController?.reload();  // WebViewをリロードする
                },
              ),
            ],
          ),
        ])));
  }
}