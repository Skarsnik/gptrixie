

module GPT::Class {

role CLocation is rw is export {
  has	$.file-id;
  has	$.file;
  has	$.start-line;
  
  method set-clocation($elem) {
    $!file-id = $elem.attribs<file>;
    $!start-line = $elem.attribs<line>;
  }
}

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

class StructType is DirectType does CLocation is export {
}

class ClassType is DirectType is export {
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

class TypeDefType is IndirectType does CLocation is export {
  has $.name is rw;
  method Str {
    return "Typedef<$!name>->«" ~  $.ref-type.Str ~ "»";
  }
}

class UnionType is DirectType does CLocation is export {
  method Str {
    'Union'
  }
}

class FunctionType is DirectType is export is rw {
  has	Type @.arguments-type;
  has	@.arguments-type-id;
  has	Type $.return-type;
  has	$.return-type-id;
  method Str {
    'F:' ~ $.return-type.Str ~ ' ( ' ~ (@.arguments-type.map:{.Str}).join(', ') ~ ')';
  }
}

class ReferenceType is IndirectType is export {
  method Str {
    return $.ref-type.Str ~ '&';
  }
}

class EnumType is DirectType is export {
}

multi sub infix:<type-eq>(Type:D $t, Str:D $s) returns Bool is export {
  $t type-eq $s.list;
}

multi sub infix:<type-eq>(Type:D $t, List:D $l) returns Bool is export {
  my $type = $t;
  #say "Testing : " ~$t.Str ~ " with :" ~ $l;
  for @($l) -> $s {
    #say $t.Str;
    given $s {
      when 'ptr' | 'Ptr' {
        return False if $type !~~ PointerType;
      }
      when 'Ref' | 'ref' {
        return False if $type !~~ ReferenceType;
      }
      when 'fund' | 'Fund' {
        return False if $type !~~ FundamentalType;
      }
      when 'typedef' | /^'typedef['(.+)']'/ {
        return False if $type !~~ TypeDefType;
        return False if $0 and $0 ne $type.name;
      }
      when 'struct' | /^"struct["(.+)']'/ {
        return False if $type !~~ StructType;
        return False if $0 and $0 ne $type.name;
      }
      when 'Union' | 'union' {
        return False if $type !~~ UnionType;
      }
      when 'const' | 'qualif' {
        return False if $type !~~ QualifiedType;
      }
      when 'enum' | 'Enum' {
        return False if $type !~~ EnumType;
      }
      when 'FunPtr' | 'funptr' {
        return False if $type !~~ FunctionType;
      }
      default {
        return False if $type !~~ FundamentalType;
        return False if $type.name ne $s;
        return True if $type.name eq $s;
      }
    }
    $type = $type.ref-type if $type ~~ IndirectType;
  }
  return True;
}


# Real class

# to keep track of the location


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
