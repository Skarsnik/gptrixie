use GPT::Class;

unit module GPT::HandleFileDeps;

sub list-deps($att, $filename) is export {
  for $att.files.kv -> $f-id, $f-name {
      my $basename = $f-name.IO.basename;
      if $basename eq $filename {
        my @files-deps;
        my %deps = find-deps($f-id, $att);
        for %deps<structs>.kv -> $sname, $sinfo {
          say "Struct $sname has field depending on other files";
          for $sinfo.kv -> $fname, $field-info {
             say "--", "$fname : ", $field-info<field>.type.Str, " from ",  $att.files{$field-info<file-id>};
             @files-deps.push($att.files{$field-info<file-id>});
          }
        }
        say "Dependancies are : ", @files-deps.unique.join(' - ');
        return;
      }
  }
  sub find-deps ($file-id, $alltt) {
    #say "Find dep : " ~ $att.files{$file-id};
    my %toret;
    for $alltt.structs.kv -> $k, $struct {
          if ($struct.file-id eq $file-id) {
            for $struct.fields -> $field {
              my $c-location = get-clocation($field.type);
              if $c-location.defined && $c-location.file-id ne $file-id {
                 %toret<structs>{$struct.name}{$field.name}<field> = $field;
                 %toret<structs>{$struct.name}{$field.name}<file-id> = $c-location.file-id;
                 %toret<structs>{$struct.name}{$field.name}<deps> = find-deps($c-location.file-id, $alltt);
              }
            }
          }
    }
    sub get-clocation(Type $t) {
      return $t if ($t ~~ CLocation && $t ~~ DirectType);
      return get-clocation($t.ref-type) if ($t ~~ IndirectType);
      return Any:U;
    }
    return %toret;
  }
}