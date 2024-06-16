NAME
====

Color::Palette

SYNOPSIS
========

```raku
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
```

DESCRIPTION
===========

Module for working with color palettes. Currently supports:

  * parsing and generating GPL (GIMP Palette format v2)

  * naive sorting by RGB or HSV values

Todo:

  * support more color palette file formats

  * implement fancier sorting algorithms, see [https://www.alanzucconi.com/2015/09/30/colour-sorting/](https://www.alanzucconi.com/2015/09/30/colour-sorting/)

ATTRIBUTES
==========

`@colors`
---------

Array of `NamedColor` objects. `NamedColor` is a simple class that holds a `Color` and an optional color name.

`$name`
-------

Optional name of the color palette.

`$columns`
----------

Specifies the number of columns to display the palette on in GIMP (only relevant when generating GPL files for use in GIMP).

METHODS / SUBS
==============

`Color::Palette::from-gpl(Str:D $input)`
----------------------------------------

```raku
my $palette = ::from-gpl('palette.gpl'.IO.slurp);
```

Creates and returns a `Color::Palette` object with the contents parsed from the given input string in GPL format.

`.to-gpl`
---------

Returns a string with the palette in GPL format.

`.add-color(Color $color, Str $name?)`
--------------------------------------

```raku
$palette.add-color(Color.new(0, 0, 0), 'Black');
$palette.add-color(Color.new(255, 0, 0));
```

Adds a color with an optional color name to the palette.

`.sort(Str :$by)`
-----------------

```raku
$palette.=sort(:by<hsv>, :reverse);
```

Returns a copy of the palette with the colors sorted using the algorithm/criteria. Currently supported:

  * `rgb` sorts by the RGB values of the color.

  * `hsv` sorts by the HSV values of the color.

  * `name` sorts the colors by name.

`:reverse` reverses the order of the colors after sorting.

`.unique(:by<color>)`
---------------------

```raku
$palette.=unique(:by<color>);
```

Returns a copy of the palette with duplicate colors removed. `color` detects duplicates by comparing the RGB values of the color, `name` checks for duplicate names.

SEE ALSO
========

  * [GIMP Palette Format Version 2 (.gpl)](https://developer.gimp.org/core/standards/gpl/)

  * [The incredibly challenging task of sorting colours](https://www.alanzucconi.com/2015/09/30/colour-sorting/)

AUTHOR
======

Jonas Kramer <jkramer@mark17.net>

COPYRIGHT AND LICENSE
=====================

Copyright 2024 Jonas Kramer

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

