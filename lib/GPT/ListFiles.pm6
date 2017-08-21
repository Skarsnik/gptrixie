unit module GPT::ListFiles;

sub list-files($att) is export {
  for $att.files.keys.sort:{$^a.substr(1) > $^b.substr(1)} -> $k {
      sub count-stuff(@t, $file) {
        return (@t.grep:{$_.file-id eq $file}).elems;
      }
      my $func = count-stuff($att.functions, $k);
      my $enum = count-stuff($att.enums, $k);
      my $struct = count-stuff($att.structs.values, $k);
      printf "%-5s%s%-50s - Functions(%d), Enums(%d), Structures(%d)\n", $k, ' : ', $att.files{$k}, $func, $enum, $struct;
    }
}