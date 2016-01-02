use DumbGenerator;
use GPClass;
use Config::Simple

module OOGenerator {
  my $config;
  sub ooc-config($conff) {
    $config = Config::Simple.read($conff, :f('ini'));
  }
  sub ooc-generate {
    my %funcs = dg-generate-functions();
    my %struct = dg-generate-structs();
    say %struct{$config<OOC><ctypename>};
    
    say "class P6FakeObject \{";
    say "has	Pointer[{$config<OOC><ctypename>}] "~ ' $!internal-pointer;';
    
    for %funcs.kv -> $n, $f {
      if $n ~~ /$config<OOC><methodpattern>/ {
        
      }
    }
  }
}