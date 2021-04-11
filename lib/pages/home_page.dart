import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int temperature = 0;
  String cityName = "City";
  int woeid = 0;

  String weather = "";
  String abbr = "";
  String errorMessage = "";
  String myCurrentPosition = "";

  Position currentPosition;
  LocationPermission permission = LocationPermission.always;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPermissionPosition();
    getCurrentLocation();
  }

  //Permiso para acceder a la ubicacion
  void getPermissionPosition () {
    Geolocator.requestPermission();
    print("Permiso a ubicación obtenido");
  }

  //obtener ubicacion actual
  getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best, forceAndroidLocationManager: true).then((Position position) {
      setState(() {
        currentPosition = position;
        myCurrentPosition = currentPosition.latitude.toStringAsFixed(6) + ","+ currentPosition.longitude.toStringAsFixed(6);
      });
    }).catchError((e) {
      print(e);
    });
    print("Ubicacion actual obtenida");
    searchCurrentLocation();
  }

  //Obtener Json de la ubicacion actual
  void searchCurrentLocation() async {
    var url = Uri.parse("https://www.metaweather.com/api/location/search/?lattlong=$myCurrentPosition");
    var result = await http.get(url);
    var decodeJson = json.decode(result.body)[0];
    print(decodeJson);
    setState(() {
      cityName = decodeJson["title"];
      woeid = decodeJson["woeid"];
      errorMessage = "";
      getLocation();
    });
    print("Clima de la ubicacion actual obtenido");
  }

  //Obtener Json por busqueda
  void getSearch(String name) async {
    try {
      var url = Uri.parse("https://www.metaweather.com/api/location/search/?query=$name");
      var result = await http.get(url);
      var decodeJson = json.decode(result.body)[0];
      print(decodeJson);
      setState(() {
        cityName = decodeJson["title"];
        woeid = decodeJson["woeid"];
        errorMessage = "";
        getLocation();
      });
    } catch (error) {
      errorMessage = "No se encontró la ciudad, intenta nuevamente.";
      setState(() {

      });
    }
    print("Conversion de Json Busqueda");
  }

  //Obtener informacion del clima
  void getLocation() async {
    var url = Uri.parse("https://www.metaweather.com/api/location/$woeid");
    var result = await http.get(url);
    var decodeJson = json.decode(result.body);
    var consolidateWeather = decodeJson["consolidated_weather"];
    var data = consolidateWeather[0];

    temperature = data["the_temp"].round();
    weather = data["weather_state_name"].replaceAll(" ", "").toLowerCase();
    abbr = data["weather_state_abbr"];
    setState(() {});
    print("Informacion del clima Completa");
  }

  void onTextFieldSubmitted(String value) {
    getSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/images/$weather.png"),
            fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                      child: IconButton(
                        focusColor: Colors.red,
                        icon: Icon(Icons.place,
                          size: 50,
                          color: Colors.blueGrey[700],
                        ),
                        onPressed: () {
                          searchCurrentLocation();
                          getCurrentLocation();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 100,),
                Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(125),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.network(
                          "https://www.metaweather.com/static/img/weather/png/$abbr.png",
                          height: 80.0,
                        ),
                      ),
                      Center(
                        child: Text(temperature.toString() + "°C",
                          style: TextStyle(
                            fontSize: 60.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ),
                      Center(
                        child: Text(cityName ?? "",
                          style: TextStyle(
                              fontSize: 40.0,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 80,),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: TextField(
                        onSubmitted: (String value) {
                          onTextFieldSubmitted(value);
                        },
                        style: TextStyle(color: Colors.white, fontSize: 25.0),
                        decoration: InputDecoration(
                          hintText: "Buscar otra ciudad...",
                          hintStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black87)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}