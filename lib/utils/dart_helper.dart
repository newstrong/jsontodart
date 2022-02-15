import 'package:json_to_dart/models/dart_property.dart';

import '../models/config.dart';
import '../models/dart_property.dart';
import 'enums.dart';

const String classHeader = 'class {0} extends BaseBean{';
const String classFooter = '}';

const String fromJsonHeader =
    '  factory {0}.fromJson(Map<String, dynamic> jsonRes)=>jsonRes == null? null:{0}(';
const String fromJsonHeader1 =
    '  factory {0}.fromJson(Map<String, dynamic> jsonRes){ if(jsonRes == null) {return null;}\n';
const String fromJsonHeaderNullSafety = '  factory {0}.fromMap(Map map)=>{0}(';
const String fromJsonHeader1NullSafety = '  factory {0}.fromMap(Map map){\n';
const String fromJsonFooter = ');';
const String fromJsonFooter1 = 'return {0}({1});}';
const String toJsonHeader = '  Map toJson() => {';
const String toJsonFooter = '};';

const String copyWithHeader =
    '  Map<String, dynamic> toJson() => <String, dynamic>{';
const String copyWithFooter = '};';

const String toJsonSetString = "        '{0}': {1},";
const String jsonImport = '''
import 'dart:convert';''';
const String propertyString = '  {0} {1};';
const String propertyStringFinal = '  final {0} {1};';
const String propertyStringGet = '  {0} _{2};\n  {0} get {1} => _{2};';
const String propertyStringGetSet =
    '  {0} _{2};\n  {0} get {1} => _{2};\n  set {1}(value)  {\n    _{2} = value;\n  }\n';

String setProperty(String setName, DartProperty item, String? className) {
  String method;
  switch (item.type) {
    case DartType.int:
      method = 'i';
      break;
    case DartType.double:
      method = 'd';
      break;
    case DartType.bool:
      method = 'b';
      break;
    default:
      method = 's';
  }
  return "    $setName : map.$method('${item.key}'),";
  // return '    $setName : ${getUseAsT(getDartTypeString(item.type, item), "jsonRes['${item.key}']")},';
  // if (appConfig.enableDataProtection) {
  //   return "    $setName : convertValueByType(jsonRes['${item.key}'],${item.value.runtimeType.toString()},stack:\"$className-${item.key}\"),";
  // } else {
  //   return "    $setName : jsonRes['${item.key}'],";
  // }
}

const String setObjectProperty = "    {0} :{3} {2}.fromMap(map.m('{1}')),";

String propertyS(PropertyAccessorType type) {
  switch (type) {
    case PropertyAccessorType.none:
      return propertyString;
    case PropertyAccessorType.final_:
      return propertyStringFinal;
    // case PropertyAccessorType.get_:
    //   return propertyStringGet;
    // case PropertyAccessorType.getSet:
    //   return propertyStringGetSet;
  }
}

String getSetPropertyString(DartProperty property) {
  final String name = property.name;
  switch (property.propertyAccessorType) {
    case PropertyAccessorType.none:
    case PropertyAccessorType.final_:
      return name;
    // case PropertyAccessorType.get_:
    // case PropertyAccessorType.getSet:s
    //   final String lowName =
    //       name.substring(0, 1).toLowerCase() + name.substring(1);
    //   return '_' + lowName;
  }
}

String getDartTypeString(DartType dartType, DartProperty item) {
  final bool nullable = ConfigSetting().nullsafety && item.nullable;
  final String type = dartType.text;
  return nullable ? type + '?' : type;
}

const String factoryStringHeader = '    {0}({';
const String factoryStringFooter = '    });\n';

String factorySetString(
  PropertyAccessorType type,
  bool nullable,
) {
  switch (type) {
    case PropertyAccessorType.none:
    case PropertyAccessorType.final_:
      return nullable ? 'this.{0},' : 'required this.{0},';
    // case PropertyAccessorType.get_:
    // case PropertyAccessorType.getSet:
    //   return '{0} {1},';
  }
}

const String classToString =
    '  \n@override\nString  toString() {\n    return jsonEncode(this);\n  }';

const String classToClone =
    '\n{0} clone() => {0}.fromJson(asT<Map<String, dynamic>>(jsonDecode(jsonEncode(this))){1});\n';

DartType converDartType(Type type) {
  if (type == int) {
    return DartType.int;
  } else if (type == double || type == num) {
    return DartType.double;
  } else if (type == String) {
    return DartType.String;
  } else if (type == bool) {
    return DartType.bool;
  } else if (type == Null) {
    return DartType.Null;
  }

  return DartType.Object;
}

bool converNullable(dynamic value) {
  return value.runtimeType == Null;
}

const String tryCatchMethod = """void tryCatch(Function f)
      { try {f?.call();}
      catch (e, stack)
       {
        log('\$e'); \n  log('\$stack');
        }
        }""";
const String tryCatchMethodNullSafety = """void tryCatch(Function? f)
      { try {f?.call();}
      catch (e, stack)
       {
        log('\$e'); \n  log('\$stack');
        }
        }""";
const String asTMethod = '''
T asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}
 ''';

const String asTMethodNullSafety = '''
T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}
 ''';
const String asTMethodWithDataProtection = '''
class FFConvert {
  FFConvert._();

   T Function<T>(dynamic value) convert = <T>(dynamic value) {
    if (value == null) {
      return null;
    }
    return json.decode(value.toString()) as T;
  };
}

T asT<T>(dynamic value, [T defaultValue]) {
  if (value is T) {
    return value;
  }
  try {
    if (value != null) {
      final String valueS = value.toString();
      if ('' is T) {
        return valueS as T;
      } else if (0 is T) {
        return int.parse(valueS) as T;
      } else if (0.0 is T) {
        return double.parse(valueS) as T;
      } else if (false is T) {
        if (valueS == '0' || valueS == '1') {
          return (valueS == '1') as T;
        }
        return (valueS == 'true') as T;
      } else {
        return FFConvert.convert<T>(value);
      }
    }
  } catch (e, stackTrace) {
    log('asT<\$T>', error: e, stackTrace: stackTrace);
    return defaultValue;
  }

  return defaultValue;
}

 ''';

const String asTMethodWithDataProtectionNullSafety = '''
class FFConvert {
  FFConvert._();
   T? Function<T extends Object?>(dynamic value) convert =
      <T>(dynamic value) {
    if (value == null) {
      return null;
    }
    return json.decode(value.toString()) as T?;
  };
}

T? asT<T extends Object?>(dynamic value, [T? defaultValue]) {
  if (value is T) {
    return value;
  }
  try {
    if (value != null) {
      final String valueS = value.toString();
      if ('' is T) {
        return valueS as T;
      } else if (0 is T) {
        return int.parse(valueS) as T;
      } else if (0.0 is T) {
        return double.parse(valueS) as T;
      } else if (false is T) {
        if (valueS == '0' || valueS == '1') {
          return (valueS == '1') as T;
        }
        return (valueS == 'true') as T;
      } else {
        return FFConvert.convert<T>(value);
      }
    }
  } catch (e, stackTrace) {
    log('asT<\$T>', error: e, stackTrace: stackTrace);
    return defaultValue;
  }

  return defaultValue;
}
 ''';

String getUseAsT(String? par1, String par2) {
  String asTString = 'asT<$par1>($par2)';
  if (ConfigSetting().nullsafety && par1 != null && !par1.contains('?')) {
    asTString += '!';
  }
  return asTString;
}
