enum ConversationType {
  private,
  group;

  int toInt() {
    return index;
  }

  static ConversationType fromInt(int value) {
    if (value >= 0 && value < ConversationType.values.length) {
      return ConversationType.values[value];
    }
    return ConversationType.private;
  }

  String toJson() => index.toString();

  static ConversationType fromJson(dynamic json) {
    if (json is int) {
      return fromInt(json);
    } else if (json is String) {
      final intValue = int.tryParse(json);
      if (intValue != null) {
        return fromInt(intValue);
      }
      // Try to parse as string name
      try {
        return ConversationType.values.firstWhere(
          (e) => e.name.toLowerCase() == json.toLowerCase(),
          orElse: () => ConversationType.private,
        );
      } catch (_) {
        return ConversationType.private;
      }
    }
    return ConversationType.private;
  }
}

