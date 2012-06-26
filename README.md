# Morris.js - pretty time-series line graphs

[![Build Status](https://secure.travis-ci.org/oesmith/morris.js.png?branch=master)](http://travis-ci.org/oesmith/morris.js)

Morris.js is the library that powers the graphs on http://howmanyleft.co.uk/.

It's a bit rough around the edges, but it's getting pretty usable now.  Expect it to get even better soon.

Cheers!

\- Olly

## Requirements

- [jQuery](http://jquery.com/) (>= 1.7 recommended, but it'll probably work with older versions)
- [Raphael.js](http://raphaeljs.com/) (>= 2.0)

## Usage

See [the website](http://oesmith.github.com/morris.js/).

## Development

Very daring.

Fork, hack, possibly even add some tests, then send a pull request :)

### Developer quick-start

You'll need [node.js](https://nodejs.org).  I recommend using
[nvm](https://github.com/creationix/nvm) for installing node in
development environments.

With node installed, install [grunt](https://github.com/cowboy/grunt) using
`npm install -g grunt`, and then the rest of the test/build dependencies
with `npm install` in the morris.js project folder.

Once you're all set up, you can compile, minify and run the tests using `grunt`.

## Changelog

### 0.2.10 - 26th June 2012

- Support for decimal labels on y-axis [#58](https://github.com/oesmith/morris.js/issues/58).
- Better axis label clipping [#63](https://github.com/oesmith/morris.js/issues/63).
- Redraw graphs with updated data using `setData` method [#64](https://github.com/oesmith/morris.js/issues/64).
- Bugfix: series with zero or one non-null values [#65](https://github.com/oesmith/morris.js/issues/65).

### 0.2.9 - 15th May 2012

- Bugfix: Fix zero-value regression
- Bugfix: Don't modify user-supplied data

### 0.2.8 - 10th May 2012

- Customising x-axis labels with `xLabelFormat` option
- Only use timezones when timezone info is specified
- Fix old IE bugs (mostly in examples!)
- Added `preunits` and `postunits` options
- Better non-continuous series data support

### 0.2.7 - 2nd April 2012

- Added `xLabels` option
- Refactored x-axis labelling
- Better ISO date support
- Fix bug with single value in non time-series graphs

### 0.2.6 - 18th March 2012

- Partial series support (see `null` y-values in `examples/quarters.html`)
- `parseTime` option bugfix for non-time-series data

### 0.2.5 - 15th March 2012

- Raw millisecond timestamp support (with `dateFormat` option)
- YYYY-MM-DD HH:MM[:SS[.SSS]] date support
- Decimal number labels

### 0.2.4 - 8th March 2012

- Negative y-values support
- `ymin` option
- `units` options

### 0.2.3 - 6th Mar 2012

- jQuery no-conflict compatibility
- Support ISO week-number dates
- Optionally hide hover on mouseout (`hideHover`)
- Optionally skip parsing dates, treating X values as an equally-spaced series (`parseTime`)

### 0.2.2 - 29th Feb 2012

- Bugfix: mouseover error when options.data.length == 2
- Automatically sort options.data

### 0.2.1 - 28th Feb 2012

- Accept a DOM element *or* an ID in `options.element`
- Add `smooth` option
- Bugfix: clone `@default`
- Add `ymax` option

## License

Copyright (c) 2012, Olly Smith
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
