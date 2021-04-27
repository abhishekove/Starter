import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/BottomCards.dart';
import 'package:flutter_app/dbms/circular.dart';
import 'package:flutter_app/internet.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
  print(message.data);
  await notifier();
  flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification.title,
      message.notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channel.description,
          icon: message.notification.android?.smallIcon,
        ),
      ));
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  'This channel is used for important notifications.', // description
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final ins = FirebaseMessaging.instance;
  ins.subscribeToTopic("puppies");

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  Hive.registerAdapter(CircularAdapter());
  await Hive.openBox('myBox');
  runApp(MaterialApp(
    title: 'SharedPreferences Demo',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  var box = Hive.box('myBox');
  bool internet = false;

  @override
  void initState() {
    super.initState();
    check().then((value) {
      if (value != null && value) {
        // Internet Present Case
        setState(() {
          internet = true;
        });
      } else {
        setState(() {
          internet = false;
        });
      }
    });
    var initialzationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initialzationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                icon: android?.smallIcon,
              ),
            ));
      }
    });
  }

  _getPublicSnapshots() async {
    QuerySnapshot qn = await _firebaseFirestore
        .collection("public")
        .get();
    return qn.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Firebase'),
      ),
      body: internet
          ? Container(
              child: FutureBuilder(
                future: notifications(),
                builder: (context, snapshot) {
                  if (snapshot.data ?? false)
                    return FutureBuilder(
                        future: _getPublicSnapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Container(
                                color: Colors.white,
                                child: new LayoutBuilder(
                                    builder: (context, constraint) {
                                  return new Icon(
                                      Icons.report_gmailerrorred_outlined,
                                      size: min(constraint.biggest.height,
                                          constraint.biggest.width));
                                }),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return Center(
                              child: Container(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: Text("Loading..."),
                            );
                          }
                          final taskListFromFirebase = snapshot.data;
                          List<Widget> dataList = [];
                          var box = Hive.box('myBox');
                          List cache = [];
                          for (var tasksData in taskListFromFirebase) {
                            var taskDetails = tasksData.data();
                            cache.add(new Circular(
                              title: taskDetails['title'] ?? "",
                              content: taskDetails['content'] ?? "",
                              imgUrl: taskDetails['imgUrl'] ?? "",
                              author: taskDetails['authorName'] ?? "",
                              id: taskDetails['id'] ?? "",
                              files: taskDetails['files'] ?? [],
                              channels: taskDetails['channels'] ?? [],
                              dept: taskDetails['dept'] ?? [],
                              year: taskDetails['year'] ?? [],
                              division: taskDetails['division'] ?? [],
                              date: taskDetails['ts'] != null
                                  ? DateTime.fromMillisecondsSinceEpoch(
                                      taskDetails['ts'] * 1000)
                                  : DateTime.now(),
                              type: taskDetails['type'],
                            ));
                            dataList.add(
                              BottomCards(
                                circular: new Circular(
                                  title: taskDetails['title'] ?? "",
                                  content: taskDetails['content'] ?? "",
                                  imgUrl: taskDetails['imgUrl'] ?? "",
                                  author: taskDetails['authorName'] ?? "",
                                  id: taskDetails['id'] ?? "",
                                  files: taskDetails['files'] ?? [],
                                  channels: taskDetails['channels'] ?? [],
                                  dept: taskDetails['dept'] ?? [],
                                  year: taskDetails['year'] ?? [],
                                  division: taskDetails['division'] ?? [],
                                  date: taskDetails['ts'] != null
                                      ? DateTime.fromMillisecondsSinceEpoch(
                                      taskDetails['ts'] * 1000)
                                      : DateTime.now(),
                                  type: taskDetails['type'],
                                ),
                                dataFromDatabase: box.get(
                                        taskDetails['id'].toString().trim()) ??
                                    false,
                              ),
                            );
                          }
                          box.put('cache', cache);
                          return ListView.separated(
                            itemCount: dataList.length,
                            itemBuilder: (context, index) {
                              return dataList[index];
                            },
                            separatorBuilder: (context, index) {
                              return Divider(
                                height: 2.0,
                              );
                            },
                          );
                        });

                  return WatchBoxBuilder(
                      box: box,
                      builder: (context, snapshot) {
                        final taskListFromFirebase =
                            snapshot.get('cache') ?? List();
                        List<BottomCards> dataList = [];
                        for (var tasksData in taskListFromFirebase) {
                          dataList.add(
                            BottomCards(
                              circular: tasksData,
                              dataFromDatabase:
                                  box.get(tasksData.id.toString().trim()) ??
                                      false,
                            ),
                          );
                        }
                        return (dataList.length == 0)
                            ? Center(
                                child: Image(
                                  image: AssetImage('assets/images/empty.png'),
                                ),
                              )
                            : ListView.separated(
                                itemCount: dataList.length,
                                itemBuilder: (context, index) {
                                  return dataList[index];
                                },
                                separatorBuilder: (context, index) {
                                  return Divider(
                                    height: 2.0,
                                  );
                                },
                              );
                      });
                },
              ),
            )
          : Internet(),
    );
  }
}
// Check internet connectivity
Future<bool> check() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  }
  return false;
}

Future<void> notifier() async {
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  Hive.registerAdapter(CircularAdapter());
  var box=await Hive.openBox('myBox');
  print("inside notifier");
  box.put('counter', true);
}

Future<bool> notifications() async {
  await Hive.openBox('myBox');
  var box = Hive.box('myBox');
  bool val = box.get('counter') ?? true;
  box.put('counter', false);
  print(val);
  return val;
}
