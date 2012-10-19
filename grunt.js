module.exports = function (grunt) {
  grunt.initConfig({
    coffee: {
      lib: {
        src: ['build/morris.coffee'],
        dest: '.',
        options: { bare: false }
      },
      spec: {
        src: ['spec/lib/*.coffee'],
        dest: 'build/spec/lib',
        options: { bare: false }
      }
    },
    concat: {
      'build/morris.coffee': ['lib/**/*.coffee']
    },
    min: {
      'morris.min.js': 'morris.js'
    },
    mocha: {
      spec: {
        runner: ['spec/spec_runner.html'],
        specs: ['build/spec/**/*.js']
      }
    },
    watch: {
      files: ['lib/**/*.coffee', 'spec/lib/**/*.coffee'],
      tasks: 'default'
    }
  });

  grunt.loadNpmTasks('grunt-coffee');
  grunt.loadNpmTasks('grunt-mocha');

  grunt.registerTask('default', 'concat coffee min mocha');
};
