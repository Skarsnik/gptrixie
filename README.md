# GPTrixie (The Great and Powerful Trixie)

A tool to generate NativeCall code from C headers

You will need gccxml and gcc/g++ 4.9
Beware some distributions provide gccxml as castxml and it's bad (does not want to take c99 headers), you will need to change the code to use gccxml.real
or make sure the gccxml executable is gccxml

# Usage

`Usage:
gptrixie [--all] [--define-enum=<Str>] [--ooc=<Str>] [--enums] [--functions] [--structs] [--externs] [--list-types] <header-file> [<gccoptions> ...]
`

gccoptions can be stuff like -I /another/include/path

The --define-enum option allows you to generate an enum from #define, it takes a starting string like `MSQL_TYPE`

The --list-types option is mainly for debugging, it lists all the C types found.

You can do a 'dry' run without options, to have an idea of the lenght of the output. It can be useful
to know what to expect. This is an example with one of a libxml2 headers:

```
Number of things founds
-Types: 972
-Structures: 80
-Unions: 12
-Enums: 31
-Functions: 1068
-Variables: 45
-Files: 52
```

Most GPTrixie messages are in stderr, allowing you to redirect the generated perl6 code into a file.

More options and other specific generators will come in the future.

# Limitations

The default generator is not smart. It can't really make sense of how the type is used; some arbitrary
choice is made for you. You will probably have to adjust the generated code.

char * and const char * become Str

void * and const void * are Pointer

Typedef defined on top of a fundamental C type are left as is. You will have to complete the missing
definition for the type. This choice is based on stuff like sqlite_int64 where is up to you to either
replace with int64 or define a `constant sqlite_int64 = int64`


## C++ Support

C++ support is planned

# Example

(The display can change)

 t@testperl6:~/piko/gptrixie# perl6  -I lib bin/gptrixie --all /usr/local/include/gumbo.h
 

