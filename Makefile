all: morris.min.js

morris.js: morris.coffee
	coffee -c morris.coffee

morris.min.js: morris.js
	uglifyjs morris.js > morris.min.js

clean:
	rm -f morris.js morris.min.js
