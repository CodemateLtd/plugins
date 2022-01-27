// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URL Launcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'URL Launcher'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String presetForHTTPSSchema = 'https://flutter.dev';
  static const String presetForMailtoSchema =
      'mailto:smith@example.org?subject=News&body=Message';
  static const String presetForFolderSchema = 'file:/';
  String _phone = '';
  String _mailto = presetForMailtoSchema;
  String _filePath = presetForFolderSchema;

  bool _hasCallSupport = false;
  Future<void>? _launched;
  String _toLaunch = presetForHTTPSSchema;

  final TextEditingController textEditingController = TextEditingController();
  final TextEditingController textMailtoController =
      TextEditingController(text: presetForMailtoSchema);
  final TextEditingController textFileController =
      TextEditingController(text: presetForFolderSchema);

  @override
  void initState() {
    super.initState();
    // Check for phone call support.
    canLaunch('tel:123').then((bool result) {
      setState(() {
        _hasCallSupport = result;
      });
    });
    textEditingController.text = _toLaunch;
    textEditingController.addListener(
      () => setState(
        () {
          _toLaunch = textEditingController.text;
        },
      ),
    );
    textMailtoController.text = presetForMailtoSchema;
    textMailtoController.addListener(
      () => setState(
        () {
          _mailto = textMailtoController.text;
        },
      ),
    );
    textFileController.addListener(
      () => setState(
        () {
          _filePath = textFileController.text;
        },
      ),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    textMailtoController.dispose();
    textFileController.dispose();
    super.dispose();
  }

  Future<void> _launchInBrowser(String url) async {
    if (!await launch(
      url,
      forceSafariVC: false,
      forceWebView: false,
      headers: <String, String>{'my_header_key': 'my_header_value'},
    )) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchInWebViewOrVC(String url) async {
    if (!await launch(
      url,
      forceSafariVC: true,
      forceWebView: true,
      headers: <String, String>{'my_header_key': 'my_header_value'},
    )) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchInWebViewWithJavaScript(String url) async {
    if (!await launch(
      url,
      forceSafariVC: true,
      forceWebView: true,
      enableJavaScript: true,
    )) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchInWebViewWithDomStorage(String url) async {
    if (!await launch(
      url,
      forceSafariVC: true,
      forceWebView: true,
      enableDomStorage: true,
    )) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchUniversalLinkIos(String url) async {
    final bool nativeAppLaunchSucceeded = await launch(
      url,
      forceSafariVC: false,
      universalLinksOnly: true,
    );
    if (!nativeAppLaunchSucceeded) {
      await launch(
        url,
        forceSafariVC: true,
      );
    }
  }

  Widget _launchStatus(BuildContext context, AsyncSnapshot<void> snapshot) {
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return const Text('');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Use `Uri` to ensure that `phoneNumber` is properly URL-encoded.
    // Just using 'tel:$phoneNumber' would create invalid URLs in some cases,
    // such as spaces in the input, which would cause `launch` to fail on some
    // platforms.
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launch(launchUri.toString());
  }

  Future<void> _makeSmsMessage(String phoneNumber) async {
    // Use `Uri` to ensure that `phoneNumber` is properly URL-encoded.
    // Just using 'sms:$phoneNumber' would create invalid URLs in some cases,
    // such as spaces in the input, which would cause `launch` to fail on some
    // platforms.
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    await launch(launchUri.toString());
  }

  Future<void> _launchURL(
    String url, {
    bool? forceSafariVC,
    bool forceWebView = false,
    bool enableJavaScript = false,
    bool enableDomStorage = false,
    bool universalLinksOnly = false,
  }) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: forceSafariVC,
        forceWebView: forceWebView,
        enableJavaScript: enableJavaScript,
        enableDomStorage: enableDomStorage,
        universalLinksOnly: universalLinksOnly,
        headers: <String, String>{},
      );
    } else {
      throw 'Could not launch URL: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle _bold = TextStyle(fontWeight: FontWeight.bold);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(left: 8),
                    child: TextField(
                      onChanged: (String text) => _phone = text,
                      decoration: const InputDecoration(
                        hintText: 'Input the phone number to launch',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: _hasCallSupport
                            ? () => setState(
                                  () {
                                    _launched = _makePhoneCall(_phone);
                                  },
                                )
                            : null,
                        child: _hasCallSupport
                            ? const Text('Launch phone call')
                            : const Text('Calling not supported'),
                      ),
                      ElevatedButton(
                        onPressed: _hasCallSupport
                            ? () => setState(
                                  () {
                                    _launched = _makeSmsMessage(_phone);
                                  },
                                )
                            : null,
                        child: _hasCallSupport
                            ? const Text('Launch sms message')
                            : const Text('SMS not supported'),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: textMailtoController,
                      onChanged: (String text) => _mailto = text,
                      decoration:
                          const InputDecoration(hintText: 'Input email'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () => setState(
                        () {
                          _launched = launch(_mailto);
                        },
                      ),
                      child: const Text('Launch mailto'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(left: 8),
                    child: TextField(
                      controller: textFileController,
                      onChanged: (String text) => _filePath = text,
                      decoration: const InputDecoration(
                        hintText: 'Input file or folder path',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: kIsWeb || Platform.isAndroid || Platform.isIOS
                          ? null
                          : () {
                              setState(
                                () {
                                  _launched = _launchURL(_filePath);
                                },
                              );
                            },
                      child: const Text('Launch file'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<void>(
                future: _launched,
                builder: _launchStatus,
              ),
              Container(
                width: MediaQuery.of(context).size.width / 2,
                padding: const EdgeInsets.all(0.0),
                child: TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  controller: textEditingController,
                  decoration: const InputDecoration(
                    hintText: 'Input the URL to launch',
                  ),
                ),
              ),
              _buildActionCard(
                onPressed: () => setState(
                  () {
                    _launched = _launchURL(_toLaunch);
                  },
                ),
                buttonText: 'Launch URL',
                descLines: <TextSpan>[
                  const TextSpan(text: 'Launch URL using the '),
                  const TextSpan(
                    text: 'default handler ',
                    style: _bold,
                  ),
                  const TextSpan(text: 'on the platform'),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                children: <Widget>[
                  _buildActionCard(
                    onPressed: kIsWeb || !Platform.isAndroid && !Platform.isIOS
                        ? null
                        : () {
                            setState(
                              () {
                                _launched = _launchInBrowser(_toLaunch);
                              },
                            );
                          },
                    buttonText: 'Launch in browser',
                    descLines: <TextSpan>[
                      const TextSpan(text: 'Android: '),
                      const TextSpan(
                        text: 'WebView\n',
                        style: _bold,
                      ),
                      const TextSpan(text: 'iOS: '),
                      const TextSpan(
                        text: 'Safari View Controller',
                        style: _bold,
                      )
                    ],
                  ),
                  _buildActionCard(
                    onPressed: kIsWeb || !Platform.isAndroid
                        ? null
                        : () {
                            setState(
                              () {
                                _launched =
                                    _launchInWebViewWithJavaScript(_toLaunch);
                              },
                            );
                          },
                    buttonText: 'Launch in browser with Javascript',
                    descLines: <TextSpan>[
                      const TextSpan(
                        text: 'enableJavaScript ',
                        style: _bold,
                      ),
                      const TextSpan(text: 'is an Android only setting'),
                    ],
                  ),
                  _buildActionCard(
                    onPressed: kIsWeb || !Platform.isAndroid
                        ? null
                        : () {
                            setState(
                              () {
                                _launched =
                                    _launchInWebViewWithDomStorage(_toLaunch);
                              },
                            );
                          },
                    buttonText: 'Launch in browser with DOM Storage',
                    descLines: <TextSpan>[
                      const TextSpan(
                        text: 'enableDomStorage ',
                        style: _bold,
                      ),
                      const TextSpan(text: 'is an Android only setting'),
                    ],
                  ),
                  _buildActionCard(
                    onPressed: kIsWeb || !Platform.isIOS
                        ? null
                        : () {
                            setState(
                              () {
                                _launched = _launchUniversalLinkIos(_toLaunch);
                              },
                            );
                          },
                    buttonText: 'Launch an universal link',
                    descLines: <TextSpan>[
                      const TextSpan(
                        text: 'universalLinksOnly ',
                        style: _bold,
                      ),
                      const TextSpan(
                          text: 'is iOS only setting, fallback to Safari'),
                    ],
                  ),
                  _buildActionCard(
                    onPressed: kIsWeb || !Platform.isAndroid && !Platform.isIOS
                        ? null
                        : () {
                            _launched = _launchInWebViewOrVC(_toLaunch);
                            Timer(
                              const Duration(seconds: 5),
                              () {
                                print('Closing WebView after 5 seconds...');
                                closeWebView();
                              },
                            );
                          },
                    buttonText: 'Launch in browser and close',
                    descLines: <TextSpan>[
                      const TextSpan(text: 'Calls '),
                      const TextSpan(
                        text: 'closeWebView ',
                        style: _bold,
                      ),
                      const TextSpan(text: 'after 5 seconds\n'),
                      const TextSpan(text: 'Android and iOS only'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Link(
                uri: Uri.parse(
                    'https://pub.dev/documentation/url_launcher/latest/link/link-library.html'),
                target: LinkTarget.blank,
                builder: (BuildContext ctx, FollowLink? openLink) {
                  return TextButton.icon(
                    onPressed: openLink,
                    label: const Text('Link Widget documentation'),
                    icon: const Icon(Icons.read_more),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    Function()? onPressed,
    required String buttonText,
    required List<TextSpan> descLines,
  }) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 80,
              minWidth: 300,
              maxWidth: 300,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                    children: descLines,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onPressed,
                  child: Text(
                    buttonText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
