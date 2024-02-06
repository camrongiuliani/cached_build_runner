// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_GeneratedFile _$$_GeneratedFileFromJson(Map<String, dynamic> json) =>
    _$_GeneratedFile(
      ownerPath: json['ownerPath'] as String,
      genOutputPath: json['genOutputPath'] as String,
      cachedFilePath: json['cachedFilePath'] as String,
      ownerDigest: json['ownerDigest'] as String,
      suffix: json['suffix'] as String?,
      generatedType:
          $enumDecode(_$CodeFileGeneratedTypeEnumMap, json['generatedType']),
    );

Map<String, dynamic> _$$_GeneratedFileToJson(_$_GeneratedFile instance) =>
    <String, dynamic>{
      'ownerPath': instance.ownerPath,
      'genOutputPath': instance.genOutputPath,
      'cachedFilePath': instance.cachedFilePath,
      'ownerDigest': instance.ownerDigest,
      'suffix': instance.suffix,
      'generatedType': _$CodeFileGeneratedTypeEnumMap[instance.generatedType]!,
    };

const _$CodeFileGeneratedTypeEnumMap = {
  CodeFileGeneratedType.import: 'import',
  CodeFileGeneratedType.partFile: 'partFile',
};
