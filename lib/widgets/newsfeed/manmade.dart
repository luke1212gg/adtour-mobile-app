import 'package:android_app/custom_arts.dart';
import 'package:android_app/widgets/newsfeed/destination_info_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../profile/profile_picture_view_widget.dart';

class ManMadeNewsfeedWidget extends StatefulWidget {
  const ManMadeNewsfeedWidget({Key? key}) : super(key: key);

  @override
  State<ManMadeNewsfeedWidget> createState() => _ManMadeNewsfeedWidgetState();
}

class _ManMadeNewsfeedWidgetState extends State<ManMadeNewsfeedWidget> {
  final User user = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic> userData = {'profile_url': null};
  final TextEditingController searchController = TextEditingController();
  List<QueryDocumentSnapshot<Object?>> destinations = [];
  List<QueryDocumentSnapshot<Object?>>? searchList = null;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((data) {
      setState(() {
        userData = data.data()!;
      });
    });
    super.initState();
  }

  void initSearchList() {
    if (searchList != null) {
      return;
    }
    setState(() {
      searchList = destinations;
    });
    print(destinations);
    print(searchList);
  }

  final Stream<QuerySnapshot> _destinationsStream = FirebaseFirestore.instance
      .collection('LocationsData')
      .doc('manmade')
      .collection('destinations')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _destinationsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasData) {
          Future.delayed(Duration.zero, () async {
            setState(() {
              destinations = snapshot.data!.docs;
            });
            initSearchList();
          });
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
                            width: 50,
                            height: 50,
                            "https://t3.ftcdn.net/jpg/03/46/83/96/360_F_346839683_6nAPzbhpSkIpb8pmAwufkC7c5eD7wYws.jpg",
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            userData['profile_url'],
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                          ),
                  ),
                ),
              ),
              actions: [
                Container(
                  width: 150,
                  child: TextField(
                    textAlignVertical: TextAlignVertical.bottom,
                    controller: searchController,
                    onChanged: (value) {
                      List<QueryDocumentSnapshot<Object?>> searched =
                          destinations.where((element) {
                        return ((element.data() as Map<String, dynamic>)['name']
                            .toString()
                            .toLowerCase()
                            .contains(searchController.text.toLowerCase()));
                      }).toList();

                      setState(() {
                        searchList = searched;
                      });
                      print(searchList);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const FaIcon(FontAwesomeIcons.house),
                  color: accentColor,
                  iconSize: 19,
                )
              ],
            ),
            body: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      Text(
                        "Explore",
                        style: TextStyle(fontSize: 35),
                      ),
                    ],
                  ),
                ),
                Expanded(
                    child: GridView.builder(
                        padding:
                            const EdgeInsets.only(left: 20, top: 50, right: 20),
                        itemCount: searchList == null ? 0 : searchList!.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: (2 / 3),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          Map<String, dynamic> data = searchList![index].data()!
                              as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          DestinationInfoWidget(
                                            data: data,
                                            id: searchList![index].id,
                                            collectionReference:
                                                searchList![index]
                                                    .reference
                                                    .collection('comments'),
                                          )));
                            },
                            child: Container(
                              alignment: Alignment.bottomCenter,
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: data['image_url'] == null
                                          ? AssetImage(
                                                  'assets/image_unavailable.jpg')
                                              as ImageProvider
                                          : NetworkImage(data['image_url']))),
                              child: FractionallySizedBox(
                                widthFactor: 1,
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: destinationCardTextBGColor,
                                        borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(10),
                                            bottomRight: Radius.circular(10))),
                                    height: 75,
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        data['name'],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: destinationCardTextColor),
                                        overflow: TextOverflow.clip,
                                      ),
                                    )),
                              ),
                            ),
                          );
                        }))
              ],
            ),
          );
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
