use GPT::Class;

unit module GPT::ListTypes;

sub list-types($att) is export {
 my %tdisplay;
    
    my %t = $att.types;
    for %t.kv -> $k, $v {
      for <FundamentalType StructType UnionType ArrayType TypeDefType> -> $cmp {
        if $v ~~ ::($cmp) {
          %tdisplay{$cmp}.push($v);
          %t{$k}:delete;
        }
      }
    }
    for <FundamentalType StructType UnionType ArrayType TypeDefType> -> $cmp {
      next unless %tdisplay{$cmp}:exists;
      say "====$cmp (" ~ @(%tdisplay{$cmp}).elems ~ ") ====";
      for @(%tdisplay{$cmp}) -> $t {
        say $t.id~ ':' ~$t;
      }
    }
    say "====OTHER====";
    for %t.values {
      say ~$_;
    }
    for $att.types.values {
      if $_ ~~ IndirectType {
        if $_.ref-type !~~ Type {
          say "Type Error: " ~ $_.id ~ " did not get resolved";
        }
      }
    }
}