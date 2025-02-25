// To parse this JSON data, do
//
//     final locationmoadel = locationmoadelFromJson(jsonString);

import 'dart:convert';

Locationmoadel locationmoadelFromJson(String str) => Locationmoadel.fromJson(json.decode(str));

String locationmoadelToJson(Locationmoadel data) => json.encode(data.toJson());

class Locationmoadel {
    List<Result>? results;
    String? status;

    Locationmoadel({
        this.results,
        this.status,
    });

    factory Locationmoadel.fromJson(Map<String, dynamic> json) => Locationmoadel(
        results: json["results"] == null ? [] : List<Result>.from(json["results"]!.map((x) => Result.fromJson(x))),
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "results": results == null ? [] : List<dynamic>.from(results!.map((x) => x.toJson())),
        "status": status,
    };
}

class Result {
    List<AddressComponent>? addressComponents;
    String? formattedAddress;
    Geometry? geometry;
    String? placeId;
    List<String>? types;

    Result({
        this.addressComponents,
        this.formattedAddress,
        this.geometry,
        this.placeId,
        this.types,
    });

    factory Result.fromJson(Map<String, dynamic> json) => Result(
        addressComponents: json["address_components"] == null ? [] : List<AddressComponent>.from(json["address_components"]!.map((x) => AddressComponent.fromJson(x))),
        formattedAddress: json["formatted_address"],
        geometry: json["geometry"] == null ? null : Geometry.fromJson(json["geometry"]),
        placeId: json["place_id"],
        types: json["types"] == null ? [] : List<String>.from(json["types"]!.map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "address_components": addressComponents == null ? [] : List<dynamic>.from(addressComponents!.map((x) => x.toJson())),
        "formatted_address": formattedAddress,
        "geometry": geometry?.toJson(),
        "place_id": placeId,
        "types": types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
    };
}

class AddressComponent {
    String? longName;
    String? shortName;
    List<String>? types;

    AddressComponent({
        this.longName,
        this.shortName,
        this.types,
    });

    factory AddressComponent.fromJson(Map<String, dynamic> json) => AddressComponent(
        longName: json["long_name"],
        shortName: json["short_name"],
        types: json["types"] == null ? [] : List<String>.from(json["types"]!.map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "long_name": longName,
        "short_name": shortName,
        "types": types == null ? [] : List<dynamic>.from(types!.map((x) => x)),
    };
}

class Geometry {
    Bounds? bounds;
    Location? location;
    String? locationType;
    Bounds? viewport;

    Geometry({
        this.bounds,
        this.location,
        this.locationType,
        this.viewport,
    });

    factory Geometry.fromJson(Map<String, dynamic> json) => Geometry(
        bounds: json["bounds"] == null ? null : Bounds.fromJson(json["bounds"]),
        location: json["location"] == null ? null : Location.fromJson(json["location"]),
        locationType: json["location_type"],
        viewport: json["viewport"] == null ? null : Bounds.fromJson(json["viewport"]),
    );

    Map<String, dynamic> toJson() => {
        "bounds": bounds?.toJson(),
        "location": location?.toJson(),
        "location_type": locationType,
        "viewport": viewport?.toJson(),
    };
}

class Bounds {
    Location? northeast;
    Location? southwest;

    Bounds({
        this.northeast,
        this.southwest,
    });

    factory Bounds.fromJson(Map<String, dynamic> json) => Bounds(
        northeast: json["northeast"] == null ? null : Location.fromJson(json["northeast"]),
        southwest: json["southwest"] == null ? null : Location.fromJson(json["southwest"]),
    );

    Map<String, dynamic> toJson() => {
        "northeast": northeast?.toJson(),
        "southwest": southwest?.toJson(),
    };
}

class Location {
    double? lat;
    double? lng;

    Location({
        this.lat,
        this.lng,
    });

    factory Location.fromJson(Map<String, dynamic> json) => Location(
        lat: json["lat"]?.toDouble(),
        lng: json["lng"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "lat": lat,
        "lng": lng,
    };
}
