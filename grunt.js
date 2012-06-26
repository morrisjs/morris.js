module.exports = function (grunt) {
  grunt.initConfig({
    coffee: {
      lib: {
        src: ['lib/morris.coffee'],
        dest: 'build/lib',
        options: { bare: false }
      },
      spec: {
        src: ['spec/lib/*.coffee'],
        dest: 'build/spec/lib',
        options: { bare: false }
      }
    },
    concat: {
      'morris.js': ['build/lib/*.js']
    },
    min: {
      'morris.min.js': 'morris.js'
    },
    mocha: {
      spec: {
        runner: ['spec/spec_runner.html'],
        specs: ['build/spec/**/*.js']
      }
    }
  });

  grunt.loadNpmTasks('grunt-coffee');
  grunt.loadNpmTasks('grunt-mocha');

  grunt.registerTask('default', 'coffee concat min mocha');
};
