// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authorized_email_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuthorizedEmailDtoAdapter extends TypeAdapter<AuthorizedEmailDto> {
  @override
  final int typeId = 1;

  @override
  AuthorizedEmailDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthorizedEmailDto(
      syncId: fields[0] as int,
      email: fields[1] as String,
      isImported: fields[2] as bool,
      syncDate: fields[3] as DateTime?,
      cachedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AuthorizedEmailDto obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.syncId)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.isImported)
      ..writeByte(3)
      ..write(obj.syncDate)
      ..writeByte(4)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorizedEmailDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
