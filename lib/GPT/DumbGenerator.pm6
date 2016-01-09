use GPT::Class;

module GPT::DumbGenerator {

my AllTheThings	$allthings;

sub dg-init($allt) is export {
  $allthings = $allt;
}

my %ctype-to-p6 = (
  'char' => 'int8',
  'bool' => 'bool',
  '_bool' => 'bool',
  'int' => 'int32',
  'float' => 'num32',
  'double' => 'num64',
  'long' => 'long',
  'unsigned int' => 'uint32',
  'unsigned char' => 'uint8'
).hash;



sub	resolve-type($t) is export {
  if $t ~~ PointerType {
    if $t.ref-type ~~ TypeDefType and $t.ref-type.ref-type ~~ FundamentalType and $t.ref-type.ref-type.name eq 'void' {
      return $t.ref-type.name ~ 'Ptr';
    }
    return 'Str' if $t.ref-type ~~ FundamentalType && $t.ref-type.name eq 'char' ||
      $t.ref-type ~~ QualifiedType && $t.ref-type.ref-type.name eq 'char';
    return 'Pointer' if $t.ref-type ~~ FundamentalType && $t.ref-type.name eq 'void' ||
      $t.ref-type ~~ QualifiedType && $t.ref-type.ref-type.name eq 'void';
    return 'Pointer[PtrFunc]' if $t.ref-type ~~ FunctionType;
    return 'Pointer[' ~ resolve-type($t.ref-type) ~ ']';
    
  }
  if $t ~~ ArrayType {
    return 'CArray[' ~ resolve-type($t.ref-type) ~ ']';
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
    return $t.name if $t.ref-type ~~ FundamentalType;
    return resolve-type($t.ref-type);
  }
  if $t ~~ UnionType {
    return $allthings.unions{$t.id}.gen-name;
  }
  return 'NYI(' ~ $t.Str ~ ')';
}

sub dg-generate-extra is export {
    for $allthings.types.kv -> $k, $t {
      if $t ~~ PointerType and $t.ref-type ~~ TypeDefType and $t.ref-type.ref-type ~~ FundamentalType and $t.ref-type.ref-type.name eq 'void' {
        say 'constant ' ~ $t.ref-type.name ~ 'Ptr is export = Pointer;';
      }
      if $t ~~ TypeDefType and $t.ref-type ~~ StructType {
        say 'constant ' ~ $t.name ~ ' is export := ' ~ $t.ref-type.name ~ ';';
      }
    }
}

sub dg-generate-functions is export {
  my %toret;
  for $allthings.functions -> $f {
    my @tmp = ();
    for $f.arguments -> $a {
      @tmp.push(resolve-type($a.type) ~ ' ' ~ ($a.name.defined ?? '$' ~ $a.name !! ''));
    }
    my $returns = ($f.returns ~~ FundamentalType && $f.returns.name eq 'void') ?? '' !!
           "returns " ~ resolve-type($f.returns);
    my $p6gen = "sub {$f.name}(" ~  @tmp.join(', ') ~ ") is native(LIB) $returns is export \{ * \}";
    %toret{$f.name} = $p6gen;
  }
  return %toret;
}

sub dg-generate-enums() is export {
  for $allthings.enums -> $e {
    say 'enum ' ~ $e.name ~ ' is export (';
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
  for $allthings.unions.kv -> $k, $cu {
    $p6gen = "class {$cu.gen-name} is repr('CUnion') is export \{\n";
    for $cu.members -> $m {
      my $has = ($m.type ~~ StructType) ?? 'HAS' !! 'has';
      $p6gen ~= sprintf("\t%s %-30s\$.%s; # %s %s\n", $has, resolve-type($m.type), $m.name, $m.type, $m.name);
      #$p6gen ~= "\t$has " ~ resolve-type($m.type) ~ "\t" ~ $m.name ~ "; # " ~ $m.type ~ ' ' ~ $m.name ~ "\n";
    }
    $p6gen ~= "}";
    %toret{$cu.gen-name}<p6str> = $p6gen;
    %toret{$cu.gen-name}<obj> = $cu;
  }
  for $allthings.structs.kv -> $k, $s {
    $p6gen = "class {$s.name} is repr('CStruct') is export \{\n";
    for $s.fields -> $field {
      my $has = ($field.type ~~ StructType | UnionType) ?? 'HAS' !! 'has';
      $p6gen ~= sprintf("\t%s %-30s\$.%s; # %s %s\n", $has, resolve-type($field.type), $field.name, $field.type, $field.name);
    }
    $p6gen ~= "}";
    %toret{$s.name}<p6str> = $p6gen;
    %toret{$s.name}<obj> = $s;
  }
  return %toret;
}

sub	dg-generate-externs is export {
  for $allthings.variables -> $v {
    say 'our '~ resolve-type($v.type) ~ ' $' ~ $v.name ~ ' is export = cglobals(LIB, "' ~ $v.name ~ '", ' ~ resolve-type($v.type) ~ ');'
  }
  
}

}