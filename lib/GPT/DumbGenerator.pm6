use GPT::Class;

module GPT::DumbGenerator {

my AllTheThings	$allthings;
my	$debug = False;

sub	debug(*@stuff) {
  say(|@stuff) if $debug;
}

sub dg-init($allt) is export {
  $allthings = $allt;
}

my %ctype-to-p6 = (
'bool'            => 'bool',
  '_bool'           => 'bool',

  'char'            => 'int8',
  'signed char'     => 'int8',
  'unsigned char'   => 'uint8',

  'short'           => 'int16',
  'short int'       => 'int16',
  'unsigned short'  => 'uint16',
  'short unsigned int' => 'uint16',

  'int'             => 'int32',
  'unsigned int'    => 'uint32',

  'float'           => 'num32',
  'double'          => 'num64',

  'long'            => 'long',
  'long int'        => 'long',
  'unsigned long'   => 'ulong',
  'unsigned long int' => 'ulong',
  'long unsigned int' => 'ulong',

  'long long'       => 'longlong',
  'long long int'   => 'longlong',

  'unsigned long long'      => 'ulonglong',
  'unsigned long long int'  => 'ulonglong',
  'long long unsigned int'  => 'ulonglong'
).hash;

my %stdinttype-to-p6 = (
  # Fixed width types from stdint.h
  'int8_t'          => 'int8',
  'int16_t'         => 'int16',
  'int32_t'         => 'int32',
  'int64_t'         => 'int64',

  'uint8_t'         => 'uint8',
  'uint16_t'        => 'uint16',
  'uint32_t'        => 'uint32',
  'uint64_t'        => 'uint64',
).hash;



sub	resolve-type($t, $cpt = 0) is export {
  debug "==" x $cpt ~ $t.id ~ $t.WHAT.perl ~ ' ' ~ $t;
  if $t ~~ PointerType {
    if $t.ref-type ~~ TypeDefType and $t.ref-type.ref-type ~~ FundamentalType and $t.ref-type.ref-type.name eq 'void' {
      return $t.ref-type.name ~ 'Ptr';
    }
    return 'Str' if ($t.ref-type ~~ FundamentalType and $t.ref-type.name eq 'char') ||
      ($t.ref-type ~~ QualifiedType and $t.ref-type.ref-type.name eq 'char');
    return 'Pointer' if ($t.ref-type ~~ FundamentalType and $t.ref-type.name eq 'void') ||
      ($t.ref-type ~~ QualifiedType and $t.ref-type.ref-type.name eq 'void');
    return 'Pointer[PtrFunc]' if $t.ref-type ~~ FunctionType;
    return 'Pointer[' ~ resolve-type($t.ref-type, $cpt + 1) ~ ']';
    
  }
  if $t ~~ ArrayType {
    return 'CArray[' ~ resolve-type($t.ref-type, $cpt + 1) ~ ']';
  }
  if $t ~~ FundamentalType {
    if %ctype-to-p6{$t.name}:exists {
      return %ctype-to-p6{$t.name};
    } else {
      warn "Encounter a not know FundamentalType ({$t.name}), either it missing in DG dic or you need to do something specific";
      return "NAT{$t.name}NAT";
    }
  }
  if $t ~~ EnumType {
    return 'int32';
  }
  if $t ~~ StructType {
    return $t.name;
  }
  if $t ~~ QualifiedType {
    return resolve-type($t.ref-type, $cpt + 1);
  }
  if $t ~~ TypeDefType {
    return 'size_t' if $t.name eq 'size_t';
    return $t.name if $t.ref-type ~~ FundamentalType;
    return %stdinttype-to-p6{$t.name} if %stdinttype-to-p6{$t.name};
    return resolve-type($t.ref-type, $cpt + 1);
  }
  if $t ~~ UnionType {
    return $allthings.unions{$t.id} ~~ AnonymousUnion ?? $allthings.unions{$t.id}.gen-name 
           !! $allthings.unions{$t.id}.name;
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
    debug "Function:" ~ $f.name;
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
    my $u-name = $cu ~~ AnonymousUnion ?? $cu.gen-name !! $cu.name;
    $p6gen = "class $u-name is repr('CUnion') is export \{\n";
    for $cu.members -> $m {
      my $has = ($m.type ~~ StructType) ?? 'HAS' !! 'has';
      $p6gen ~= sprintf("\t%s %-30s\$.%s; # %s %s\n", $has, resolve-type($m.type), $m.name, $m.type, $m.name);
      #$p6gen ~= "\t$has " ~ resolve-type($m.type) ~ "\t" ~ $m.name ~ "; # " ~ $m.type ~ ' ' ~ $m.name ~ "\n";
    }
    $p6gen ~= "}";
    %toret{$u-name}<p6str> = $p6gen;
    %toret{$u-name}<obj> = $cu;
  }
  for $allthings.structs.kv -> $k, $s {
    debug "Structure : " ~ $s.name;
    $p6gen = "class {$s.name} is repr('CStruct') is export \{\n";
    for $s.fields -> $field {
      debug "--Field : " ~ $field.name ~ "    " ~ $field.type;
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