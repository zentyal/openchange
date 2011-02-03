#!/usr/bin/perl -w

###################################################
# package to parse the mapi-properties files and 
# generate code for libmapi in OpenChange
#
# Perl code based on pidl one from Andrew Tridgell and the Samba team
#
# Copyright (C) Julien Kerihuel 2005-2011
# released under the GNU GPL

use strict;
use Getopt::Long;

my $ret = "";
my $tabs = "";

sub indent() { $tabs.="\t"; }
sub deindent() { $tabs = substr($tabs, 1); }
sub mparse($) { $ret .= $tabs.(shift)."\n"; }

my($opt_outputdir) = '.';
my($opt_parser) = '';

my	%prop_types = (
    0x0		=> "PT_UNSPECIFIED",
    0x1		=> "PT_NULL",
    0x2		=> "PT_SHORT",
    0x3		=> "PT_LONG",
    0x4		=> "PT_FLOAT",
    0x5		=> "PT_DOUBLE",
    0x6		=> "PT_CURRENCY",
    0x7		=> "PT_APPTIME",
    0xa		=> "PT_ERROR",
    0xb		=> "PT_BOOLEAN",
    0xd		=> "PT_OBJECT",
    0x14	=> "PT_I8",
    0x1e	=> "PT_STRING8",
    0x1f	=> "PT_UNICODE",
    0x40	=> "PT_SYSTIME",
    0x48	=> "PT_CLSID",
    0xFB	=> "PT_SVREID",
    0xFD	=> "PT_SRESTRICT",
    0xFE	=> "PT_ACTIONS",
    0x102	=> "PT_BINARY",
# Multi-valued property types
    0x1002	=> "PT_MV_SHORT",
    0x1003	=> "PT_MV_LONG",
    0x1004	=> "PT_MV_FLOAT",
    0x1005	=> "PT_MV_DOUBLE",
    0x1006	=> "PT_MV_CURRENCY",
    0x1007	=> "PT_MV_APPTIME",
    0x1014	=> "PT_MV_I8",
    0x101e	=> "PT_MV_STRING8",
    0x101f	=> "PT_MV_UNICODE",
    0x1040	=> "PT_MV_SYSTIME",
    0x1048	=> "PT_MV_CLSID",
    0x1102	=> "PT_MV_BINARY"
);

my	%prop_names = (
    "PT_UNSPECIFIED"	=>	0x0,
    "PT_NULL"		=>	0x1,
    "PT_SHORT"		=>	0x2,
    "PT_LONG"		=>	0x3,
    "PT_FLOAT"		=>	0x4,
    "PT_DOUBLE"		=>	0x5,
    "PT_CURRENCY"	=>	0x6,
    "PT_APPTIME"	=>	0x7,
    "PT_ERROR"		=>	0xa,
    "PT_BOOLEAN"	=>	0xb,
    "PT_OBJECT"		=>	0xd,
    "PT_I8"		=>	0x14,
    "PT_STRING8"	=>	0x1e,
    "PT_UNICODE"	=>	0x1f,
    "PT_SYSTIME"	=>	0x40,
    "PT_CLSID"		=>	0x48,
    "PT_SVREID"		=>	0xfb,
    "PT_SRESTRICT"	=>	0xfd,
    "PT_ACTIONS"	=>	0xfe,
    "PT_BINARY"		=>	0x102,
# Multi-valued property types
    "PT_MV_SHORT"	=>	0x1002,
    "PT_MV_LONG"	=>	0x1003,
    "PT_MV_FLOAT"	=>	0x1004,
    "PT_MV_DOUBLE"	=>	0x1005,
    "PT_MV_CURRENCY"	=>	0x1006,
    "PT_MV_APPTIME"	=>	0x1007,
    "PT_MV_I8"		=>	0x1014,
    "PT_MV_STRING8"	=>	0x101e,
    "PT_MV_UNICODE"	=>	0x101f,
    "PT_MV_SYSTIME"	=>	0x1040,
    "PT_MV_CLSID"	=>	0x1048,
    "PT_MV_BINARY"	=>	0x1102
);

