enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  int toInt() {
    return index;
  }

  static MessageStatus fromInt(int value) {
    if (value >= 0 && value < MessageStatus.values.length) {
      return MessageStatus.values[value];
    }
    return MessageStatus.sending;
  }

  String toJson() => index.toString();

  static MessageStatus fromJson(dynamic json) {
    if (json is int) {
      return fromInt(json);
    } else if (json is String) {
      final intValue = int.tryParse(json);
      if (intValue != null) {
        return fromInt(intValue);
      }
      // Try to parse as string name
      try {
        return MessageStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == json.toLowerCase(),
          orElse: () => MessageStatus.sending,
        );
      } catch (_) {
        return MessageStatus.sending;
      }
    }
    return MessageStatus.sending;
  }
}

