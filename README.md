# Morris.js - pretty time-series line graphs

As morris.js project seems no more updated and as I have been asked many times to bring several changes to this plugin on my past but yet active projects, I decided to dig in it and add these requirements myself ^^

## Changelog

### 6th January 2018

- Combo Charts - Bar and Line together
- Right Y-axis [Issue #113](https://github.com/morrisjs/morris.js/issues/113)
- Pie chart type added
- Animation for every chart, based on [PR #62](https://github.com/morrisjs/morris.js/pull/62) for line chart and [PR #559](https://github.com/morrisjs/morris.js/pull/559) and for bar chart
- Labels for every chart, based on [PR #688](https://github.com/morrisjs/morris.js/pull/688)
- Orders of label in hover [Issue #534](https://github.com/morrisjs/morris.js/issues/534)
- Remove null values from computation of trend line
- Color scheme changed to Bootstrap 4's default theme

## To do
- Animation for donut chart
- Remove jQuery depency

## Requirements

- [jQuery](http://jquery.com/) (>= 1.7 recommended, but it'll probably work with
  older versions)
- [Raphael.js](http://raphaeljs.com/) (>= 2.0)

## Usage

See [the website](http://pierresh.github.com/morris.js/).

## Development

Very daring.

Fork, hack, possibly even add some tests, then send a pull request :)

Remember that Morris.js is a coffeescript project. Please make your changes in
the `.coffee` files, not in the compiled javascript files in the root directory
of the project.

### Developer quick-start

You'll need [node.js](https://nodejs.org).  I recommend using
[nvm](https://github.com/creationix/nvm) for installing node in
development environments.

With node installed, install [grunt](https://github.com/cowboy/grunt) using
`npm install -g grunt-cli`, and then the rest of the test/build dependencies
with `npm install` in the morris.js project folder.

Additionally, [bower](http://bower.io/) is required for for retrieving additional test dependencies.  
Install it with `npm install -g bower` and then `bower install` in the morris project folder.

Once you're all set up, you can compile, minify and run the tests using `grunt`.


## License

Copyright (c) 2012-2014, Olly Smith
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
