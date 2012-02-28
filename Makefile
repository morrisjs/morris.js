all: morris

morris:
	coffee -c morris.coffee
	uglifyjs morris.js > morris.min.js
