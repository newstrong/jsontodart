import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:json_to_dart/i18n.dart';
import 'package:json_to_dart/models/config.dart';
import 'package:json_to_dart/utils/camel_under_score_converter.dart';
import 'package:json_to_dart/utils/dart_helper.dart';
import 'package:json_to_dart/utils/enums.dart';
import 'package:json_to_dart/utils/my_string_buffer.dart';
import 'package:json_to_dart/utils/string_helper.dart';
import 'package:tuple/tuple.dart';

import 'config.dart';
import 'dart_property.dart';

List<DartObject> printedObjects = <DartObject>[];

// ignore: must_be_immutable
class DartObject extends DartProperty {
  DartObject({
    String? uid,
    MapEntry<String, dynamic>? keyValuePair,
    required int depth,
    DartObject? source,
    required bool nullable,
  }) : super(
          uid: source?.uid ?? uid!,
          keyValuePair: source?.keyValuePair ?? keyValuePair!,
          depth: source?.depth ?? depth,
          nullable: nullable,
        ) {
    if (source != null) {
      properties = source.properties;
      objectKeys = source.objectKeys;
      _jObject = (source.keyValuePair.value as Map<String, dynamic>?)?.map(
          (String key, dynamic value) =>
              MapEntry<String, Tuple3<dynamic, DartType, bool>>(
                  key,
                  Tuple3<dynamic, DartType, bool>(
                      value,
                      converDartType(value.runtimeType),
                      converNullable(value))));
      className = source.className;
    } else {
      properties = <DartProperty>[];
      objectKeys = <String, DartObject>{};
      _jObject = (this.keyValuePair.value as Map<String, dynamic>).map(
          (String key, dynamic value) =>
              MapEntry<String, Tuple3<dynamic, DartType, bool>>(
                  key,
                  Tuple3<dynamic, DartType, bool>(
                      value,
                      converDartType(value.runtimeType),
                      converNullable(value))));

      final String key = this.keyValuePair.key;
      final String className =
          key.substring(0, 1).toUpperCase() + key.substring(1);
      this.className = className;
      initializeProperties();
      updateNameByNamingConventionsType();
    }
  }

  Map<String, Tuple3<dynamic, DartType, bool>>? _jObject;
  Map<String, Tuple3<dynamic, DartType, bool>>? _mergeObject;

  Map<String, Tuple3<dynamic, DartType, bool>>? get jObject =>
      _mergeObject != null ? _mergeObject! : _jObject;

  String _className = '';

  String get className => _className;

  set className(String className) {
    _className = className;
    if (!rebuildName.isClosed) {
      rebuildName.sink.add(className);
    }
  }

  StreamController<String> rebuildName = StreamController<String>.broadcast();

  late List<DartProperty> properties;

  late Map<String, DartObject> objectKeys;

  void close() {
    rebuildName.close();
  }

  void decDepth() {
    depth -= 1;
    for (final DartObject obj in objectKeys.values) {
      obj.decDepth();
    }
  }

  void initializeProperties() {
    properties.clear();
    objectKeys.clear();
    if (jObject != null && jObject!.isNotEmpty) {
      for (final MapEntry<String, Tuple3<dynamic, DartType, bool>> item
          in jObject!.entries) {
        initializePropertyItem(item, depth);
      }
      orderPropeties();
    }
  }

