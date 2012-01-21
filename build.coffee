{Serenade} = require './src/serenade'

CoffeeScript = require 'coffee-script'
fs = require 'fs'
path = require 'path'

header = """
  /**
   * Serenade.js JavaScript Framework v#{Serenade.VERSION}
   * http://github.com/elabs/serenade.js
   *
   * Copyright 2011, Jonas Nicklas
   * Released under the MIT License
   */
"""

Build =
  files: ->
    files = fs.readdirSync 'src'
    for file in files when file.match(/\.coffee$/)
      unless file is 'parser.coffee'
        path = 'src/' + file
        newPath = 'lib/' + file.replace(/\.coffee$/, '.js')
        fs.writeFileSync newPath, CoffeeScript.compile(fs.readFileSync(path).toString(), bare: false)
  parser: ->
    {Parser} = require('./lib/grammar')
    fs.writeFileSync 'lib/parser.js', Parser.generate()
  browser: ->
    requires = ''
    for name in ['events', 'helpers', 'cache', 'collection', 'association_collection', 'associations', 'serenade', 'lexer', 'nodes', 'parser', 'properties', 'model', 'view']
      requires += """
        require['./#{name}'] = new function() {
          var exports = this;
          #{fs.readFileSync "lib/#{name}.js"}
        };
      """
    code = """
      (function(root) {
        var Serenade = function() {
          function require(path){ return require[path]; }
          #{requires}
          return require['./serenade'].Serenade
        }();

        if(typeof define === 'function' && define.amd) {
          define(function() { return Serenade });
        } else { root.Serenade = Serenade }
      }(this));
    """
    if process.env.MINIFY is 'true'
      {parser, uglify} = require 'uglify-js'
      code = uglify.gen_code uglify.ast_squeeze uglify.ast_mangle parser.parse code
    fs.writeFileSync 'extras/serenade.js', header + '\n' + code
  all: ->
    Build.files()
    Build.parser()
    Build.browser()

exports.Build = Build
