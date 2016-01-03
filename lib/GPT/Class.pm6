module GPT::Class {
role Type is export {
  has	$.id is rw;
}

class DirectType does Type is export {
  has	$.name is rw;
  method Str {
    $!name;
  }
}

class IndirectType does Type is export {
  has	$.ref-id is rw;
  has	Type $.ref-type is rw;
}

class PointerType is IndirectType is export {
  method Str {
    return $.ref-type.Str ~ '*';
  }
}

class StructType is DirectType is export {
}

class FundamentalType is DirectType is export {
}

class ArrayType is IndirectType is export {
  method Str {
    return '[]' ~ $.ref-type.Str;
  }
}

class QualifiedType is IndirectType is export {
  method Str {
    return 'const ' ~ $.ref-type.Str;
  }
}

class TypeDefType is IndirectType is export {
  has $.name is rw;
  method Str {
    return "Typedef($!name)->" ~  $.ref-type.Str;
  }
}

class UnionType is DirectType is export {
  method Str {
    'Union'
  }
}

class FunctionType is DirectType is export {
  method Str {
    'PtrFunc';
  }
}

class EnumType is DirectType is export {
}

class Field is rw  is export {
  has	$.name;
  has	$.type-id;
  has	Type $.type;
}

class Struct is rw is export {
  has	$.name;
  has	$.id;
  has	Field @.fields;
}

class EnumValue is rw is export {
  has	$.name;
  has	$.init,
}

class CEnum is rw is export {
  has	$.name;
  has	$.id;
  has	EnumValue @.values;
}

class FunctionArgument is rw is export {
  has		$.name;
  has Type 	$.type;
}

class Function is rw is export {
  has	$.id;
  has	$.name;
  has	Type $.returns;
  has	FunctionArgument @.arguments;
}

class CUnion is rw is export {
  has	$.id;
  has   $.field;
  has   $.struct;
  has   @.members;
  has   $.gen-name;
}
  
}