my	%oleguid = (
    "PSETID_Appointment"	=>	"00062002-0000-0000-c000-000000000046",
    "PSETID_Task"		=>	"00062003-0000-0000-c000-000000000046",
    "PSETID_Address"		=>	"00062004-0000-0000-c000-000000000046",
    "PSETID_Common"		=>	"00062008-0000-0000-c000-000000000046",
    "PSETID_Note"		=>	"0006200e-0000-0000-c000-000000000046",
    "PSETID_Log"		=>	"0006200a-0000-0000-c000-000000000046",
    "PSETID_Sharing"		=>	"00062040-0000-0000-c000-000000000046",
    "PSETID_PostRss"		=>	"00062041-0000-0000-c000-000000000046",
    "PSETID_UnifiedMessaging"	=>	"4442858e-a9e3-4e80-b900-317a210cc15b",
    "PSETID_Meeting"		=>	"6ed8da90-450b-101b-98da-00aa003f1305",
    "PSETID_AirSync"		=>	"71035549-0739-4dcb-9163-00f0580dbbdf",
    "PSETID_Messaging"		=>	"41f28f13-83f4-4114-a584-eedb5a6b0bff",
    "PSETID_Attachment"		=>	"96357f7f-59e1-47d0-99a7-46515c183b54",
    "PSETID_CalendarAssistant"	=>	"11000e07-b51b-40d6-Af21-caa85edab1d0",
    "PS_PUBLIC_STRINGS"		=>	"00020329-0000-0000-c000-000000000046",
    "PS_INTERNET_HEADERS"	=>	"00020386-0000-0000-c000-000000000046",
    "PS_MAPI"			=>	"00020328-0000-0000-c000-000000000046",
    "PSETID_Remote"		=>	"00062014-0000-0000-c000-000000000046"
);

# main program

my $result = GetOptions (
			 'outputdir=s' => \$opt_outputdir,
			 'parser=s' => \$opt_parser
			 );

if (not $result) {
    exit(1);
}

#####################################################################
# read a file into a string
sub FileLoad($)
{
    my($filename) = shift;
    local(*INPUTFILE);
    open(INPUTFILE, $filename) || return undef;
    my($saved_delim) = $/;
    undef $/;
    my($data) = <INPUTFILE>;
    close(INPUTFILE);
    $/ = $saved_delim;
    return $data;
}

#####################################################################
# write a string into a file
sub FileSave($$)
{
    my($filename) = shift;
    my($v) = shift;
    local(*FILE);
    open(FILE, ">$filename") || die "can't open $filename";    
    print FILE $v;
    close(FILE);
}

#####################################################################
# generate mapicode.c file

sub mapicodes_interface($)
{
    my $contents = shift;
    my $line;
    my @lines;
    my @errors;

    mparse "/* parser auto-generated by mparse */";
    mparse "#include \"libmapi/libmapi.h\"";
    mparse "#include \"libmapi/libmapi_private.h\"";
    mparse "#include \"gen_ndr/ndr_exchange.h\"";
    mparse "";
    mparse "void set_errno(enum MAPISTATUS status)";
    mparse "{";
    indent;
    mparse "errno = status;";
    deindent;
    mparse "}";
    mparse "";
    mparse "struct mapi_retval {";
    indent;
    mparse "enum MAPISTATUS		err;";
    mparse "const char		*name;";
    deindent;
    mparse "};";
    mparse "";
    mparse "static const struct mapi_retval mapi_retval[] = {";
    indent;

    @lines = split(/\n/, $contents);
    foreach $line (@lines) {
	$line =~ s/^\#+.*$//;
	if ($line) {
	    @errors = split(/\s+/, $line);
	    mparse sprintf "{ %8s, \"%s\" },", $errors[1], $errors[1];
	}
    }


    mparse " { MAPI_E_RESERVED, NULL }";
    deindent;
    mparse "};";
    mparse "";
    mparse "_PUBLIC_ void mapi_errstr(const char *function, enum MAPISTATUS mapi_code)";
    mparse "{";
    indent;
    mparse "struct ndr_print	ndr_print;";
    mparse "";
    mparse "ndr_print.depth = 1;";
    mparse "ndr_print.print = ndr_print_debug_helper;";
    mparse "ndr_print.no_newline = false;";
    mparse "ndr_print_MAPISTATUS(&ndr_print, function, mapi_code);";
    deindent;
    mparse "}";
    mparse "";
    mparse "_PUBLIC_ const char *mapi_get_errstr(enum MAPISTATUS mapi_code)";
    mparse "{";
    indent;
    mparse "uint32_t i;";
    mparse "";
    mparse "for (i = 0; mapi_retval[i].name; i++) {";
    indent;
    mparse "if (mapi_retval[i].err == mapi_code) {";
    indent;
    mparse "return mapi_retval[i].name;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return NULL;";
    deindent;
    mparse "}";
}

