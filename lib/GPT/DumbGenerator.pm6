use GPT::Class;

module GPT::DumbGenerator {

my AllTheThings	$allthings;

sub dg-init($allt) is export {
  $allthings = $allt;
}

my %ctype-to-p6 = (
  'bool'            => 'bool',
  '_bool'           => 'bool',

  'char'            => 'int8',
  'unsigned char'   => 'uint8',

  'short'           => 'int16',
  'unsigned short'  => 'uint16',

  'int'             => 'int32',
  'unsigned int'    => 'uint32',

  'float'           => 'num32',
  'double'          => 'num64',

  'long'            => 'long',
  'long int'        => 'long',
  'unsigned long'   => 'ulong',
  'unsigned long int' => 'ulong',

  'long long'       => 'longlong',
  'long long int'   => 'longlong',

  'unsigned long long'      => 'ulonglong',
  'unsigned long long int'  => 'ulonglong',
  'long long unsigned int'  => 'ulonglong',

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


sub	resolve-type($t) is export {
  if $t ~~ PointerType {
    #say '$t.ref-type = ' ~ $t.ref-type;

    return 'Str' if $t.ref-type ~~ FundamentalType && $t.ref-type.name eq 'char' ||
      $t.ref-type ~~ QualifiedType && $t.ref-type.ref-type.name eq 'char';

    # Can't get this working, use Buf for now
    #return 'Pointer' if $t.ref-type ~~ FundamentalType && $t.ref-type.name eq 'void' ||
    #  $t.ref-type ~~ QualifiedType && $t.ref-type.ref-type.name eq 'void';
    return 'Buf' if $t.ref-type ~~ FundamentalType && $t.ref-type.name eq 'void' ||
      $t.ref-type ~~ QualifiedType && $t.ref-type.ref-type.name eq 'void';

    # Do something similar for unsigned char*
    return 'Buf' if $t.ref-type ~~ FundamentalType && $t.ref-type.name eq 'unsigned char' ||
      $t.ref-type ~~ QualifiedType && $t.ref-type.ref-type.name eq 'unsigned char';


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
    #say 'got typedeftype, $t = ' ~ $t;
    #say '--> $t.name = ' ~ $t.name;
    return 'size_t' if $t.name eq 'size_t';
    return %stdinttype-to-p6{$t.name} if %stdinttype-to-p6{$t.name};
    return $t.name if $t.ref-type ~~ FundamentalType;
    return resolve-type($t.ref-type);
  }
  if $t ~~ UnionType {
    return $allthings.unions{$t.id}.gen-name;
  }
  return 'NYI(' ~ $t.Str ~ ')';
}

sub get-def($file, $line) {
    my @def-lines;
    my @file-lines = $file.IO.lines;
    my $i = $line - 1;

    while @file-lines[$i].chars > 0 {
        @def-lines.push(@file-lines[$i]);
        $i--;
    }
    @def-lines.reverse
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
    my $args = @tmp.join(', ');
    my $p6gen;

    # Add commented definition above sub
    #$p6gen ~= "file: " ~ $f.file;
    #$p6gen ~= "start-ling: " ~ $f.start-line;

    my $function-def = get-def($f.file, $f.start-line).map({ "# $_" }).join("\n") ~ "\n";
    $p6gen ~= $function-def;

    $p6gen ~= "sub {$f.name}($args)\n";
    if $returns {
        $p6gen ~= qq:to/END/;
            $returns
        END
    }
    $p6gen ~= qq:to/END/;
        is native(LIB)
        is export
        \{ * \}
    END

    #"sub {$f.name}(" ~  ~ ")\n"\
    #"" is native(LIB) $returns ("  ~ ') is export { * }';

    %toret{$f.name} = $p6gen;
  }
  return %toret;
}

sub dg-generate-enums() is export {
  for $allthings.enums -> $e {
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
  for $allthings.unions.kv -> $k, $cu {
    $p6gen = "class {$cu.gen-name} is repr('CUnion') is export \{\n";
    for $cu.members -> $m {
      my $has = ($m.type ~~ StructType) ?? 'HAS' !! 'has';
      $p6gen ~= sprintf("\t%s %-30s\$.%s; # %s %s\n", $has, resolve-type($m.type), $m.name, $m.type, $m.name);
      #$p6gen ~= "\t$has " ~ resolve-type($m.type) ~ "\t" ~ $m.name ~ "; # " ~ $m.type ~ ' ' ~ $m.name ~ "\n";
    }
    $p6gen ~= "}";
    %toret{$cu.gen-name} = $p6gen;
  }
  for $allthings.structs.kv -> $k, $s {
    $p6gen = "class {$s.name} is repr('CStruct') is export \{\n";
    for $s.fields -> $field {
      my $has = ($field.type ~~ StructType | UnionType) ?? 'HAS' !! 'has';
      $p6gen ~= sprintf("\t%s %-30s\$.%s; # %s %s\n", $has, resolve-type($field.type), $field.name, $field.type, $field.name);
    }
    $p6gen ~= "}";
    %toret{$s.name} = $p6gen;
  }
  return %toret;
}

}
