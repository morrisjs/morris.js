# Morris.js - pretty time-series line graphs

Morris.js is the library that powers the graphs on http://howmanyleft.co.uk/.

This is an early release.  It's a bit rough around the edges, but it's getting pretty usable now.  Expect it to get even better soon.

Cheers!

\- Olly

## Requirements

- [jQuery](http://jquery.com/) (>= 1.7 recommended, but it'll probably work with older versions)
- [Raphael.js](http://raphaeljs.com/) (>= 2.0)

## Usage

See [the website](http://oesmith.github.com/morris.js/).

## Development

Very daring.

Fork, hack, send a pull request :)

## Changelog

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
