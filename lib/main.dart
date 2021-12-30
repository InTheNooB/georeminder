import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong/latlong.dart" as latLng;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoReminder',
      theme: ThemeData(primaryColor: Colors.black, fontFamily: 'Comfortaa'),
      home: MyHomePage(title: 'GeoReminder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Position _currentPosition;
  String _currentAddress;
  Geolocator geolocator;

  _MyHomePageState() {
    geolocator = Geolocator()..forceAndroidLocationManager;
    _getCurrentLocation();
  }

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);
      Placemark place = p[0];
      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 100.0, bottom: 60),
                child: (Text('GeoReminder', style: TextStyle(fontSize: 36)))),
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  height: 400,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: FlutterMap(
                    options: MapOptions(
                      center: latLng.LatLng(51.5, -0.09),
                      zoom: 13.0,
                    ),
                    layers: [
                      TileLayerOptions(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c']),
                      MarkerLayerOptions(
                        markers: [
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: latLng.LatLng(_currentPosition.latitude,
                                _currentPosition.longitude),
                            builder: (ctx) => Container(
                              child: Image(
                                image: AssetImage('images/markpoint.png'),
                              ), // Current location
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                InkWell(
                    // Add location button
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AddLocationDialog(
                                currentPosition: _currentPosition,
                                currentAddress: _currentAddress);
                          });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      width: 350,
                      height: 75,
                      child: Text("Add Location",
                          style: TextStyle(fontSize: 30, color: Colors.white)),
                    )),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 75.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 8,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              alignment: Alignment.center,
              width: 230,
              height: 37,
              child: Text("List",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}

class AddLocationDialog extends StatefulWidget {
  final String currentAddress;
  final Position currentPosition;

  const AddLocationDialog({Key key, this.currentPosition, this.currentAddress})
      : super(key: key);

  @override
  _AddLocationDialogState createState() =>
      _AddLocationDialogState(this.currentPosition, this.currentAddress);
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final String currentAddress;
  final Position currentPosition;

  final locationNameTextFieldController = TextEditingController();

  _AddLocationDialogState(this.currentPosition, this.currentAddress);

  LocationCategory selectedLocationCategory;
  List<LocationCategory> users = <LocationCategory>[
    const LocationCategory(
        'Restaurant', Icon(Icons.restaurant, color: Colors.grey)),
    const LocationCategory(
        'Parc',
        Icon(
          Icons.pedal_bike_outlined,
          color: Colors.grey,
        )),
    const LocationCategory(
        'Bar',
        Icon(
          Icons.local_drink,
          color: Colors.grey,
        )),
    const LocationCategory(
        'Other',
        Icon(
          Icons.map_outlined,
          color: Colors.grey,
        )),
  ];

  _addLocation(String name, Image image, LocationCategory category) async {
    // Validate new location
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();

    if (name != null && name != "") {
      var location = <String, Object>{
        'name': name,
        'image': image,
        'category': category == null ? "Other" : category.name,
        'address': currentAddress
      };
      var jsonLocation = jsonEncode(location);

      var locationList = prefs.getStringList('locations') ?? [];
      locationList.add(jsonLocation);
      prefs.setStringList('locations', locationList);
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    locationNameTextFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: dialogContent(context));
  }

  dialogContent(context) {
    return SingleChildScrollView(
        child: Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 40.0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.all(Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          alignment: Alignment.center,
          width: 75,
          height: 75,
          child: Image(
            image: AssetImage('images/camera.png'),
            width: 55,
          ),
        ),
        Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.only(top: 20.0),
          width: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: new Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.black,
            ),
            child: DropdownButton<LocationCategory>(
              dropdownColor: Colors.black,
              hint: Text("Select category",
                  style: TextStyle(color: Colors.white)),
              value: selectedLocationCategory,
              onChanged: (LocationCategory Value) {
                setState(() {
                  selectedLocationCategory = Value;
                });
              },
              items: users.map((LocationCategory selectedLocationCategory) {
                return DropdownMenuItem<LocationCategory>(
                  value: selectedLocationCategory,
                  child: Row(
                    children: <Widget>[
                      selectedLocationCategory.icon,
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        selectedLocationCategory.name,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 20.0, bottom: 50),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.all(Radius.circular(15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          alignment: Alignment.center,
          width: 350,
          height: 75,
          child: TextField(
            controller: locationNameTextFieldController,
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Name...',
                hintStyle: TextStyle(color: Colors.white)),
            style: TextStyle(color: Colors.white),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            InkWell(
                onTap: () => {Navigator.of(context).pop()},
                child: Container(
                  margin: const EdgeInsets.only(top: 0.0, bottom: 60),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  width: 75,
                  height: 50,
                  child: Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 40),
                )),
            InkWell(
                onTap: () {
                  _addLocation(locationNameTextFieldController.text, null,
                      selectedLocationCategory);
                  Navigator.of(context).pop();
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 0.0, bottom: 60),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  width: 75,
                  height: 50,
                  child: Icon(Icons.check, color: Colors.white, size: 40),
                )),
          ],
        )
      ],
    ));
  }
}

class LocationCategory {
  const LocationCategory(this.name, this.icon);

  final String name;
  final Icon icon;
}