  void initializePropertyItem(
      MapEntry<String, Tuple3<dynamic, DartType, bool>> item, int depth,
      {bool addProperty = true}) {
    if (item.value.item1 is Map &&
        (item.value.item1 as Map<String, dynamic>).isNotEmpty) {
      if (objectKeys.containsKey(item.key)) {
        final DartObject temp = objectKeys[item.key]!;
        temp.merge((item.value.item1 as Map<String, dynamic>).map(
            (String key, dynamic value) =>
                MapEntry<String, Tuple3<dynamic, DartType, bool>>(
                    key,
                    Tuple3<dynamic, DartType, bool>(
                        value,
                        converDartType(value.runtimeType),
                        converNullable(value)))));
        objectKeys[item.key] = temp;
      } else {
        final DartObject temp = DartObject(
            uid: uid + '_' + item.key,
            keyValuePair: MapEntry<String, dynamic>(item.key, item.value.item1),
            nullable: item.value.item3,
            depth: depth + 1);
        if (addProperty) {
          properties.add(temp);
        }
        objectKeys[item.key] = temp;
      }
    } else if (item.value.item1 is List) {
      if (addProperty) {
        properties.add(DartProperty(
            uid: uid,
            keyValuePair: MapEntry<String, dynamic>(item.key, item.value.item1),
            nullable: item.value.item3,
            depth: depth));
      }
      final List<dynamic> array = item.value.item1 as List<dynamic>;
      if (array.isNotEmpty) {
        int count = ConfigSetting().traverseArrayCount;
        if (count == 99) {
          count = array.length;
        }
        final Iterable<dynamic> cutArray = array.take(count);
        for (final dynamic arrayItem in cutArray) {
          initializePropertyItem(
              MapEntry<String, Tuple3<dynamic, DartType, bool>>(
                  item.key,
                  Tuple3<dynamic, DartType, bool>(
                      arrayItem,
                      converDartType(arrayItem.runtimeType),
                      converNullable(value) && ConfigSetting().smartNullable)),
              depth,
              addProperty: false);
        }
      }
    } else {
      if (addProperty) {
        properties.add(DartProperty(
            uid: uid,
            keyValuePair: MapEntry<String, dynamic>(item.key, item.value.item1),
            nullable: item.value.item3,
            depth: depth));
      }
    }
  }

  void merge(Map<String, Tuple3<dynamic, DartType, bool>>? other) {
    bool needInitialize = false;
    if (_jObject != null) {
      _mergeObject ??= <String, Tuple3<dynamic, DartType, bool>>{};

      for (final MapEntry<String, Tuple3<dynamic, DartType, bool>> item
          in _jObject!.entries) {
        if (!_mergeObject!.containsKey(item.key)) {
          needInitialize = true;
          _mergeObject![item.key] = item.value;
        }
      }

      if (other != null) {
        _mergeObject ??= <String, Tuple3<dynamic, DartType, bool>>{};

        if (ConfigSetting().smartNullable) {
          for (final MapEntry<String,
                  Tuple3<dynamic, DartType, bool>> existObject
              in _mergeObject!.entries) {
            if (!other.containsKey(existObject.key)) {
              final Tuple3<dynamic, DartType, bool> newObject =
                  Tuple3<dynamic, DartType, bool>(
                      existObject.value.item1, existObject.value.item2, true);
              _mergeObject![existObject.key] = newObject;
              needInitialize = true;
            }
          }
        }

        for (final MapEntry<String, Tuple3<dynamic, DartType, bool>> item
            in other.entries) {
          if (!_mergeObject!.containsKey(item.key)) {
            needInitialize = true;
            _mergeObject![item.key] = Tuple3<dynamic, DartType, bool>(
                item.value.item1, item.value.item2, true);
          } else {
            Tuple3<dynamic, DartType, bool> existObject =
                _mergeObject![item.key]!;
            if ((existObject.item2.isNull && !item.value.item2.isNull) ||
                (!existObject.item2.isNull && item.value.item2.isNull) ||
                existObject.item3 != item.value.item3) {
              existObject = Tuple3<dynamic, DartType, bool>(
                  item.value.item1 ?? existObject.item1,
                  item.value.item2 != DartType.Null
                      ? item.value.item2
                      : existObject.item2,
                  (existObject.item3 || item.value.item3) &&
                      ConfigSetting().smartNullable);
              _mergeObject![item.key] = existObject;
              needInitialize = true;
            }
          }
        }
        if (needInitialize) {
          initializeProperties();
        }
      }
    }
  }

  @override
  void updateNameByNamingConventionsType() {
    super.updateNameByNamingConventionsType();

    for (final DartProperty item in properties) {
      item.updateNameByNamingConventionsType();
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      item.value.updateNameByNamingConventionsType();
    }
  }

  @override
  void updatePropertyAccessorType() {
    super.updatePropertyAccessorType();

    for (final DartProperty item in properties) {
      item.updatePropertyAccessorType();
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      item.value.updatePropertyAccessorType();
    }
  }

  @override
  void updateNullable(bool nullable) {
    super.updateNullable(nullable);
    for (final DartProperty item in properties) {
      item.updateNullable(nullable);
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      item.value.updateNullable(nullable);
    }
  }

  @override
  String getTypeString({String? className}) {
    return this.className;
  }

