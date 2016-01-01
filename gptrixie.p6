use XML;


my %types;
my %fields;
my %struct;
my @cfunctions;
my @cenums;

sub MAIN($header-file, Bool :$all, Bool :$enums, Bool :$functions, Bool :$structs) {
  do-magic($header-file);
  
  if $enums {
    generate-enums(@cenums);
  }
  if $functions {
    generate-functions();
  }
  if $structs {
    generate-structs();
  }
}

my %ctype-to-p6 = (
  'char' => 'int8',
  'bool' => 'bool',
  '_bool' => 'bool',
  'int' => 'int32',
  'float' => 'num32',
  'double' => 'num64',
  'long' => 'long',
  'unsigned int' => 'uint32'
).hash;

role Type {
  has	$.id is rw;
}

class DirectType does Type {
  has	$.name is rw;
  method Str {
    $!name;
  }
}

class IndirectType does Type {
  has	$.ref-id is rw;
  has	Type $.ref-type is rw;
}

class PointerType is IndirectType {
  method Str {
    return $.ref-type.Str ~ '*';
  }
}

class StructType is DirectType {
}

class FundamentalType is DirectType {
}

class QualifiedType is IndirectType {
  method Str {
    return 'const ' ~ $.ref-type.Str;
  }
}

class TypeDefType is IndirectType {
  has $.name is rw;
  method Str {
    return "Typedef($!name)->" ~  $.ref-type.Str;
  }
}

class UnionType is DirectType {
  method Str {
    'Union'
  }
}

class FunctionType is DirectType {
  method Str {
    'PtrFunc';
  }
}

class EnumType is DirectType {
}


sub	resolve-type($t) {
  if $t ~~ PointerType {
    return 'Str' if $t.ref-type ~~ FundamentalType && $t.ref-type.name eq 'char' ||
      $t.ref-type ~~ QualifiedType && $t.ref-type.ref-type.name eq 'char';
    return 'Pointer' if $t.ref-type ~~ FundamentalType && $t.ref-type.name eq 'void' ||
      $t.ref-type ~~ QualifiedType && $t.ref-type.ref-type.name eq 'void';
    return 'Pointer[' ~ resolve-type($t.ref-type) ~ ']';
  }
  if $t ~~ FundamentalType {
    return %ctype-to-p6{$t.name};
  }
  if $t ~~ EnumType {
    return 'int32';
  }
  if $t ~~ StructType {
    return $t.name;
  }
  if $t ~~ QualifiedType {
    return resolve-type($t.ref-type);
  }
  if $t ~~ TypeDefType {
    return 'size_t' if $t.name eq 'size_t';
    return resolve-type($t.ref-type);
  }
  return 'NYI';
}

sub generate-functions {
  for @cfunctions -> $f {
    my @tmp;
    for $f.arguments -> $a {
      @tmp.push(resolve-type($a.type) ~ ' ' ~ $a.name);
    }
    my $returns = $f.returns ~~ FundamentalType && $f.returns.name eq 'void' ?? '' !!
           "returns " ~ resolve-type($f.returns);
    say "sub {$f.name} is native(LIB) $returns (" ~ @tmp.join(', ') ~ ') { * }';
  }
}

sub generate-enums (@enum) {
  for @enum -> $e {
    say 'enum ' ~ $e.name ~ ' is export = (';
    my @tmp;
    for @($e.values) -> $v {
      @tmp.push("   " ~ $v.name ~ " => " ~ $v.init);
    }
    say @tmp.join(",\n");
    say ");";
  }
}

sub generate-structs {
  for %struct.kv -> $k, $s {
    say "class {$s.name} is repr('CStruct') is export \{";
    for $s.fields -> $field {
      my $has = ($field.type ~~ StructType | UnionType) ?? 'HAS' !! 'has';
      say "\t$has " ~ resolve-type($field.type) ~ "\t" ~ $field.name ~ ';';
    }
    say "}";
  }
}


class Field is rw {
  has	$.name;
  has	$.type-id;
  has	Type $.type;
}

class Struct is rw {
  has	$.name;
  has	$.id;
  has	Field @.fields;
}

class EnumValue is rw {
  has	$.name;
  has	$.init,
}

class CEnum is rw {
  has	$.name;
  has	$.id;
  has	EnumValue @.values;
}

class FunctionArgument is rw {
  has		$.name;
  has Type 	$.type;
}

class Function is rw {
  has	$.id;
  has	$.name;
  has	Type $.returns;
  has	FunctionArgument @.arguments;
}

