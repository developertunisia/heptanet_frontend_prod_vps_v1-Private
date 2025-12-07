enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  contact,
  sticker,
  system;

  int toInt() {
    return index;
  }

  static MessageType fromInt(int value) {
    if (value >= 0 && value < MessageType.values.length) {
      return MessageType.values[value];
    }
    return MessageType.text;
  }

  String toJson() => index.toString();

  static MessageType fromJson(dynamic json) {
    if (json is int) {
      return fromInt(json);
    } else if (json is String) {
      final intValue = int.tryParse(json);
      if (intValue != null) {
        return fromInt(intValue);
      }
      // Try to parse as string name
      try {
        return MessageType.values.firstWhere(
          (e) => e.name.toLowerCase() == json.toLowerCase(),
          orElse: () => MessageType.text,
        );
      } catch (_) {
        return MessageType.text;
      }
    }
    return MessageType.text;
  }
}

