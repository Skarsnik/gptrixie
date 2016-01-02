use GPClass;

module DumbGenerator {

my %types;
my %fields;
my %struct;
my @cfunctions;
my @cenums;
my %cunions;

sub dg-init(%t, %f, %s, @cf, @ce, %u) is export {
  %types = %t;
  %fields = %f;
  %struct = %s;
  @cfunctions = @cf;
  @cenums = @ce;
  %cunions = %u;
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



sub	resolve-type($t) is export {
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
  if $t ~~ UnionType {
    return %cunions{$t.id}.gen-name;
  }
  return 'NYI';
}

sub dg-generate-functions is export {
  my %toret;
  for @cfunctions -> $f {
    my @tmp = ();
    for $f.arguments -> $a {
      @tmp.push(resolve-type($a.type) ~ ' ' ~ ($a.name.defined ?? '$' ~ $a.name !! ''));
    }
    my $returns = ($f.returns ~~ FundamentalType && $f.returns.name eq 'void') ?? '' !!
           "returns " ~ resolve-type($f.returns);
    my $p6gen = "sub {$f.name} is native(LIB) $returns (" ~ @tmp.join(', ') ~ ') { * }';
    %toret{$f.name} = $p6gen;
  }
  return %toret;
}

sub dg-generate-enums(@enum) is export {
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

sub dg-generate-structs is export {
  my %toret;
  my $p6gen;
  for %cunions.kv -> $k, $cu {
    $p6gen = "class {$cu.gen-name} is repr('CUnion') is export \{\n";
    for $cu.members -> $m {
      my $has = ($m.type ~~ StructType) ?? 'HAS' !! 'has';
      $p6gen ~= "\t$has " ~ resolve-type($m.type) ~ "\t" ~ $m.name ~ ";\n";
    }
    $p6gen ~= "}";
    %toret{$cu.gen-name} = $p6gen;
  }
  for %struct.kv -> $k, $s {
    $p6gen = "class {$s.name} is repr('CStruct') is export \{\n";
    for $s.fields -> $field {
      my $has = ($field.type ~~ StructType | UnionType) ?? 'HAS' !! 'has';
      $p6gen ~= "\t$has " ~ resolve-type($field.type) ~ "\t\$." ~ $field.name ~ ";\n";
    }
    $p6gen ~= "}";
    %toret{$s.name} = $p6gen;
  }
  return %toret;
}
  
}