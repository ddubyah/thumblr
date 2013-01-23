Hash = require 'hashish'
require 'colors'
async = require 'async'
BrowserProxy = require './browser_proxy'
path = require 'path'
util = require 'util'

class Thumblr
  @_defaults: 
    viewportSize:
      width: 1024
      height: 768
    zoomFactor: 0.5
    formatter: "thumb_%d.png"

  _titles: 0 # value must be set in the constructor for instances
  _privateStuff: ()->
    console.log "Private by convention only"

    ###
    Public Members
    ###
    get_count: ->
      # Do stuff
  browserOptions: {}
  queue: null

  constructor: (opts={}, callback) ->
    @browserOptions = Hash.merge(Thumblr._defaults, opts)
    @queue = []

  addJob: (outputPath, urlList)->
    job = @_makeJob(outputPath, urlList)
    @queue = @queue.concat job
    job

  run: (callback)->
    _startTime = process.hrtime()
    async.forEachSeries @queue, (item, callback)=>
      @_runJob item, callback
    ,(err)->
      console.log "\nAll thumbs processed in %s milliseconds", String(process.hrtime(_startTime)).green
      callback err

  _makeJob: (outputPath, urlList)->
    {
      path: outputPath
      urls: urlList
    }

  _runJob: (job, callback)->
    _startTime = process.hrtime()
    _counter = 0
    async.forEachSeries job.urls, (item, callback)=>
      thumbPath = path.join job.path, util.format(@browserOptions.formatter, _counter)
      _counter = _counter+1
      @_processThumbnail item, thumbPath, callback
    ,(err)->
      console.log "Job complete in %s".green.underline, process.hrtime _startTime unless err 
      callback err

  _processThumbnail: (url, outputPath, callback)->
    console.log "Rendering"
    _startTime = process.hrtime()
    @_renderThumbnail url, outputPath, (err, results)->
        console.log "%s -> %s : %s", url, outputPath, process.hrtime(_startTime)
        callback err

  _renderThumbnail: (url, outputPath, callback)->
    _browserProxy = new BrowserProxy { zoomFactor:0.5 }
    async.auto {
      visitPage: 
        (callback, results)->
          _browserProxy.visit url, (err, page)->
            # console.log "%s Ready? %s".yellow, url, err
            callback err, page
      checkUrl: [
        'visitPage'
        (callback, results)->
          results.visitPage.get 'url', (value)->
            # console.log "Requested %s", url
            # console.log "Visted page %s", value
            if value.match /about:blank/i
              callback "Bad page. Can't render"
            else
              callback null, 'success'
      ]
      renderPage: [
        'checkUrl'
        (callback, results)->
          _browserProxy.renderThumbnail outputPath, callback
      ]
      closeBrowser: [
        'renderPage'
        (callback, results)->
          _browserProxy.close callback
      ]
    }, (err, results)->
      throw err if err
      console.log "Rendering complete %s\n".green.underline, url
      process.nextTick ->
        callback err, results

module.exports = Thumblr