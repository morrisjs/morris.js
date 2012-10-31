module.exports = function (grunt) {
  grunt.initConfig({
    coffee: {
      lib: {
        src: ['build/morris.coffee'],
        dest: '.',
        options: { bare: false }
      },
      spec: {
        src: ['build/spec.coffee'],
        dest: 'build',
        options: { bare: true }
      }
    },
    concat: {
      'build/morris.coffee': [
        'lib/morris.coffee',
        'lib/morris.grid.coffee',
        'lib/morris.line.coffee',
        'lib/morris.area.coffee',
        'lib/morris.bar.coffee',
        'lib/morris.donut.coffee'
      ],
      'build/spec.coffee': ['spec/support/**/*.coffee', 'spec/lib/**/*.coffee']
    },
    min: {
      'morris.min.js': 'morris.js'
    },
    mocha: {
      spec: {
        src: 'spec/specs.html',
        run: true
      }
    },
    watch: {
      files: ['lib/**/*.coffee', 'spec/lib/**/*.coffee', 'spec/support/**/*.coffee'],
      tasks: 'default'
    }
  });

  grunt.loadNpmTasks('grunt-coffee');
  grunt.loadNpmTasks('grunt-mocha');

  grunt.registerTask('default', 'concat coffee min mocha');
};
