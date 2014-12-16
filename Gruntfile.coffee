module.exports = (grunt) ->

  grunt.initConfig
    test:
      options:
        bare: true
      expand: true
      src: ['test/**/*.coffee']
      dest: 'test'
      ext: '.js'

    mochacli:
      options:
        require: ['coffee-errors']
        reporter: 'spec'
        colors: true
        compilers: ['coffee:coffee-script']
      all: ['./test/*.coffee']

    coffeelint:
      lib: ['*.coffee', 'src/*.coffee', 'test/*.coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-mocha-cli'
  grunt.loadNpmTasks 'grunt-coffeelint'

  grunt.registerTask 'test', ['mochacli']
  grunt.registerTask 'lint', ['coffeelint']
