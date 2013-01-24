'use strict'
fs = require 'fs.extra'
path = require 'path'

async = require 'async'
assert = require 'assert'
AsyncCache = require 'async-cache'
hashish = require 'hashish'
_ = require 'underscore'

phantomProxy = require 'phantom-proxy'


'use strict'
require 'colors'

# Acts as a proxy for a web browser
# TODO: Mock out dependencies for phantom to allow for easier ci testing
class BrowserProxy
  @_browserDefaults:
    viewportSize:
      width: 1024
      height: 768
    zoomFactor: 0.5

  _phantom: null
  _page: null
  _pageProperties: null

  constructor: (options={})->
    # Instantiate. Remember to set instance member values here
    @_pageProperties = hashish.merge BrowserProxy._browserDefaults, options
    @_createPhantomProxyCachedObjects()

  getPage: (callback)->
    @_phantom.get 'page', callback # always returns the single, cached page object

  visit: (url, callback)->
    ph = @_phantom
    
    async.auto {
      getPage: 
        (asyncCallback)->
          ph.get 'page', asyncCallback   

      visitUrl: [
        'getPage'
        (asyncCallback, results)->
          results.getPage.open url, (success)->
            if success
              asyncCallback null
            else
              console.error  "Problem opening url: #{url}"
              asyncCallback "Page open failed: #{url}"
      ]

    }, (err, results)->
      # console.log "Page load complete: %s".green, url
      if err
        console.warn "%s".yellow.underline, err 
        return callback err
      async.nextTick ->
        callback err, results.getPage

  close: (callback)->
    ph = @_phantom
    # console.log "Closing Phantom Pages".yellow
    async.auto {
      getPhantom:
        (asyncCallback)=>
          ph.get 'phantom', asyncCallback

      closePage: [
        'getPhantom'
        (asyncCallback, results)->
          results.getPhantom.end (success)->
            if success 
              asyncCallback null
            else
              asyncCallback "failed to close phantom"
      ]
    }, (err, results)->
      throw err if err
      ph.reset() # drop the cache objects
      # console.log "Browser closed".red
      callback err, "Page closed" if callback?

  renderThumbnail: (fullOutputFilePath, callback)->
    ph = @_phantom
    zoom = @_pageProperties.zoomFactor
    targetViewport = _scaleObjectKeys @_pageProperties.viewportSize, @_pageProperties.zoomFactor

    async.auto {
      getPage: 
        (asyncCallback)->
          ph.get 'page', asyncCallback
      testPageInfo: [
        'getPage'
        (asyncCallback, results)->
          results.getPage.get 'url', (value)->
            # console.log "Current url: %s".yellow, value
            asyncCallback null, value
      ]
      setViewport: [
        'getPage'
        (asyncCallback, results)=>
          # console.log "Setting browser size"
          @_setPhantomPageProperty results.getPage, 'viewportSize', targetViewport, asyncCallback
      ]
      setZoom: [
        'getPage'
        (asyncCallback, results)=>
          # console.log "Setting browser zoom"
          @_setPhantomPageProperty results.getPage, 'zoomFactor', zoom, asyncCallback
      ]
      setClipping: [
        'getPage'
        (asyncCallback, results)=>
          # console.log "Setting browser clipping"
          @_setPhantomPageProperty results.getPage, 'clipRect', {
            top: 0
            left: 0
            bottom: targetViewport.height
            right: targetViewport.width
          }, asyncCallback
      ]
      renderThumb: [
        'testPageInfo'
        'setZoom'
        'setViewport'
        'setClipping'
        (asyncCallback, results)->
          # console.log "Rendering Thumbnail for %s", results.testPageInfo
          
          # don't render if we haven't visited a valid page
          if results.testPageInfo.match /about:blank/i
            asyncCallback "Can't Render: #{results.testPageInfo}" 
          else
            results.getPage.render fullOutputFilePath, (success)->
              # console.log "Rendered page? %s", success
              if success
                asyncCallback null , "Rendered file"
              else
                asyncCallback "Thumbnail render failed: #{success}"
      ]
    }, (err, results)->
      # console.error "%s".red, err if err
      # console.log "Render Complete %s".green, fullOutputFilePath
      process.nextTick ->
        callback err, results


  _createPhantomProxyCachedObjects: ->
    # console.log "Creating phantom object cache"
    @_phantom = new AsyncCache {
      load: (key, callback)=>
        switch key
          when "phantom" then @_getPhantomProxyObject callback
          when "page" then @_getPhantomPageProxy callback
          else
            callback "Phantom Cache - key not supported"
    }
    @_phantom

  _getPhantomProxyObject: (callback)->
    # console.log "Cacheing phantom proxy object".yellow
    phantomProxy.create {}, (proxy)->
      callback null, proxy

  _getPhantomPageProxy: (callback)->
    # console.log "Cacheing phantom page object".yellow
    async.auto {
      getPhantom:
        (asyncCallback, results)=>
          @_phantom.get 'phantom', asyncCallback
      getPhantomPage:[
        'getPhantom'
        (asyncCallback, results)->
          callback null, results.getPhantom.page
      ]
      # setViewport: [
      #   'getPhantomPage'
      #   (asyncCallback, results)=>
      #     _setPhantomPageProperty results.getPhantomPage,
      #       'viewportSize',
      #       @_pageProperties.viewportSize,
      #       asyncCallback
      # ]
    }, (err, results)->
      # console.log "New Phantom page ready".green
      callback err, results.getPhantomPage

  _setPhantomPageProperty: (page, property, value, callback)->
    page.set property, value, (success)->
      if success
        callback null if callback?
      else
        callback "Problem setting #{property} on phantom page" if callback?

  # apply a scalor to each value of an object. Used to scale the viewport
  _scaleObjectKeys = (obj, scale= 0.5)->
    newObj = _.clone obj
    for k,v of obj
      # console.log "Scaling %d by %d", v, scale
      newObj[k] = v * scale
    # console.log "Scaling to :".yellow
    console.dir newObj
    newObj

module.exports = BrowserProxy

