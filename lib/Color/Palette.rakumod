unit class Color::Palette;

use Color;

class NamedColor {
  has Str $.name is rw;
  has Color:D $.color is rw is required;
}

has NamedColor @.colors is rw;
has Str $.name is rw;
has Int $.columns is rw;


method add-color(Color $color, Str $name?) {
  $.colors.push: NamedColor.new(:$color, :$name);
}


method sort(:$by where any(<rgb hsv name>), :$reverse) {
  my &cmp = do given $by {
    when 'rgb' {
      -> $a, $b {
        ($a.color.rgb[0] leg $b.color.rgb[0])
        ||
        ($a.color.rgb[1] leg $b.color.rgb[1])
        ||
        ($a.color.rgb[2] leg $b.color.rgb[2])
      }
    }

    when 'hsv' {
      -> $a, $b {
        ($a.color.hsv[0] leg $b.color.hsv[0])
        ||
        ($a.color.hsv[1] leg $b.color.hsv[1])
        ||
        ($a.color.hsv[2] leg $b.color.hsv[2])
      }
    }

    when 'name' {
      -> $a, $b {
        ($a.name // '') cmp ($b.name // '')
      }
    }

    # TODO: Add more advanced color sorting methods from
    # https://www.alanzucconi.com/2015/09/30/colour-sorting/
  }

  my @sorted = @.colors.sort(&cmp);

  @sorted.=reverse if $reverse;

  return $.clone(:colors(@sorted));
}


method unique(:$by where any(<name color>) = 'color') {
  my &as = do given $by {
    when 'name' { *.name }
    when 'color' { *.color.Str }
  };

  return $.clone(:colors(@.colors.unique(:&as)));
}


our sub from-gpl(Str:D $input) {
  grammar GPL {
    token TOP { ^ <magic> \n [ <head-name> ]?  [ <head-columns> ]? <lines> $ }
    token head-name { "Name: " <name> \n }
    token head-columns { "Columns: " <value> \n }
    token magic { "GIMP Palette" }
    token name { \V+ }
    token value { \d+ }
    token empty { ^^ $$ }
    token color { <rgb> [ \h+ <name> ]? }
    token comment { ^^ '#' \V* }
    token rgb { <value> \h+ <value> \h+ <value> }
    token lines { <line>* %% "\n" }
    token line { <color> | <comment> | <empty> }
  }

  my $match = GPL.parse($input);

  with $match {
    my $palette = Color::Palette.new;

    $palette.name = ~.<name> with $match<head-name>;
    $palette.columns = +.<value> with $match<head-columns>;

    for $match<lines>.caps {
      with .<line><color> {
        my $color = Color.new: |.<rgb>.caps.map(*.value.Int);
        my $name = .<name> ?? ~.<name> !! Str:U;
        $palette.add-color: $color, $name;
      }
    }

    return $palette;
  }
  else {
    fail 'Failed to parse GPL/invalid GPL format.';
  }
}


method to-gpl {
  my $gpl = "GIMP Palette\nName: " ~ ($.name // '') ~ "\n";

  $gpl ~= "Columns: $_\n" with $.columns;

  for @.colors {
    $gpl ~= ~.color.rgb;
    $gpl ~= " $_" with .name;
    $gpl ~= "\n";
  }

  return $gpl;
}


=begin pod

=head1 NAME

Color::Palette

=head1 SYNOPSIS

=begin code :lang<raku>

use Color::Palette;
use Color;

my $palette = Color::Palette::from-gpl('pantone.gpl'.IO.slurp);

$palette.add-color(Color.new(0, 0, 0), 'Black');
$palette.add-color(Color.new(255, 0, 0));
$palette.=sort(:by<hsv>);
$palette.=unique(:by<color>);
$palette.name = 'Lots of Colors';
$palette.columns = 5;

say $palette.to-gpl;

=end code

=head1 DESCRIPTION

Module for working with color palettes. Currently supports:

=item parsing and generating GPL (GIMP Palette format v2)
=item naive sorting by RGB or HSV values

Todo:

=item support more color palette file formats
=item implement fancier sorting algorithms, see L<https://www.alanzucconi.com/2015/09/30/colour-sorting/>


=head1 ATTRIBUTES

=head2 C<<@colors>>

Array of C<<NamedColor>> objects. C<<NamedColor>> is a simple class that holds
a C<<Color>> and an optional color name.

=head2 C<<$name>>

Optional name of the color palette.

=head2 C<<$columns>>

Specifies the number of columns to display the palette on in GIMP (only
relevant when generating GPL files for use in GIMP).


=head1 METHODS / SUBS

=head2 C<<::from-gpl(Str:D $input)>>

=begin code :lang<raku>

my $palette = Color::Palette::from-gpl('palette.gpl'.IO.slurp);

=end code

Creates and returns a C<<Color::Palette>> object with the contents parsed from
the given input string in GPL format.

=head2 C<<.to-gpl>>

Returns a string with the palette in GPL format.

=head2 C<<.add-color(Color $color, Str $name?)>>

=begin code :lang<raku>

$palette.add-color(Color.new(0, 0, 0), 'Black');
$palette.add-color(Color.new(255, 0, 0));

=end code

Adds a color with an optional color name to the palette.


=head2 C<<.sort(Str :$by)>>

=begin code :lang<raku>

$palette.=sort(:by<hsv>, :reverse);

=end code

Returns a copy of the palette with the colors sorted using the
algorithm/criteria. Currently supported:

=item C<<rgb>> sorts by the RGB values of the color.
=item C<<hsv>> sorts by the HSV values of the color.
=item C<<name>> sorts the colors by name.

C<<:reverse>> reverses the order of the colors after sorting.


=head2 C<<.unique(:by<color>)>>

=begin code :lang<raku>

$palette.=unique(:by<color>);

=end code

Returns a copy of the palette with duplicate colors removed. C<<color>> detects
duplicates by comparing the RGB values of the color, C<<name>> checks for
duplicate names.


=head1 SEE ALSO

=item L<GIMP Palette Format Version 2 (.gpl)|https://developer.gimp.org/core/standards/gpl/>

=item L<The incredibly challenging task of sorting colours|https://www.alanzucconi.com/2015/09/30/colour-sorting/>


=head1 AUTHOR

Jonas Kramer <jkramer@mark17.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Jonas Kramer

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
