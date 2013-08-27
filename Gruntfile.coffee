module.exports = (grunt) ->
  config =
    pkg: grunt.file.readJSON 'package.json'
    coffee:
      compile:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'bin'
        ext: '.js'
    coffeecup:
      examples:
        expand: true
        cwd: 'src'
        src: ['**/*.ccup']
        dest: 'bin'
        ext: '.html'
    copy:
      js:
        expand: true
        cwd: 'src'
        src: ['**/*.js']
        dest: 'bin'
      components:
        expand: true
        cwd: 'src'
        src: ['*/components/**']
        dest: 'bin'
      assets:
        expand: true
        cwd: 'src'
        src: ['**/assets/**']
        dest: 'bin'
      requirejs:
        src: 'support/combo/support/require.js'
        dest: 'bin/require.js'
    watch:
      coffee:
        files: '**/*.coffee'
        tasks: 'coffee'
        options:
          nospawn: true
    requirejs:
      build:
        options:
          baseUrl: 'bin'
          name: '../support/almond'
          include: 'main'
          insertRequire: ['main']
          out: "bin/main-built.js"

  grunt.initConfig config

    # Hackish, but results in substantially quicker `watch`:
  compile_cwd = grunt.config.get 'coffee.compile.cwd'
  grunt.event.on 'watch', (action, filepath) ->
    grunt.config.set 'coffee.compile.src', filepath.substr compile_cwd.length+1

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-coffeecup'
  grunt.loadNpmTasks 'grunt-contrib-requirejs'

  grunt.registerMultiTask 'copyfiles', 'Copy assets into example folders.', ->
    if grunt.file.exists @data.src
      grunt.file.copy @data.src, @data.dest

  grunt.registerTask 'default', ['coffee', 'coffeecup', 'copy', 'requirejs']