sub do-magic($header) {

  say "gccxml $header -fxml=plop.xml";
  run "gccxml",  $header, "-fxml=plop.xml";

  my $xml = from-xml-file('plop.xml');

  my @xmlfields = $xml.lookfor(:TAG<Field>);
  my @xmlFundtypes = $xml.lookfor(:TAG<FundamentalType>);
  my @xmlPointertypes = $xml.lookfor(:TAG<PointerType>);
  my @xmlQualtypes = $xml.lookfor(:TAG<CvQualifiedType>);
  my @xmlTypesdef = $xml.lookfor(:TAG<Typedef>);
  my @xmlFunctionTypes = $xml.lookfor(:TAG<FunctionType>);
  my @xmlUnion = $xml.lookfor(:TAG<Union>);
  my @xmlFunctions = $xml.lookfor(:TAG<Function>, :name(* !~~ /^__/));


  #Gather type
  for @xmlFundtypes -> $ft {
    my FundamentalType $t .= new(:id($ft.attribs<id>));
    $t.name = $ft.attribs<name>;
    %types{$t.id} = $t;
  }

  for @xmlFunctionTypes -> $ft {
    my FunctionType $t .= new(:id($ft.attribs<id>));
    %types{$t.id} = $t;
  }

  #Need futher work
  for @xmlUnion -> $ft {
    my UnionType $t .= new(:id($ft.attribs<id>));
    %types{$t.id} = $t;
  }

  for @xmlPointertypes -> $ft {
    my PointerType $t .= new(:id($ft.attribs<id>));
    $t.ref-id = $ft.attribs<type>;
    %types{$t.id} = $t;
  }

  for @xmlQualtypes -> $ft {
    my QualifiedType $t .= new(:id($ft.attribs<id>));
    $t.ref-id = $ft.attribs<type>;
    %types{$t.id} = $t;
  }

  for @xmlTypesdef -> $ft {
    my TypeDefType $t .= new(:id($ft.attribs<id>));
    $t.ref-id = $ft.attribs<type>;
    $t.name = $ft.attribs<name>;
    %types{$t.id} = $t;
  }


  for @xmlfields -> $field {
    my $pf = Field.new();
    $pf.name = $field.attribs<name>;
    $pf.type-id = $field.attribs<type>;
    %fields{$field.attribs<id>} = $pf;
  }

  my @xmlStruct = $xml.lookfor(:TAG<Struct>);

  for @xmlStruct -> $xmls {
    my $s = Struct.new;
    $s.name = $xmls.attribs<name>;
    $s.id = $xmls.attribs<id>;
    my @rawmember = $xmls.attribs<members>.split(' ');
    for @rawmember {
      $s.fields.push(%fields{$_}) if %fields{$_}.defined;
    }
    %struct{$s.id} = $s;
    my StructType $t .= new(:id($s.id), :name($s.name));
    %types{$t.id} = $t;
  }


  my @xmlenum = $xml.lookfor(:TAG<Enumeration>);


  for @xmlenum -> $m {
    my CEnum $enum .= new(:id($m.attribs<id>), :name($m.attribs<name>));
    my EnumType $t .= new(:id($m.attribs<id>), :name($m.attribs<name>));
    %types{$t.id} = $t;
    for @($m.elements()) -> $enumv {
      my EnumValue $nv .= new(:name($enumv.attribs<name>), :init($enumv.attribs<init>));
      $enum.values.push($nv);
    }
    @cenums.push($enum);
  }

  #We probably can resolve every type now.
  sub resolvetype {
    my $change = True; #Do something like bubble sort, until we solve everytype, let's boucle
    while ($change) {
      $change = False;
      for %types.kv -> $id, $t {
	if $t ~~ IndirectType {
	  unless $t.ref-type:defined {
	    #say "Found an undef indirect id: "~ $t.ref-id;
	    $t.ref-type = %types{$t.ref-id};
	    $change = True;
	  }
	}
      }
    }
  }
  resolvetype();

  for @xmlFunctions -> $func {
    my Function $f .= new(:name($func.attribs<name>), :id($func.attribs<id>));
    $f.returns = %types{$func.attribs<returns>};
    for @($func.elements()) -> $param {
      my FunctionArgument $a .= new(:name($param.attribs<name>));
      $a.type = %types{$param.attribs<type>};
      $f.arguments.push($a);
    }
    @cfunctions.push($f);
  }

  # say "List type";
  # for %types.kv -> $k, $v {
  #   say $v.id ~ ':' ~ $v.Str;
  # }

  for %fields.kv ->  $id, $f {
    $f.type = %types{$f.type-id};
  }

}

# say "\n==CSTRUCT==";
# for %struct.kv -> $k, $v {
#   say "-$k : {$v.name}";
#   for $v.fields -> $f {
#     say "   {$f.type.Str} ({$f.type-id})  '{$f.name}'";
#   }
# }
# 
# say "==FUNCTIONS==";
# 
# for @cfunctions -> $f {
#   my @tmp;
#   for $f.arguments -> $a {
#     @tmp.push($a.type ~ ' ' ~ $a.name);
#   }
#   say $f.returns ~ "\t\t" ~ $f.name ~ '(' ~ @tmp.join(', ') ~ ')';
# }

