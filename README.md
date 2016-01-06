# gptrixie
A tool to generate NativeCall code from C headers

You will need gccxml and gcc/g++ 4.9
Beware some distrib provide gccxml as castxml and it's bad (does not want to take c99 headers), you will need to change the code to use gccxml.real
of have sure the gccxml executable is gccxml

use it like this :

 `gptrixie --enums --structs --functions path/myheader.h`

Try to keep the header at his original location if it include other

There is also a define-enum option to generate enum from #define

 --define-enum=EnumName:Definepattern

# Example


 t@testperl6:~/piko/gptrixie# perl6  -I lib bin/gptrixie --functions --enums --structs /usr/local/include/gumbo.h 

```perl
enum GumboNamespaceEnum is export = (
   GUMBO_NAMESPACE_HTML => 0,
   GUMBO_NAMESPACE_SVG => 1,
   GUMBO_NAMESPACE_MATHML => 2
);
enum GumboParseFlags is export = (
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
enum GumboQuirksModeEnum is export = (
   GUMBO_DOCTYPE_NO_QUIRKS => 0,
   GUMBO_DOCTYPE_QUIRKS => 1,
   GUMBO_DOCTYPE_LIMITED_QUIRKS => 2
);
enum GumboAttributeNamespaceEnum is export = (
   GUMBO_ATTR_NAMESPACE_NONE => 0,
   GUMBO_ATTR_NAMESPACE_XLINK => 1,
   GUMBO_ATTR_NAMESPACE_XML => 2,
   GUMBO_ATTR_NAMESPACE_XMLNS => 3
);
enum GumboNodeType is export = (
   GUMBO_NODE_DOCUMENT => 0,
   GUMBO_NODE_ELEMENT => 1,
   GUMBO_NODE_TEXT => 2,
   GUMBO_NODE_CDATA => 3,
   GUMBO_NODE_COMMENT => 4,
   GUMBO_NODE_WHITESPACE => 5,
   GUMBO_NODE_TEMPLATE => 6
);
sub gumbo_get_attribute is native(LIB) returns Pointer[GumboAttribute] (Pointer[GumboVector] $attrs, Str $name) { * }
sub gumbo_normalized_tagname is native(LIB) returns Str (int32 $tag) { * }
sub gumbo_parse is native(LIB) returns Pointer[GumboInternalOutput] (Str $buffer) { * }
sub gumbo_string_equals_ignore_case is native(LIB) returns bool (Pointer[GumboStringPiece] $str1, Pointer[GumboStringPiece] $str2) { * }
sub gumbo_tag_from_original_text is native(LIB)  (Pointer[GumboStringPiece] $text) { * }
sub gumbo_vector_index_of is native(LIB) returns int32 (Pointer[GumboVector] $vector, Pointer $element) { * }
sub gumbo_tagn_enum is native(LIB) returns int32 (Str $tagname, uint32 $length) { * }
sub gumbo_destroy_output is native(LIB)  (Pointer[GumboInternalOptions] $options, Pointer[GumboInternalOutput] $output) { * }
sub gumbo_string_equals is native(LIB) returns bool (Pointer[GumboStringPiece] $str1, Pointer[GumboStringPiece] $str2) { * }
sub gumbo_normalize_svg_tagname is native(LIB) returns Str (Pointer[GumboStringPiece] $tagname) { * }
sub gumbo_parse_with_options is native(LIB) returns Pointer[GumboInternalOutput] (Pointer[GumboInternalOptions] $options, Str $buffer, size_t $buffer_length) { * }
sub gumbo_tag_enum is native(LIB) returns int32 (Str $tagname) { * }
class GumboAttribute is repr('CStruct') is export {
        has int32       $.attr_namespace;
        has Str $.name;
        HAS GumboStringPiece    $.original_name;
        has Str $.value;
        HAS GumboStringPiece    $.original_value;
        HAS GumboSourcePosition $.name_start;
        HAS GumboSourcePosition $.name_end;
        HAS GumboSourcePosition $.value_start;
        HAS GumboSourcePosition $.value_end;
}
class GumboInternalNode is repr('CStruct') is export {
        has int32       $.type;
        has Pointer[GumboInternalNode]  $.parent;
        has size_t      $.index_within_parent;
        has int32       $.parse_flags;
        HAS GumboInternalNode_v_Union   $.v;
}
class GumboText is repr('CStruct') is export {
        has Str $.text;
        HAS GumboStringPiece    $.original_text;
        HAS GumboSourcePosition $.start_pos;
}
class GumboInternalOptions is repr('CStruct') is export {
        has Pointer[PtrFunc]    $.allocator;
        has Pointer[PtrFunc]    $.deallocator;
        has Pointer     $.userdata;
        has int32       $.tab_stop;
        has bool        $.stop_on_first_error;
        has int32       $.max_errors;
        has int32       $.fragment_context;
        has int32       $.fragment_namespace;
}
class GumboDocument is repr('CStruct') is export {
        HAS GumboVector $.children;
        has bool        $.has_doctype;
        has Str $.name;
        has Str $.public_identifier;
        has Str $.system_identifier;
        has int32       $.doc_type_quirks_mode;
}
class GumboInternalOutput is repr('CStruct') is export {
        has Pointer[GumboInternalNode]  $.document;
        has Pointer[GumboInternalNode]  $.root;
        HAS GumboVector $.errors;
}
class GumboInternalNode_v_Union is repr('CUnion') is export {
        HAS GumboDocument       document;
        HAS GumboElement        element;
        HAS GumboText   text;
}
class GumboStringPiece is repr('CStruct') is export {
        has Str $.data;
        has size_t      $.length;
}
class GumboSourcePosition is repr('CStruct') is export {
        has uint32      $.line;
        has uint32      $.column;
        has uint32      $.offset;
}
class GumboVector is repr('CStruct') is export {
        has Pointer[Pointer]    $.data;
        has uint32      $.length;
        has uint32      $.capacity;
}
class GumboElement is repr('CStruct') is export {
        HAS GumboVector $.children;
        has int32       $.tag;
        has int32       $.tag_namespace;
        HAS GumboStringPiece    $.original_tag;
        HAS GumboStringPiece    $.original_end_tag;
        HAS GumboSourcePosition $.start_pos;
        HAS GumboSourcePosition $.end_pos;
        HAS GumboVector $.attributes;
}

```


