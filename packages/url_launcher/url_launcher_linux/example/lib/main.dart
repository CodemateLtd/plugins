// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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
      home: MyHomePage(title: 'URL Launcher'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final presetForHTTPSchema = 'http://flutter.dev/';
  static final presetForHTTPSSchema = 'https://flutter.dev/';
  static final presetForMailtoSchema = 'mailto:example@example.com';
  static final presetForFileSchema = 'file:/home/';

  String toLaunch = presetForHTTPSSchema;

  final textEditingController = TextEditingController();
  Future<void>? _launched;

  @override
  void initState() {
    super.initState();

    textEditingController.text = toLaunch;
    textEditingController.addListener(() => setState(() {
          toLaunch = textEditingController.text; //Uri.encodeFull();
        }));
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    if (await UrlLauncherPlatform.instance.canLaunch(url)) {
      await UrlLauncherPlatform.instance.launch(
        url,
        useSafariVC: false,
        useWebView: false,
        enableJavaScript: false,
        enableDomStorage: false,
        universalLinksOnly: false,
        headers: <String, String>{},
      );
    } else {
      throw 'Could not launch URL: $url';
    }
  }

  Widget _launchStatus(BuildContext context, AsyncSnapshot<void> snapshot) {
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return const Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Wrap(children: [
                Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () =>
                          textEditingController.text = presetForHTTPSchema,
                      child: Text("http"),
                    )),
                Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () =>
                          textEditingController.text = presetForHTTPSSchema,
                      child: Text("https"),
                    )),
                Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () =>
                          textEditingController.text = presetForFileSchema,
                      child: Text("file"),
                    )),
                Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () =>
                          textEditingController.text = presetForMailtoSchema,
                      child: Text("mailto"),
                    )),
              ]),
              Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter URL here',
                    ),
                  )),
              ElevatedButton(
                onPressed: () => setState(() {
                  _launched = _launchURL(toLaunch);
                }),
                child: const Text('Launch URL'),
              ),
              const Padding(padding: EdgeInsets.all(16.0)),
              FutureBuilder<void>(future: _launched, builder: _launchStatus),
            ],
          ),
        ],
      ),
    );
  }
}
