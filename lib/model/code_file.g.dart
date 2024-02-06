// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_CodeFile _$$_CodeFileFromJson(Map<String, dynamic> json) => _$_CodeFile(
      path: json['path'] as String,
      digest: json['digest'] as String,
      generatedOutput: (json['generatedOutput'] as List<dynamic>)
          .map((e) => GeneratedFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      isTestFile: json['isTestFile'] as bool? ?? false,
    );

Map<String, dynamic> _$$_CodeFileToJson(_$_CodeFile instance) =>
    <String, dynamic>{
      'path': instance.path,
      'digest': instance.digest,
      'generatedOutput': instance.generatedOutput,
      'isTestFile': instance.isTestFile,
    };
