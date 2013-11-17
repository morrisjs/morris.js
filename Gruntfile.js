module.exports = function (grunt) {
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  grunt.initConfig({
    coffee: {
      lib: {
        options: { bare: true },
        files: {
          'morris-bare.js': ['build/morris.coffee']
        }
      },
      spec: {
        options: { bare: true },
        files: {
          'build/spec.js': ['build/spec.coffee']
        }
      },
    },
    concat: {
      coffee: {
        src: [
          'lib/morris.coffee',
          'lib/morris.grid.coffee',
          'lib/morris.hover.coffee',
          'lib/morris.line.coffee',
          'lib/morris.area.coffee',
          'lib/morris.bar.coffee',
          'lib/morris.donut.coffee'
        ],
        dest: 'build/morris.coffee'
      },
      spec: {
        src: ['spec/support/**/*.coffee', 'spec/lib/**/*.coffee'],
        dest: 'build/spec.coffee'
      },
      wrap: {
        src: [
          'amd-header.txt',
          'morris-bare.js',
          'amd-footer.txt'
        ],
        dest: 'morris.js'
      }
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
    uglify: {
      build: {
        files: {
          'morris.min.js': 'morris.js'
        }
      }
    },
    mocha: {
      index: ['spec/specs.html'],
      options: {run: true}
    },
    watch: {
      all: {
        files: ['lib/**/*.coffee', 'spec/lib/**/*.coffee', 'spec/support/**/*.coffee', 'less/**/*.less'],
        tasks: 'default'
      },
      dev: {
        files:  'lib/*.coffee' ,
        tasks: ['concat:build/morris.coffee', 'coffee:lib']
      }
    },
    shell: {
      visual_spec: {
        command: './run.sh',
        options: {
          stdout: true,
          failOnError: true,
          execOptions: {
            cwd: 'spec/viz'
          }
        }
      }
    }
  });

  grunt.registerTask('default', ['concat:coffee', 'concat:spec', 'coffee', 'concat:wrap', 'less', 'uglify', 'mocha', 'shell:visual_spec']);
};
