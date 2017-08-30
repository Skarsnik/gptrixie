use GPT::Class;

unit module GPT::HandleFileDeps;

my @files-searched;
my %alldeps;

sub print-deps($att, %deps, $depth) {
  say %alldeps.perl;
  for %alldeps.kv -> $file-id, $deps {
  say "==For file {$att.files{$file-id}}==";
  my %deps = $deps;
    for %deps<structs>.kv -> $sname, $sinfo {
    say ' ' x $depth * 2, "Struct $sname has field(s) depending on other files";
    for $sinfo.kv -> $fname, $field-info {
      say ' ' x $depth * 2, '  ', "$fname : ", $field-info<field>.type.Str, " from ",  $att.files{$field-info<file-id>};
    }
    for %deps<functions>.kv -> $fname, $finfo {
    say ' ' x $depth * 2, "Function $fname has argument(s) depending on other files";
    for $finfo.kv -> $arg-name, $arg-info {
      say ' ' x $depth * 2, '  Argument ', "'$arg-name' : ", $arg-info<argument>.type.Str, " from ", $att.files{$arg-info<file-id>};
    }
  }
  }
  }
}


sub list-deps($att, $filename) is export {
  for $att.files.kv -> $f-id, $f-name {
      my $basename = $f-name.IO.basename;
      if $basename eq $filename {
        my @files-deps;
        my %deps = find-deps($f-id, $att);
        print-deps($att, %deps, 0);
        #for %deps<structs>.kv -> $sname, $sinfo {
        #  for $sinfo.kv -> $fname, $field-info {
         #    @files-deps.push($att.files{$field-info<file-id>});
         # }
        #}
        say "Dependancies are : ", (%alldeps.keys.map:{$att.files{$_}}).join(' - ');
        return;
      }
  }
  sub find-deps($file-id, $alltt) {
    @files-searched = Empty;
    %alldeps = Empty;
    partial-find-deps($file-id, $alltt);
  }
  
  sub partial-find-deps ($file-id, $alltt) {
    say "Find dep : " ~ $att.files{$file-id};
    my %toret;
    @files-searched.append($file-id);
    for $alltt.structs.kv -> $k, $struct {
          if ($struct.file-id eq $file-id) {
            for $struct.fields -> $field {
              my $c-location = get-clocation($field.type);
              if $c-location.defined && $c-location.file-id ne $file-id {
                 say "structs";
                 %toret<structs>{$struct.name}{$field.name}<field> = $field;
                 %toret<structs>{$struct.name}{$field.name}<file-id> = $c-location.file-id;
                 unless @files-searched.contains: $c-location.file-id {
                   %toret<structs>{$struct.name}{$field.name}<deps> = partial-find-deps($c-location.file-id, $alltt);
                 }
              }
            }
          }
    }
    for $alltt.functions -> $function {
      if $function.file-id eq $file-id {
        for $function.arguments -> $arg {
          my $c-location = get-clocation($arg.type);
          if $c-location.defined && $c-location.file-id ne $file-id {
            say $function.name, $arg.name, $file-id, $arg.type.Str, " ^ " , $c-location;
            %toret<functions>{$function.name}{$arg.name}<argument> = $arg;
            %toret<functions>{$function.name}{$arg.name}<file-id> = $c-location.file-id;
            unless @files-searched.contains: $c-location.file-id {
              %toret<functions>{$function.name}{$arg.name}<deps> = partial-find-deps($c-location.file-id, $alltt);
            }
          }
        }
      }
    }
    sub get-clocation(Type $t) {
      return $t if ($t ~~ CLocation && $t ~~ DirectType);
      return get-clocation($t.ref-type) if ($t ~~ IndirectType);
      return Any:U;
    }
    %alldeps{$file-id} = %toret;
    return %toret;
  }
}