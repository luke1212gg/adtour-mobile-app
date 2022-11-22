import 'dart:async';
import 'dart:math';

import 'package:android_app/widgets/configuration.dart';
import 'package:android_app/widgets/map/mapbox_widget.dart';
import 'package:android_app/widgets/newsfeed/cultural.dart';
import 'package:android_app/widgets/newsfeed/destination_confirmation.dart';
import 'package:android_app/widgets/newsfeed/manmade.dart';
import 'package:android_app/widgets/newsfeed/special_interest.dart';
import 'package:android_app/widgets/profile/profile_picture_view_widget.dart';
import 'package:android_app/widgets/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart';
import 'package:maps_toolkit/maps_toolkit.dart';
import 'package:android_app/custom_arts.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key? key}) : super(key: key);

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final User user = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic> userData = {'profile_url': null};
  List<QueryDocumentSnapshot> destinationInfos = <QueryDocumentSnapshot>[];
  List<LatLng> destinationPositions = <LatLng>[];
  Map<String, dynamic>? closestLocation;
  Timer? timer;
  ValueNotifier<bool> isDialOpen = ValueNotifier(false);

  Future<void> getLocations() async {
    CollectionReference culturalRef = FirebaseFirestore.instance
        .collection('LocationsData')
        .doc("cultural")
        .collection("destinations");

    QuerySnapshot querySnapshot = await culturalRef.get();

    // Get data from docs and convert map to List
    final culturalDesinations = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          destinationInfos.add(doc);
        });
      }
      return LatLng(
          double.parse(data['latitude']), double.parse(data['longitude']));
    }).toList();

    CollectionReference manmadeRef = FirebaseFirestore.instance
        .collection('LocationsData')
        .doc("manmade")
        .collection("destinations");

    querySnapshot = await manmadeRef.get();

    // Get data from docs and convert map to List
    final manmadeDesinations = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          destinationInfos.add(doc);
        });
      }
      return LatLng(
          double.parse(data['latitude']), double.parse(data['longitude']));
    }).toList();

    CollectionReference specialinterestRef = FirebaseFirestore.instance
        .collection('LocationsData')
        .doc("manmade")
        .collection("destinations");

    querySnapshot = await specialinterestRef.get();

    // Get data from docs and convert map to List
    final specialinterestDesinations = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          destinationInfos.add(doc);
        });
      }

      return LatLng(
          double.parse(data['latitude']), double.parse(data['longitude']));
    }).toList();

    final allData =
        culturalDesinations + manmadeDesinations + specialinterestDesinations;

    if (mounted) {
      setState(() {
        destinationPositions = allData;
      });
    }
  }

  Future<void> getUserLocation() async {
    if (destinationPositions.isEmpty) {
      return;
    }
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
    LatLng locationPosition =
        LatLng(locationData.latitude!, locationData.longitude!);

    num closestPosition = 100000000;
    int closestPositionIndex = 0;
    destinationPositions.asMap().forEach((index, value) {
      num distance =
          SphericalUtil.computeDistanceBetween(locationPosition, value);

      closestPosition = min(closestPosition, distance);
      if (closestPosition == distance) {
        closestPositionIndex = index;
      }
    });

    Map<String, dynamic> destinationData =
        destinationInfos[closestPositionIndex - 1].data()
            as Map<String, dynamic>;

    LatLng destinationPosition = destinationPositions[closestPositionIndex];

    setState(() {
      closestLocation = {
        'location_name': destinationData['name'],
        'distance': closestPosition / 1000,
        'data': destinationData,
        'id': destinationInfos[closestPositionIndex - 1].id,
        'latitude': destinationPosition.latitude,
        'longitude': destinationPosition.longitude,
        'comments': destinationInfos[closestPositionIndex - 1]
            .reference
            .collection('comments')
      };
    });
  }

  void checkConfigured() {
    if (userData['tourist_type'] == null) {
      timer!.cancel();
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ConfigurationWidget(
                    uid: user.uid,
                  )));
    }
  }

  @override
  void initState() {
    FirebaseAnalytics.instance.logLogin().then((value) {});
    FirebaseAnalytics.instance.logScreenView(screenName: "Home");
    FirebaseAnalytics.instance
        .setUserId(id: FirebaseAuth.instance.currentUser?.uid);
    DateTime today = DateTime.now();
    print("${today.year}-${today.month}-${today.day}");
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((data) {
      setState(() {
        userData = data.data()!;
      });
      checkConfigured();
    });
    FirebaseFirestore.instance
        .collection('admin')
        .doc('analytics')
        .get()
        .then((analyticsReference) {
      Map<String, dynamic> data = {};
      if (analyticsReference.data() != null) {
        data = analyticsReference.data() as Map<String, dynamic>;
      }
      if (data['logins'] != null) {
        data['logins'] += 1;
      } else {
        data['logins'] = 1;
      }
      FirebaseFirestore.instance
          .collection('admin')
          .doc('analytics')
          .set(data, SetOptions(merge: true))
          .then((value) {
        FirebaseFirestore.instance
            .collection('admin')
            .doc('analytics')
            .collection('logins')
            .doc("${today.year}-${today.month}-${today.day}")
            .get()
            .then((analyticsReference) {
          Map<String, dynamic> data = {};
          if (analyticsReference.data() != null) {
            data = analyticsReference.data() as Map<String, dynamic>;
          }
          if (data['logins'] != null) {
            data['logins'] += 1;
          } else {
            data['logins'] = 1;
          }
          FirebaseFirestore.instance
              .collection('admin')
              .doc('analytics')
              .collection('logins')
              .doc("${today.year}-${today.month}-${today.day}")
              .set(data, SetOptions(merge: true));
        });
      });
    });
    getLocations();
    timer = Timer.periodic(
        const Duration(seconds: 5), (Timer t) => getUserLocation());
    super.initState();
  }

  void signOut() {
    timer!.cancel();
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: bgColor,
        elevation: 0,
        toolbarHeight: 80,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePictureView(
                      profileURL: userData['profile_url'] ??
                          "https://t3.ftcdn.net/jpg/03/46/83/96/360_F_346839683_6nAPzbhpSkIpb8pmAwufkC7c5eD7wYws.jpg"),
                ));
          },
          child: CircleAvatar(
            child: ClipOval(
              child: userData['profile_url'] == null
                  ? Image.network(
                      width: 100,
                      height: 100,
                      "https://t3.ftcdn.net/jpg/03/46/83/96/360_F_346839683_6nAPzbhpSkIpb8pmAwufkC7c5eD7wYws.jpg",
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      userData['profile_url'],
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket),
            color: accentColor,
            iconSize: 19,
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 30, right: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Explore",
                  style: GoogleFonts.nunitoSans(
                      fontSize: 40, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: GridView.count(
                    primary: false,
                    padding: const EdgeInsets.all(20),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 2,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CulturalNewsfeedWidget()));
                        },
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: AssetImage(
                                      'assets/cultural_background.jpg'))),
                          child: FractionallySizedBox(
                            widthFactor: 1,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: categoryTextBGColor,
                                    borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10))),
                                height: 30,
                                alignment: Alignment.center,
                                child: const Text(
                                  "Cultural",
                                  style: TextStyle(fontSize: 17),
                                )),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ManMadeNewsfeedWidget()));
                        },
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: AssetImage(
                                      'assets/manmade_background.jpg'))),
                          child: FractionallySizedBox(
                            widthFactor: 1,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: categoryTextBGColor,
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10))),
                                height: 30,
                                alignment: Alignment.center,
                                child: const Text(
                                  "Man Made",
                                  style: TextStyle(fontSize: 17),
                                )),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SpecialInterestNewsfeedWidget()));
                        },
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: AssetImage(
                                      'assets/special_interest.jpg'))),
                          child: FractionallySizedBox(
                            widthFactor: 1,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: categoryTextBGColor,
                                    borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10))),
                                height: 30,
                                alignment: Alignment.center,
                                child: const Text(
                                  "Special Interest",
                                  style: TextStyle(fontSize: 17),
                                )),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                // Expanded(child: ListView.builder(itemBuilder: ((context, index) {

                // }),))
              ],
            ),
          ),
          Positioned(
              bottom: 0,
              left: 0,
              child: GestureDetector(
                onTap: () {
                  if (closestLocation != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DestinationConfirmationWidget(
                                data: closestLocation!['data'],
                                id: closestLocation!['id'],
                                collectionReference:
                                    closestLocation!['comments'])));
                  }
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 200,
                      child: Column(
                        children: [
                          ...(closestLocation != null
                              ? [
                                  Text(
                                    closestLocation!["location_name"],
                                    style: TextStyle(fontSize: 20),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ]
                              : []),
                          Text(
                            "Closest Location${closestLocation != null ? " (${(closestLocation!["distance"] as num).toStringAsFixed(1)} km)" : ""}",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
