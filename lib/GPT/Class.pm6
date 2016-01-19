module GPT::Class {

#Type class. they only represent a Type
role Type is export {
  has	$.id is rw;
}

class DirectType does Type is export {
  has	Str $.name is rw = "";
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
  has	$.size = '';
  method Str {
    return $.ref-type.Str ~ "[$!size]";
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
    return "Typedef($!name)->|" ~  $.ref-type.Str ~ "|";
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

class ReferenceType is IndirectType is export {
  method Str {
    return $.ref-type.Str ~ '&';
  }
}

class EnumType is DirectType is export {
}


# Real class

# to keep track of the location
role CLocation is rw is export {
  has	$.file-id;
  has	$.file;
  has	$.start-line;
  
  method set-clocation($elem) {
    $!file-id = $elem.attribs<file>;
    $!start-line = $elem.attribs<line>;
  }
}

class Field does CLocation is rw is export {
  has	$.name;
  has	$.type-id;
  has	Type $.type;
}

class Struct does CLocation is rw is export {
  has	$.name;
  has	$.id;
  has	Field @.fields;
}

class EnumValue is rw is export {
  has	$.name;
  has	$.init,
}

class CEnum does CLocation is rw is export {
  has	$.name;
  has	$.id;
  has	EnumValue @.values;
}

class FunctionArgument does CLocation is rw is export {
  has		$.name;
  has Type 	$.type;
  has		$.type-id;
}

class Function does CLocation is rw is export {
  has	$.id;
  has	$.name;
  has	Type $.returns;
  has	$.returns-id;
  has	FunctionArgument @.arguments;
}

class CUnion does CLocation is rw is export {
  has	$.id;
  has   @.members;
  has	$.name;
}

class AnonymousUnion is CUnion is rw is export {
  has   $.gen-name;
  has   $.field;
  has   $.struct;
}

class ExternVariable does CLocation is rw is export {
  has	$.id;
  has	$.name;
  has	$.type-id;
  has	$.type;
}

class AllTheThings is rw is export {
  has	@.functions;
  has	%.types;
  has	@.enums;
  has	%.structs;
  has	%.files;
  has	%.unions;
  has	@.variables;
}

}