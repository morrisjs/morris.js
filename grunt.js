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
        'lib/morris.hover.coffee',
        'lib/morris.line.coffee',
        'lib/morris.area.coffee',
        'lib/morris.bar.coffee',
        'lib/morris.donut.coffee'
      ],
      'build/spec.coffee': ['spec/support/**/*.coffee', 'spec/lib/**/*.coffee']
    },
    less: {
      all: {
        src: 'less/*.less',
        dest: 'morris.css',
        options: {
          compress: true
        }
      }
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
      files: ['lib/**/*.coffee', 'spec/lib/**/*.coffee', 'spec/support/**/*.coffee', 'less/**/*.less'],
      tasks: 'default'
    }
  });

  grunt.loadNpmTasks('grunt-coffee');
  grunt.loadNpmTasks('grunt-mocha');
  grunt.loadNpmTasks('grunt-contrib-less');

  grunt.registerTask('default', 'concat coffee less min mocha');
};
