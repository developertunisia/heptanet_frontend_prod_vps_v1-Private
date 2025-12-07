// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_response_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserResponseDtoAdapter extends TypeAdapter<UserResponseDto> {
  @override
  final int typeId = 0;

  @override
  UserResponseDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserResponseDto(
      id: fields[0] as int,
      firstName: fields[1] as String,
      lastName: fields[2] as String,
      email: fields[3] as String,
      whatsAppNumber: fields[4] as String,
      roleId: fields[5] as int?,
      roles: (fields[6] as List).cast<String>(),
      createdAt: fields[7] as DateTime,
      lastLogin: fields[8] as DateTime?,
      isBlacklisted: fields[9] as bool,
      cachedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserResponseDto obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.firstName)
      ..writeByte(2)
      ..write(obj.lastName)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.whatsAppNumber)
      ..writeByte(5)
      ..write(obj.roleId)
      ..writeByte(6)
      ..write(obj.roles)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.lastLogin)
      ..writeByte(9)
      ..write(obj.isBlacklisted)
      ..writeByte(10)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserResponseDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