#####################################################################
# generate mapicodes_enum.idl file
sub mapicodes_enum($)
{
    my $contents = shift;
    my $line;
    my @lines;
    my @prop;
    my $prop_type;

    mparse "/* parser auto-generated by mparse */";
    mparse "";

    mparse "typedef [public, v1_enum, flag(NDR_PAHEX)] enum {";
    indent;
    
    @lines = split(/\n/, $contents);
    foreach $line (@lines) {
	$line =~ s/^\#+.*$//;
	if ($line) {
	    @prop = split(/\s+/, $line);
	    mparse sprintf "%-51s = %s,", $prop[1], $prop[0];
	}
    }
    mparse sprintf "%-51s = %s", "MAPI_E_RESERVED", "0xFFFFFFFF";
    deindent;
    mparse "} MAPISTATUS;";    
    mparse "";
    
    return $ret;
}

#####################################################################
# generate openchangedb_property.c file
sub openchangedb_property($)
{
    my $contents = shift;
    my $line;
    my @lines;
    my @prop;
    my $prop_type;
    my $prop_value;
    my $pidtag;

    mparse "/* parser auto-generated by mparse */";
    mparse "#include \"mapiproxy/dcesrv_mapiproxy.h\"";
    mparse "#include \"libmapiproxy.h\"";
    mparse "#include \"libmapi/libmapi.h\"";
    mparse "#include \"libmapi/libmapi_private.h\"";
    mparse "";
    mparse "struct pidtags {";
    mparse "	uint32_t	proptag;";
    mparse "	const char	*pidtag;";
    mparse "};";
    mparse "";
    mparse "static struct pidtags pidtags[] = {";
    indent;
    
    @lines = split(/\n/, $contents);
    foreach $line (@lines) {
	$line =~ s/^\#+.*$//;
	if ($line) {
	    @prop = split(/\s+/, $line);
	    $prop_type = hex $prop[0];
	    $prop_type &= 0xFFFF;
	    $prop_value = hex $prop[0];
	    $prop_value = ($prop_value >> 16) & 0xFFFF;
	    if ($prop_types{$prop_type}) {
		if ($prop[2]) {
		    mparse sprintf "{ %-51s, \"%s\"},", $prop[1], $prop[2];
		} else {
		    mparse sprintf "{ %-51s, \"0x%.8x\"},", $prop[1], hex $prop[0];
		}

		if (($prop_type == 0x1e) ||  ($prop_type == 0x101e)) {
		    if ($prop[2]) {
			mparse sprintf "{ %-51s, \"%s\"},", "$prop[1]_UNICODE", $prop[2];
		    } else {
			mparse sprintf "{ %-51s, \"0x%.8x\"},", "$prop[1]_UNICODE", hex $prop[0];
		    }
		}
	    }
	}
    }

    mparse sprintf "{ %-51s, NULL }", 0;
    deindent;
    mparse "};";
    mparse "";
    mparse "_PUBLIC_ const char *openchangedb_property_get_attribute(uint32_t proptag)";
    mparse "{";
    indent;
    mparse "uint32_t i;";
    mparse "";
    mparse "for (i = 0; pidtags[i].pidtag; i++) {";
    indent;
    mparse "if (pidtags[i].proptag == proptag) {";
    indent;
    mparse "return pidtags[i].pidtag;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "DEBUG(0, (\"[%s:%d]: Unsupported property tag '0x%.8x'\\n\", __FUNCTION__, __LINE__, proptag));";
    mparse "";
    mparse "return NULL;";
    deindent;
    mparse "}";
}

#####################################################################
# generate codepage_lcid.c file
sub codepage_lcid_interface($)
{
    my $contents = shift;
    my $line;
    my @lines;
    my @params;
    my $locale;

    mparse "/* parser auto-generated by mparse */";
    mparse "#include \"libmapi/libmapi.h\"";
    mparse "#include \"libmapi/libmapi_private.h\"";
    mparse "#include <locale.h>";
    mparse "#include <langinfo.h>";
    mparse "";
    mparse "/**";
    mparse "  \\file codepage_lcid.c";
    mparse "";
    mparse "  \\brief Codepage and Locale ID operations";
    mparse " */";
    mparse "";

    # Step 1. Generate code for defines
    @lines = split(/\n/, $contents);
    foreach $line (@lines) {
	$line =~ s/^\#+.*$//;
	if ($line) {
	    @params = split(/\s+/, $line);
	    if ($params[0] eq "DEFINE") {
		mparse sprintf "#define	%-30s %15d", $params[1], $params[2];
	    }
	}
    }

## We do not have yet convenient functions making use of this struct. This causes warning
#    mparse "";
#    mparse "static const char *language_group[] =";
#    mparse "{";
#    indent;
#    foreach $line (@lines) {
#	$line =~ s/^\#+.*$//;
#	if ($line) {
#	    @params = split(/\s+/, $line);
#	    if ($params[0] eq "DEFINE") {
#		mparse sprintf "\"%s\",", $params[1];
#	    }
#	}
#    }
#    mparse "NULL";
#    deindent;
#    mparse "};";
#    mparse "";

    # Step 2. Generate the locales array
    mparse "struct cpid_lcid {";
    indent;
    mparse "const char	*language;";
    mparse "const char	*locale;";
    mparse "uint32_t	lcid;";
    mparse "uint32_t	cpid;";
    mparse "uint32_t	language_group;";
    deindent;
    mparse "};";
    mparse "";

    mparse "static const struct cpid_lcid locales[] =";
    mparse "{";
    indent;

    foreach $line (@lines) {
	$line =~ s/^\#+.*$//;
	if ($line) {
	    @params = split(/\s+/, $line);
	    if ($params[0] ne "DEFINE") {

		$params[0] = ($params[1] eq "NULL") ? (sprintf "\"%s\",", $params[0]) : 
		    (sprintf "\"%s (%s)\",", $params[0], $params[1]);
		$params[0] =~ s/_/ /g;
		$params[2] = sprintf "\"%s\",", $params[2];
		mparse sprintf "{ %-32s %-18s %-6s, %-4s, %-24s },", 
		$params[0], $params[2], $params[3], $params[4], $params[5];		    
	    }
	}
    }

    mparse "{ NULL, NULL, 0, 0, 0 }";
    deindent;
    mparse "};";
    mparse "";

    # mapi_get_system_locale
    mparse "/**";
    mparse "  \\details Returns current locale used by the system";
    mparse "";
    mparse " \\return pointer to locale string on success, otherwise NULL";
    mparse " */";
    mparse "_PUBLIC_ char *mapi_get_system_locale(void)";
    mparse "{";
    indent;
    mparse "char	*locale;";
    mparse "";
    mparse "locale = setlocale(LC_CTYPE, \"\");";
    mparse "return locale;";
    deindent;
    mparse "}";
    mparse "";   

    # mapi_verify_cpid
    mparse "/**";
    mparse "  \\details Verify if the specified codepage is valid";
    mparse "";
    mparse "  \\param cpid the codepage to lookup";
    mparse "";
    mparse "  \\return 0 on success, otherwise 1";
    mparse " */";
    mparse "_PUBLIC_ bool mapi_verify_cpid(uint32_t cpid)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "for (i = 0; locales[i].lcid; i++) {";
    indent;
    mparse "if (cpid == locales[i].cpid) {";
    indent;
    mparse "return true;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return false;";
    deindent;
    mparse "}";
    mparse "";   

    # mapi_get_cpid_from_lcid
    mparse "/**";
    mparse "  \\details Returns codepage for a given LCID (Locale ID)";
    mparse "";
    mparse "  \\param lcid the locale ID to lookup";
    mparse "";
    mparse "  \\return non-zero codepage on success, otherwise 0 if";
    mparse "   only unicode is supported for this language";
    mparse " */";
    mparse "_PUBLIC_ uint32_t mapi_get_cpid_from_lcid(uint32_t lcid)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "for (i = 0; locales[i].lcid; i++) {";
    indent;
    mparse "if (lcid == locales[i].lcid) {";
    indent;
    mparse "return locales[i].cpid;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return 0;";
    deindent;
    mparse "}";
    mparse "";

    # mapi_get_cpid_from_locale
    mparse "/**";
    mparse "  \\details Return codepage associated to specified locale";
    mparse "";
    mparse "  \\param locale The locale string to lookup";
    mparse "";
    mparse "  \\return non-zero codepage on success, otherwise 0";
    mparse " */";
    mparse "_PUBLIC_ uint32_t mapi_get_cpid_from_locale(const char *locale)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "/* Sanity Checks */";
    mparse "if (!locale) return 0;";
    mparse "";
    mparse "for (i = 0; locales[i].locale; i++) {";
    indent;
    mparse "if (locales[i].locale && !strncmp(locales[i].locale, locale, strlen(locales[i].locale))) {";
    indent;
    mparse "return locales[i].cpid;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return 0;";
    deindent;
    mparse "}";
    mparse "";

    # mapi_get_cpid_from_language
    mparse "/**";
    mparse "  \\details Return codepage associated to specified language";
    mparse "";
    mparse "  \\param language The language string to lookup";
    mparse "";
    mparse "  \\return non-zero codepage on success, otherwise 0";
    mparse " */";
    mparse "_PUBLIC_ uint32_t mapi_get_cpid_from_language(const char *language)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "/* Sanity Checks */";
    mparse "if (!language) return 0;";
    mparse "";
    mparse "for (i = 0; locales[i].language; i++) {";
    indent;
    mparse "if (locales[i].language && !strncmp(locales[i].language, language, strlen(locales[i].language))) {";
    indent;
    mparse "return locales[i].cpid;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return 0;";
    deindent;
    mparse "}";
    mparse "";

    # mapi_get_lcid_from_locale
    mparse "/**";
    mparse "  \\details Returns LCID (Locale ID) for a given locale";
    mparse "";
    mparse "  \\param locale the locale string to lookup";
    mparse "";
    mparse "  \\return non-zero LCID on success, otherwise 0";
    mparse " */";
    mparse "_PUBLIC_ uint32_t mapi_get_lcid_from_locale(const char *locale)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "/* Sanity Checks */";
    mparse "if (!locale) return 0;";
    mparse "";
    mparse "for (i = 0; locales[i].locale; i++) {";
    indent;
    mparse "if (locales[i].locale && !strncmp(locales[i].locale, locale, strlen(locales[i].locale))) {";
    indent;
    mparse "return locales[i].lcid;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return 0;";
    deindent;
    mparse "}";
    mparse "";

    # mapi_get_lcid_from_language
    mparse "/**";
    mparse "  \\details Returns LCID (Locale ID) for a given language";
    mparse "";
    mparse "  \\param language the language string to lookup";
    mparse "";
    mparse "  \\return non-zero LCID on success, otherwise 0";
    mparse " */";
    mparse "_PUBLIC_ uint32_t mapi_get_lcid_from_language(const char *language)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "/* Sanity Checks */";
    mparse "if (!language) return 0;";
    mparse "";
    mparse "for (i = 0; locales[i].language; i++) {";
    indent;
    mparse "if (locales[i].language && !strncmp(locales[i].language, language, strlen(locales[i].language))) {";
    indent;
    mparse "return locales[i].lcid;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return 0;";
    deindent;
    mparse "}";
    mparse "";

    # mapi_get_locale_from_lcid
    mparse "/**";
    mparse "  \\details Returns Locale for a given Locale ID";
    mparse "";
    mparse "  \\param lcid the locale ID to lookup";
    mparse "";
    mparse "  \\return locale string on success, otherwise NULL";
    mparse " */";
    mparse "_PUBLIC_ const char *mapi_get_locale_from_lcid(uint32_t lcid)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "for (i = 0; locales[i].lcid; i++) {";
    indent;
    mparse "if (locales[i].lcid == lcid) {";
    indent;
    mparse "return locales[i].locale;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return NULL;";
    deindent;
    mparse "}";
    mparse "";

    # mapi_get_locale_from_language
    mparse "/**";
    mparse "  \\details Returns Locale for a given language";
    mparse "";
    mparse "  \\param language the language string to lookup";
    mparse "";
    mparse "  \\return Locale string on success, otherwise NULL";
    mparse " */";
    mparse "_PUBLIC_ const char *mapi_get_locale_from_language(const char *language)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "/* Sanity Checks */";
    mparse "if (!language) return NULL;";
    mparse "";
    mparse "for (i = 0; locales[i].language; i++) {";
    indent;
    mparse "if (locales[i].language && !strncmp(locales[i].language, language, strlen(locales[i].language))) {";
    indent;
    mparse "return locales[i].locale;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return NULL;";
    deindent;
    mparse "}";
    mparse "";

    # mapi_get_language_from_locale
       mparse "/**";
    mparse "  \\details Returns Language for a given Locale";
    mparse "";
    mparse "  \\param locale the language string to lookup";
    mparse "";
    mparse "  \\return Language string on success, otherwise NULL";
    mparse " */";
    mparse "_PUBLIC_ const char *mapi_get_language_from_locale(const char *locale)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "/* Sanity Checks */";
    mparse "if (!locale) return NULL;";
    mparse "";
    mparse "for (i = 0; locales[i].locale; i++) {";
    indent;
    mparse "if (locales[i].locale && !strncmp(locales[i].locale, locale, strlen(locales[i].locale))) {";
    indent;
    mparse "return locales[i].language;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return NULL;";
    deindent;
    mparse "}";
    mparse "";
 
    # mapi_get_language_from_lcid
    mparse "/**";
    mparse "  \\details Returns Language for a given Locale ID";
    mparse "";
    mparse "  \\param lcid the locale ID to lookup";
    mparse "";
    mparse "  \\return language string on success, otherwise NULL";
    mparse " */";
    mparse "_PUBLIC_ const char *mapi_get_language_from_lcid(uint32_t lcid)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "for (i = 0; locales[i].lcid; i++) {";
    indent;
    mparse "if (locales[i].lcid == lcid) {";
    indent;
    mparse "return locales[i].language;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "return NULL;";
    deindent;
    mparse "}";
    mparse "";

    # mapi_get_language_by_group
        mparse "/**";
    mparse "  \\details Returns List of languages for a given Language Group";
    mparse "";
    mparse "  \\param mem_ctx pointer to the memory context";
    mparse "  \\param group the locale group to lookup";
    mparse "";
    mparse "  \\return Array of languages string on success, otherwise NULL";
    mparse " */";
    mparse "_PUBLIC_ char **mapi_get_language_from_group(TALLOC_CTX *mem_ctx, uint32_t group)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "uint32_t	counter = 0;";
    mparse "char		**languages;";
    mparse "";
    mparse "/* Sanity Checks */";
    mparse "if (!mem_ctx) return NULL;";
    mparse "";
    mparse "languages = talloc_array(mem_ctx, char *, counter + 1);";
    mparse "for (i = 0; locales[i].language; i++) {";
    indent;
    mparse "if (locales[i].language_group == group) {";
    indent;
    mparse "languages = talloc_realloc(mem_ctx, languages, char *, counter + 1);";
    mparse "languages[counter] = talloc_strdup(languages, locales[i].language);";
    mparse "counter += 1;";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
    mparse "";
    mparse "if (!counter) {";
    indent;
    mparse "talloc_free(languages);";
    mparse "return NULL;";
    deindent;
    mparse "}";
    mparse "";
    mparse "return languages;";
    deindent;
    mparse "}";
    mparse "";

    # assessor for mapidump_get_languages
    mparse "void mapi_get_language_list(void)";
    mparse "{";
    indent;
    mparse "uint32_t	i;";
    mparse "";
    mparse "for (i = 0; locales[i].language; i++) {";
    indent;
    mparse "printf(\"%s\\n\", locales[i].language);";
    deindent;
    mparse "}";
    deindent;
    mparse "}";
}


#####################################################################
# generate OpenChange properties defines for Python
sub pymapi_properties($)
{
    my $contents = shift;
    my $line;
    my @lines;
    my @props;
    my $prop_type;

    mparse "/* parser auto-generated by mparse */";
    mparse "";
    mparse "#include <Python.h>";
    mparse "#include \"pyopenchange/pymapi.h\"";
    mparse "";
    mparse "int pymapi_add_properties(PyObject *m)";
    mparse "{";
    indent;

    @lines = split(/\n/, $contents);
    foreach $line (@lines) {
	$line =~ s/^\#+.*$//;
	if ($line) {
	    @props = split(/\s+/, $line);
	    $prop_type = hex $props[0];
	    $prop_type &= 0xFFFF;
	    mparse sprintf "PyModule_AddObject(m, \"%s\", PyInt_FromLong(%s));", $props[1], $props[0];
	    mparse sprintf "PyModule_AddObject(m, \"%s\", PyInt_FromLong(%s));", $props[2], $props[0] if ($props[2]);
	    if (($prop_type == 0x1e) || ($prop_type == 0x101e)) {
		$prop_type = hex $props[0];
		$prop_type++;
		mparse sprintf "PyModule_AddObject(m, \"%s\", PyInt_FromLong(0x%.8x));", "$props[1]_UNICODE", $prop_type;
	    }
	}

    }
    mparse "";
    mparse "return 0;";
    deindent;
    mparse "}";
}

sub process_file($)
{
    my $mapi_file = shift;
    my $outputdir = $opt_outputdir;

    print "Parsing $mapi_file\n";
    my $contents = FileLoad($mapi_file);
    defined $contents || return undef;

    if ($opt_parser eq "mapicodes") {
	print "Generating $outputdir" . "mapicode.c\n";
	$ret = '';
	my $code_parser = ("$outputdir/mapicode.c");
	FileSave($code_parser, mapicodes_interface($contents));

	print "Generating mapicodes_enum.h\n";
	$ret = '';
	my $enum_parser = ("mapicodes_enum.h");
	FileSave($enum_parser, mapicodes_enum($contents));
    }

    if ($opt_parser eq "codepage_lcid") {
	print "Generating $outputdir" . "codepage_lcid.c\n";
	$ret = '';
	my $code_parser = ("$outputdir/codepage_lcid.c");
	FileSave($code_parser, codepage_lcid_interface($contents));
    }

    if ($opt_parser eq "openchangedb_property") {
	print "Generating $outputdir" . "openchangedb_property.c\n";
	my $openchangedb_parser = ("$outputdir/openchangedb_property.c");
	FileSave($openchangedb_parser, openchangedb_property($contents));
    }

    if ($opt_parser eq "pymapi_properties") {
	print "Generating $outputdir" . "pymapi_properties.c\n";
	my $pymapi_parser = ("$outputdir/pymapi_properties.c");
	FileSave($pymapi_parser, pymapi_properties($contents));
    }
}

process_file($_) foreach (@ARGV);
