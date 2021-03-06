package Regexp::Stringify;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use re qw(regexp_pattern);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(stringify_regexp);

our %SPEC;

$SPEC{stringify_regexp} = {
    v => 1.1,
    summary => 'Stringify a Regexp object',
    description => <<'_',

This routine is an alternative to Perl's default stringification of Regexp
object (i.e.:`"$re"`) and has some features/options, e.g.: producing regexp
string that is compatible with certain perl versions.

If given a string (or other non-Regexp object), will return it as-is.

_
    args => {
        regexp => {
            schema => 're*',
            req => 1,
            pos => 0,
        },
        plver => {
            summary => 'Target perl version',
            schema => 'str*',
            description => <<'_',

Try to produce a regexp object compatible with a certain perl version (should at
least be >= 5.10).

For example, in perl 5.14 regex stringification changes, e.g. `qr/hlagh/i` would
previously be stringified as `(?i-xsm:hlagh)`, but now it's stringified as
`(?^i:hlagh)`. If you set `plver` to 5.10 or 5.12, then this routine will
still produce the former. It will also ignore regexp modifiers that are
introduced in newer perls.

Note that not all regexp objects are translatable to older perls, e.g. if they
contain constructs not known to older perls like `(?^...)` before perl 5.14.

_
        },
        with_qr => {
            schema  => 'bool',
            description => <<'_',

If you set this to 1, then `qr/a/i` will be stringified as `'qr/a/i'` instead as
`'(?^i:a)'`. The resulting string can then be eval-ed to recreate the Regexp
object.

_
        },
    },
    result_naked => 1,
    result => {
        schema => 'str*',
    },
};
sub stringify_regexp {
    my %args = @_;

    my $re = $args{regexp};
    return $re unless ref($re) eq 'Regexp';
    my $plver = $args{plver} // $^V;

    my ($pat, $mod) = regexp_pattern($re);

    my $ge_5140 = version->parse($plver) >= version->parse('5.14.0');
    unless ($ge_5140) {
        $mod =~ s/[adlu]//g;
    }

    if ($args{with_qr}) {
        return "qr($pat)$mod";
    } else {
        if ($ge_5140) {
            return "(^$mod:$pat)";
        } else {
            return "(?:(?$mod-)$pat)";
        }
    }
}

1;
# ABSTRACT:

=head1 SYNOPSIS

Assuming this runs on Perl 5.14 or newer.

 use Regexp::Stringify qw(stringify_regexp);
 $str = stringify_regexp(regexp=>qr/a/i);                       # '(^i:a)'
 $str = stringify_regexp(regexp=>qr/a/i, with_qr=>1);           # 'qr(a)i'
 $str = stringify_regexp(regexp=>qr/a/i, plver=>5.010);         # '(?:(?i-)a)'
 $str = stringify_regexp(regexp=>qr/a/ui, plver=>5.010);        # '(?:(?i-)a)'
