unit module GPT::FileFilter;

#Used to Filter files. the 'std' exclude are kinda bad

sub files-filter($file-id, $file, @excluded, @selected?, :$context) returns Bool is export {
    my $basename = $file.IO.basename;
    
    #Autoexclude stuff
    return False if $basename ~~ /^std/;
    return False if $basename eq '<builtin>'/;
    return False if $basename ~~ /^pthread/;
    return False if $basename eq 'libio.h';
    return False if $basename eq 'string.h';
    return False if $basename eq 'errno.h';
    return False if $file ~~ /'/usr/include/'.+?'-linux-gnu/bits/'/;
    return False if $file ~~ /'/usr/include/'.+?'-linux-gnu/sys/'/;
    return False if $file ~~ /'/castxml/clang/include/'/;
    
    if @selected !== Empty {
      my @files-list;
      for @selected -> $f {
         if $f ~~ /^ $<myc> = ([f|e|s]) ':' $<filename> = (.+) / {
           #say "Got a special filename : $<myc> --- context : $context " ~ $<filename> if $context.defined and $<myc> eq $context;
           @files-list.push($<filename>.Str) if $context.defined and $<myc> eq $context;
           say @files-list;
         } else {
           @files-list.push($f);
         }
      }
      if $basename (<=) @files-list || ('@' ~ $file-id) (<=)  @files-list {
        return True;
      }
      return False;
    }
    if @excluded!== Empty {
      if $basename (<=) @excluded || ('@' ~ $file-id) (<=)  @excluded {
        return False;
      }
      return True;
    }
    return True;
  }