  void orderPropeties() {
    final PropertyNameSortingType sortingType =
        ConfigSetting().propertyNameSortingType;
    if (sortingType != PropertyNameSortingType.none) {
      if (sortingType == PropertyNameSortingType.ascending) {
        properties.sort((DartProperty left, DartProperty right) =>
            left.name.compareTo(right.name));
      } else {
        properties.sort((DartProperty left, DartProperty right) =>
            right.name.compareTo(left.name));
      }
    }

    if (jObject != null) {
      for (final MapEntry<String, DartObject> item in objectKeys.entries) {
        item.value.orderPropeties();
      }
    }
  }

  @override
  String toString() {
    if (printedObjects.contains(this)) {
      return '';
    }
    printedObjects.add(this);

    orderPropeties();

    final MyStringBuffer sb = MyStringBuffer();

    sb.writeLine(stringFormat(classHeader, <String>[className]));

    if (properties.isNotEmpty) {
      final MyStringBuffer factorySb = MyStringBuffer(); //构造函数
      final MyStringBuffer factorySb1 = MyStringBuffer();
      final MyStringBuffer propertySb = MyStringBuffer();
      //StringBuffer propertySb1 = StringBuffer();
      final MyStringBuffer fromJsonSb = MyStringBuffer();
      //Array
      final MyStringBuffer fromJsonSb1 = MyStringBuffer();
      final MyStringBuffer toJsonSb = MyStringBuffer(); //toJson 函数

      factorySb
          .writeLine(stringFormat(factoryStringHeader, <String>[className]));

      toJsonSb.writeLine(toJsonHeader);

      for (final DartProperty item in properties) {
        final String lowName =
            item.name.substring(0, 1).toLowerCase() + item.name.substring(1);
        final String name = item.name;
        String? className;
        String? typeString;
        final String setName = getSetPropertyString(item);
        String setString = '';
        final String fss = factorySetString(
          item.propertyAccessorType,
          (!ConfigSetting().nullsafety) ||
              (ConfigSetting().nullsafety && item.nullable),
        );
        final bool isGetSet = fss.startsWith('{');
        if (item is DartObject) {
          className = item.className;

          setString = stringFormat(setObjectProperty, <String>[
            item.name,
            item.key,
            className,
            if (ConfigSetting().nullsafety && item.nullable)
              'jsonRes[\'${item.key}\']==null?null:'
            else
              '',
            if (ConfigSetting().nullsafety) '!' else ''
          ]);
          typeString = className;
          if (ConfigSetting().nullsafety && item.nullable) {
            typeString += '?';
          }
        } else if (item.value is List) {
          if (objectKeys.containsKey(item.key)) {
            className = objectKeys[item.key]!.className;
          }
          typeString = item.getTypeString(className: className);
          typeString = typeString.replaceAll('?', '');

          fromJsonSb1.writeLine(item.getArraySetPropertyString(
            lowName,
            typeString,
            className: className,
            baseType: item
                .getBaseTypeString(className: className)
                .replaceAll('?', ''),
          ));

          // setString = ' ${item.name}:$lowName';
          setString =
              " ${item.name}:map.l('${item.key}').map((map)=>$className.fromMap(map)).toList()";

          /* if (ConfigSetting().nullsafety) {
            if (item.nullable) {
              typeString += '?';
            } else {
              setString += '!';
            }
          }*/
          setString += ',';
        } else {
          setString = setProperty(item.name, item, this.className);
          typeString = getDartTypeString(item.type, item);
        }

        if (isGetSet) {
          factorySb.writeLine(stringFormat(fss, <String>[typeString, lowName]));
          if (factorySb1.length == 0) {
            factorySb1.write('}):');
          } else {
            factorySb1.write(',');
          }
          factorySb1.write('$setName=$lowName');
        } else {
          factorySb.writeLine(stringFormat(fss, <String>[item.name]));
        }

        propertySb.writeLine(stringFormat(propertyS(item.propertyAccessorType),
            <String>[typeString, name, lowName]));
        fromJsonSb.writeLine(setString);

        // String setNameTemp = setName;

        // if (className != null) {
        //   String toJson = '=> e.toJson()';
        //   dynamic value = item.value;
        //   String typeString = className;
        //   while (value is List) {
        //     toJson = '=> e.map(($typeString e) $toJson)';
        //     typeString = 'List<$typeString>';
        //     if (value.isNotEmpty) {
        //       value = value.first;
        //     } else {
        //       break;
        //     }
        //   }
        //   toJson = toJson.replaceFirst('=>', '');
        //   toJson = toJson.replaceFirst('e', '');
        //   toJson = toJson.trim();

        //   final bool nonNullAble = ConfigSetting().nullsafety && !item.nullable;
        //   setNameTemp += '${nonNullAble ? '' : '?'}$toJson';
        // }

        toJsonSb.writeLine(stringFormat(toJsonSetString, <String>[
          item.key,
          setName,
        ]));
      }

      if (factorySb1.length == 0) {
        factorySb.writeLine(factoryStringFooter);
      } else {
        factorySb1.write(';');
        factorySb.write(factorySb1.toString());
      }

      String fromJson = '';
      if (fromJsonSb1.length != 0) {
        fromJson = stringFormat(
                ConfigSetting().nullsafety
                    ? fromJsonHeader1NullSafety
                    : fromJsonHeader1,
                <String>[className]) +
            // fromJsonSb1.toString() +
            stringFormat(
                fromJsonFooter1, <String>[className, fromJsonSb.toString()]);
      } else {
        fromJson = stringFormat(
                ConfigSetting().nullsafety
                    ? fromJsonHeaderNullSafety
                    : fromJsonHeader,
                <String>[className]) +
            fromJsonSb.toString() +
            fromJsonFooter;
      }

      //fromJsonSb.AppendLine(FromJsonFooter);

      toJsonSb.writeLine(toJsonFooter);

      sb.writeLine(propertySb.toString()); //参数
      sb.writeLine(factorySb.toString()); //构造函数
      sb.writeLine(fromJson); //from 函数
      // sb.writeLine(classToString); //toString
      sb.writeLine('\n@override');
      sb.writeLine(toJsonSb.toString()); //toJson
      /*sb.writeLine(stringFormat(classToClone,
          <String>[className, if (ConfigSetting().nullsafety) '!' else '']));//克隆*/
    }

    sb.writeLine(classFooter);

    /// 添加 mock
    sb.writeLine('class ${className}Mock {');
    sb.writeLine('static $className mock([int? index]) => $className(');

    for (final DartProperty item in properties) {
      dynamic mockValue;
      switch (item.type) {
        case DartType.int:
        case DartType.double:
        case DartType.bool:
          mockValue = item.value;
          break;
        case DartType.String:
          mockValue = "\'${item.value}\'";
          break;
        case DartType.Null:
          mockValue = r"''";
          break;
        case DartType.Object:
          if (item.value is Map) {
            if (item is DartObject) {
              mockValue = '${item.className}Mock.mock()';
            } else {
              mockValue = <String, dynamic>{};
            }
          } else if (item.value is List) {
            final String theClassName = upcaseCamelName(item.name);
            mockValue = '${theClassName}Mock.mockList';
          } else {
            mockValue = r"''";
          }
          break;
        default:
          mockValue = r"''";
      }
      sb.writeLine('${item.name}:$mockValue,');
    }
    sb.writeLine(' );\n');
    sb.writeLine(
        'static List<$className> get mockList => List.generate(3, mock);');
    sb.writeLine(classFooter);

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      sb.writeLine(item.value.toString());
    }

    return sb.toString();
  }

  String? hasEmptyProperties() {
    final AppLocalizations appLocalizations = I18n.instance;
    if (isNullOrWhiteSpace(className)) {
      return appLocalizations.classNameAssert(uid);
    }

    for (final DartProperty item in properties) {
      if (item is DartObject) {
        if (depth > 0 &&
            !item.uid.endsWith('_Array') &&
            isNullOrWhiteSpace(item.name)) {
          return appLocalizations.propertyNameAssert(item.uid);
        }
      } else if (isNullOrWhiteSpace(item.name)) {
        return appLocalizations.propertyNameAssert(item.uid);
      }
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      final String? msg = item.value.hasEmptyProperties();
      if (msg != null) {
        return msg;
      }
    }
    return null;
  }

  DartObject copy() {
    return DartObject(source: this, depth: depth, nullable: nullable);
  }

  @override
  List<Object?> get props => <Object?>[
        className,
        properties,
      ];
}
