import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/BottomCards.dart';
import 'package:flutter_app/dbms/circular.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
  print(message.data);
  // final SharedPreferences prefs = await SharedPreferences.getInstance();
  // final int counter = (prefs.getInt('counter') ?? 0) + 1;
  // await prefs.setInt('counter', counter);
  flutterLocalNotificationsPlugin.show(
      message.data.hashCode,
      message.notification.title,
      message.notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channel.description,
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
  final ins=FirebaseMessaging.instance;
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
  var box = Hive.box('myBox');

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SharedPreferences Demo"),
      ),
      body: Container(
        child: WatchBoxBuilder(
            box: box,
            builder: (context, snapshot) {
              final taskListFromFirebase = snapshot.get('postList') ?? List();
              List<BottomCards> dataList = [];
              for (var tasksData in taskListFromFirebase) {
                dataList.add(
                  BottomCards(
                    circular: tasksData,
                    dataFromDatabase: true,
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
            }),
      ),
    );
  }
}