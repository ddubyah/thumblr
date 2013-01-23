path = require 'path'
fs = require 'fs'
Thumblr = require '../../src/thumblr'
describe.skip 'Thumblr Integrations', ->
  _outputFolder = path.resolve __dirname, '../fixtures/delete_me/integration_thumbs'
  _targets = [
    'http://www.cdsm.co.uk'
    'http://www.twitter.com'
    'http://www.google.com'
  ]

  beforeEach (done)->
    @timeout 15000
    @results = null
    @sut = new Thumblr formatter: "int_thumb_%d.png"
    @sut.addJob _outputFolder, _targets
    @sut.run (err)->
      done()

  it "should create three thumbnails", (done)->
    fs.readdir _outputFolder, (err, files)->
      files.should.have.length 3
      done()

