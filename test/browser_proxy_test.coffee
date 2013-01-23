express = require 'express'
# request = require "superagent"
assert = require 'assert'
async = require 'async'
path = require 'path'
http = require 'http'
fs = require 'fs.extra'
# wrench = require 'wrench'

BrowserProxy = require '../../../lib/utilities/browser_proxy'

# constants
PORT = 3838
THUMBPATH = path.resolve __dirname, '../../fixtures/delete_me/thumbs'
_testPage = null

describe "Browser Proxy", ->
  before (done)->
    # make test dir if necessary
    fs.exists THUMBPATH, (exists)=>
      if !exists
        fs.mkdirp THUMBPATH, (err)=>
          console.log "Created test directory %s", THUMBPATH
          done(err)
      else
        done()

  beforeEach (done)->
    # @timeout 15000
    
    # start test server
    @app = express()

    # Create a middleware callback to spy on
    @cbSpy = sinon.spy (req, res, next)->
      console.log "Requesting test page id: %s".yellow, req.params['id']
      randomDelay = Math.floor(Math.random()*500)
      setTimeout ->
        res.send """
        <h1>Hello! <small>page id: #{req.params['id']}</small></h1>

        <p>This is some test content</p>
        """
      ,randomDelay

    # apply the spy to the express route
    @app.get '/test/:id?', @cbSpy
    
    _testPage = "http://localhost:#{PORT}/test/0"
    @server = http.createServer(@app)
    @server.listen PORT, ->
      console.log "Server listening on %d", PORT
      done()
    
  afterEach ->
    @server.close()

  describe "visit", ->
    _browserProxy = null

    describe "one page per proxy session", ->
      #TODO: Test consecutive, multiple visits
      beforeEach (done)->
        # @timeout 15000
        _browserProxy = new BrowserProxy()
        async.series [
          (callback)=>
            _browserProxy.visit _testPage, (err)=>
              callback err, "Page visit successful"
        ], (err, results)->
          assert.ifError err
          console.log results
          done()

      afterEach (done)->
        _browserProxy.close done
        

      it "should open the requested url", ->
        @cbSpy.should.have.been.calledOnce

  describe "multiple pages per session", ->
    _browserProxy = null
    _pageObject = null

    beforeEach (done)->
      _browserProxy = new BrowserProxy()
      _browserProxy.getPage (err, pageObject)->
        _pageObject = pageObject
        done err


    afterEach (done)->
      _browserProxy.close done

    it "should complete each page load in sequence", (done)->
      pages = for i in [1..5]
        _testPage.concat i

      index = 0
      async.forEachSeries pages, (page, callback)=>
        _browserProxy.visit page, (err)->
          index++
          _pageObject.get "content", (value)->
            indexMatcher = new RegExp "page id: 0#{index}"
            value.should.match indexMatcher
            callback err
      , done

    it.skip "should work for external links", (done)->
      @timeout 45000
      pages = [
        "http://www.cdsm.co.uk"
        "http://www.twitter.com"
        "http://www.bbc.co.uk"
      ]

      async.forEachSeries pages, (page, callback)=>
        _browserProxy.visit page, (err)->
          callback err
      , done

  describe "renderThumbnail", ->
    _browserProxy = null
    _targetPath = null
    describe "after visiting a page", ->
      beforeEach (done)->
        # @timeout 15000
        _browserProxy = new BrowserProxy()
        _targetPath = path.resolve THUMBPATH, 'testThumb.png'
        async.series [
          (callback)->
            _browserProxy.visit _testPage, (err)->
              callback err, "Page visited"
          (callback)->
            _browserProxy.renderThumbnail _targetPath, callback
        ], (err, results)->
          console.log "Test render complete"
          assert.ifError err
          done()

      it "should save a file to the output path", (done)->
        fs.exists _targetPath, (exists)->
          console.log "%s should exist -> %s".yellow,(_targetPath), exists
          exists.should.be.ok
          done()

    afterEach (done)->
      _browserProxy.close done

    describe "with no valid page visit", ->
      _errorMsg = null

      beforeEach (done)->
        # @timeout 15000
        bp = new BrowserProxy()
        _targetPath = path.resolve THUMBPATH, 'duffThumb.png'
        # call render without calling visit first
        bp.renderThumbnail _targetPath, (err)->
          console.log "Error message? %s", err
          _errorMsg = err
          done()

      it "should return an error  message", ->
        _errorMsg.should.not.equal null

      it "should not save a thumbnail", ->
        fs.exists _targetPath, (exists)->
          console.log "%s should not exist -> ".yellow, path.basename(_targetPath), exists
          exists.should.not.be.ok