```perl
## Enumerations
enum GumboNamespaceEnum is export (
   GUMBO_NAMESPACE_HTML => 0,
   GUMBO_NAMESPACE_SVG => 1,
   GUMBO_NAMESPACE_MATHML => 2
);
enum GumboParseFlags is export (
   GUMBO_INSERTION_NORMAL => 0,
   GUMBO_INSERTION_BY_PARSER => 1,
   GUMBO_INSERTION_IMPLICIT_END_TAG => 2,
   GUMBO_INSERTION_IMPLIED => 8,
   GUMBO_INSERTION_CONVERTED_FROM_END_TAG => 16,
   GUMBO_INSERTION_FROM_ISINDEX => 32,
   GUMBO_INSERTION_FROM_IMAGE => 64,
   GUMBO_INSERTION_RECONSTRUCTED_FORMATTING_ELEMENT => 128,
   GUMBO_INSERTION_ADOPTION_AGENCY_CLONED => 256,
   GUMBO_INSERTION_ADOPTION_AGENCY_MOVED => 512,
   GUMBO_INSERTION_FOSTER_PARENTED => 1024
);

enum GumboQuirksModeEnum is export (
   GUMBO_DOCTYPE_NO_QUIRKS => 0,
   GUMBO_DOCTYPE_QUIRKS => 1,
   GUMBO_DOCTYPE_LIMITED_QUIRKS => 2
);
enum GumboAttributeNamespaceEnum is export (
   GUMBO_ATTR_NAMESPACE_NONE => 0,
   GUMBO_ATTR_NAMESPACE_XLINK => 1,
   GUMBO_ATTR_NAMESPACE_XML => 2,
   GUMBO_ATTR_NAMESPACE_XMLNS => 3
);
enum GumboNodeType is export (
   GUMBO_NODE_DOCUMENT => 0,
   GUMBO_NODE_ELEMENT => 1,
   GUMBO_NODE_TEXT => 2,
   GUMBO_NODE_CDATA => 3,
   GUMBO_NODE_COMMENT => 4,
   GUMBO_NODE_WHITESPACE => 5,
   GUMBO_NODE_TEMPLATE => 6
);
## Structures
class GumboSourcePosition is repr('CStruct') is export {
        has uint32                        $.line; # unsigned int line
        has uint32                        $.column; # unsigned int column
        has uint32                        $.offset; # unsigned int offset
}
class GumboStringPiece is repr('CStruct') is export {
        has Str                           $.data; # const char* data
        has size_t                        $.length; # Typedef(size_t)->|unsigned int| length
}
class GumboVector is repr('CStruct') is export {
        has Pointer[Pointer]              $.data; # void** data
        has uint32                        $.length; # unsigned int length
        has uint32                        $.capacity; # unsigned int capacity
}
class GumboAttribute is repr('CStruct') is export {
        has int32                         $.attr_namespace; # GumboAttributeNamespaceEnum attr_namespace
        has Str                           $.name; # const char* name
        HAS GumboStringPiece              $.original_name; # GumboStringPiece original_name
        has Str                           $.value; # const char* value
        HAS GumboStringPiece              $.original_value; # GumboStringPiece original_value
        HAS GumboSourcePosition           $.name_start; # GumboSourcePosition name_start
        HAS GumboSourcePosition           $.name_end; # GumboSourcePosition name_end
        HAS GumboSourcePosition           $.value_start; # GumboSourcePosition value_start
        HAS GumboSourcePosition           $.value_end; # GumboSourcePosition value_end
}
class GumboDocument is repr('CStruct') is export {
        HAS GumboVector                   $.children; # GumboVector children
        has bool                          $.has_doctype; # bool has_doctype
        has Str                           $.name; # const char* name
        has Str                           $.public_identifier; # const char* public_identifier
        has Str                           $.system_identifier; # const char* system_identifier
        has int32                         $.doc_type_quirks_mode; # GumboQuirksModeEnum doc_type_quirks_mode
}
class GumboText is repr('CStruct') is export {
        has Str                           $.text; # const char* text
        HAS GumboStringPiece              $.original_text; # GumboStringPiece original_text
        HAS GumboSourcePosition           $.start_pos; # GumboSourcePosition start_pos
}
class GumboElement is repr('CStruct') is export {
        HAS GumboVector                   $.children; # GumboVector children
        has int32                         $.tag; # GumboTag tag
        has int32                         $.tag_namespace; # GumboNamespaceEnum tag_namespace
        HAS GumboStringPiece              $.original_tag; # GumboStringPiece original_tag
        HAS GumboStringPiece              $.original_end_tag; # GumboStringPiece original_end_tag
        HAS GumboSourcePosition           $.start_pos; # GumboSourcePosition start_pos
        HAS GumboSourcePosition           $.end_pos; # GumboSourcePosition end_pos
        HAS GumboVector                   $.attributes; # GumboVector attributes
}
class GumboInternalNode_v_Union is repr('CUnion') is export {
        HAS GumboDocument                 $.document; # GumboDocument document
        HAS GumboElement                  $.element; # GumboElement element
        HAS GumboText                     $.text; # GumboText text
}
class GumboInternalNode is repr('CStruct') is export {
        has int32                         $.type; # GumboNodeType type
        has Pointer[GumboInternalNode]    $.parent; # Typedef(GumboNode)->|GumboInternalNode|* parent
        has size_t                        $.index_within_parent; # Typedef(size_t)->|unsigned int| index_within_parent
        has int32                         $.parse_flags; # GumboParseFlags parse_flags
        HAS GumboInternalNode_v_Union     $.v; # Union v
}
class GumboInternalOptions is repr('CStruct') is export {
        has Pointer[PtrFunc]              $.allocator; # Typedef(GumboAllocatorFunction)->|PtrFunc*| allocator
        has Pointer[PtrFunc]              $.deallocator; # Typedef(GumboDeallocatorFunction)->|PtrFunc*| deallocator
        has Pointer                       $.userdata; # void* userdata
        has int32                         $.tab_stop; # int tab_stop
        has bool                          $.stop_on_first_error; # bool stop_on_first_error
        has int32                         $.max_errors; # int max_errors
        has int32                         $.fragment_context; # GumboTag fragment_context
        has int32                         $.fragment_namespace; # GumboNamespaceEnum fragment_namespace
}
class GumboInternalOutput is repr('CStruct') is export {
        has Pointer[GumboInternalNode]    $.document; # Typedef(GumboNode)->|GumboInternalNode|* document
        has Pointer[GumboInternalNode]    $.root; # Typedef(GumboNode)->|GumboInternalNode|* root
        HAS GumboVector                   $.errors; # GumboVector errors
}
## Extras stuff
constant GumboOutput is export := GumboInternalOutput;
constant GumboOptions is export := GumboInternalOptions;
constant GumboNode is export := GumboInternalNode;
## Functions
sub gumbo_get_attribute(Pointer[GumboVector] $attrs, Str $name) is native(LIB) returns Pointer[GumboAttribute] is export { * }
sub gumbo_normalized_tagname(int32 $tag) is native(LIB) returns Str is export { * }
sub gumbo_parse(Str $buffer) is native(LIB) returns Pointer[GumboInternalOutput] is export { * }
sub gumbo_string_equals_ignore_case(Pointer[GumboStringPiece] $str1, Pointer[GumboStringPiece] $str2) is native(LIB) returns bool is export { * }
sub gumbo_tag_from_original_text(Pointer[GumboStringPiece] $text) is native(LIB)  is export { * }
sub gumbo_vector_index_of(Pointer[GumboVector] $vector, Pointer $element) is native(LIB) returns int32 is export { * }
sub gumbo_tagn_enum(Str $tagname, uint32 $length) is native(LIB) returns int32 is export { * }
sub gumbo_destroy_output(Pointer[GumboInternalOptions] $options, Pointer[GumboInternalOutput] $output) is native(LIB)  is export { * }
sub gumbo_string_equals(Pointer[GumboStringPiece] $str1, Pointer[GumboStringPiece] $str2) is native(LIB) returns bool is export { * }
sub gumbo_normalize_svg_tagname(Pointer[GumboStringPiece] $tagname) is native(LIB) returns Str is export { * }
sub gumbo_parse_with_options(Pointer[GumboInternalOptions] $options, Str $buffer, size_t $buffer_length) is native(LIB) returns Pointer[GumboInternalOutput] is export { * }
sub gumbo_tag_enum(Str $tagname) is native(LIB) returns int32 is export { * }
## Externs
our GumboInternalOptions $kGumboDefaultOptions is export = cglobals(LIB, "kGumboDefaultOptions", GumboInternalOptions);
our GumboStringPiece $kGumboEmptyString is export = cglobals(LIB, "kGumboEmptyString", GumboStringPiece);
our GumboVector $kGumboEmptyVector is export = cglobals(LIB, "kGumboEmptyVector", GumboVector);
our GumboSourcePosition $kGumboEmptySourcePosition is export = cglobals(LIB, "kGumboEmptySourcePosition", GumboSourcePosition);

```

# Reporting bugs and errors

Use the github issue tracker. Try to give the name of the headers


# Licence

This software is under the same licence as Rakudo. See the LICENCE file
