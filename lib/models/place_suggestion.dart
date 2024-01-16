
class Suggestion {
  String placeName;
  String placeId;

  Suggestion({required this.placeName, required this.placeId});

  factory Suggestion.fromJson(Map<String, dynamic> data) {
    return Suggestion(
      placeName: data['description'] as String,
      placeId: data['place_id'] as String,
    );
  }
}

