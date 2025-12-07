// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_message_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoiceMessageCacheAdapter extends TypeAdapter<VoiceMessageCache> {
  @override
  final int typeId = 2;

  @override
  VoiceMessageCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoiceMessageCache(
      messageId: fields[0] as int,
      localFilePath: fields[1] as String,
      serverUrl: fields[2] as String?,
      cachedAt: fields[3] as DateTime,
      durationSeconds: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, VoiceMessageCache obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.localFilePath)
      ..writeByte(2)
      ..write(obj.serverUrl)
      ..writeByte(3)
      ..write(obj.cachedAt)
      ..writeByte(4)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceMessageCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
