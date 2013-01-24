Thumblr = require '../src/thumblr'
BrowserProxy = require '../src/browser_proxy'
path = require 'path'

describe "Thumblr.", ->
  it "should exists", ->
    expect(Thumblr).to.exist

  describe "new Thumblr()", ->
    describe "thumblr.browserOptions.", ->
      it "should come with sensible defaults", ->
        sut = new Thumblr()
        expect(sut.browserOptions.viewportSize).to.exist

      it "should be possible to override the defaults", ->
        sut = new Thumblr {
          zoomFactor: 0.3, 
          viewportSize: 
            width: 200
        }
        sut.browserOptions.zoomFactor.should.equal 0.3
        sut.browserOptions.viewportSize.width.should.equal 200

    describe "thumblr.addJob(outputPath, urlList)", ->
      beforeEach ->
        @sut = new Thumblr( zoomFactor: 0.2 )
        @outputPath1 = './some/path/1'
        @outputPath2 = './some/path/2'
        @urlList1 = ("http://url/#{i}" for i in [1..10])
        @urlList2 = ("http://url/#{i}" for i in [11..20])

      it "should return a job object", ->
        job = @sut.addJob(@outputPath1, @urlList1)
        job.path.should.equal @outputPath1
        job.urls.should.equal @urlList1

      it "should add the job to the queue", ->
        @sut.queue.should.have.length 0
        @sut.addJob @outputPath1, @urlList1
        @sut.addJob @outputPath2, @urlList2
        @sut.queue.should.have.length 2

    describe "run(callback)", ->
      beforeEach ->
        _getFakePage = ->
          {
            get: sinon.stub().withArgs('url').yields "http://localhost:3434"
          }
        
        sinon.stub(BrowserProxy.prototype, 'visit').yields null, _getFakePage()
        sinon.stub(BrowserProxy.prototype, 'renderThumbnail').yields null
        sinon.stub(BrowserProxy.prototype, 'close').yields null

        @outputPath1 = './some/path/1'
        @outputPath2 = './some/path/2'
        @urlList1 = ("http://url/#{i}" for i in [1..10])
        @urlList2 = ("http://url/#{i}" for i in [11..20])

        @sut = new Thumblr formatter: "my_thumbs_%d.png"
        @sut.addJob @outputPath1, @urlList1
        @sut.addJob @outputPath2, @urlList2

      afterEach ->
        BrowserProxy.prototype.visit.restore()
        BrowserProxy.prototype.renderThumbnail.restore()
        BrowserProxy.prototype.close.restore()

      it "should run asynchronously", (done)->
        @sut.run (err)->
          BrowserProxy.prototype.visit.should.have.been.called
          BrowserProxy.prototype.renderThumbnail.should.have.been.called
          BrowserProxy.prototype.close.should.have.been.called
          done()

      it "should render each thumbnail", (done)->
        @sut.run (err)=>
          sinon.assert.callCount BrowserProxy.prototype.visit, 20
          sinon.assert.callCount BrowserProxy.prototype.renderThumbnail, 20
          BrowserProxy.prototype.visit.should.have.been.calledWithMatch @urlList1[0]
          BrowserProxy.prototype.visit.should.have.been.calledWithMatch @urlList1[9]
          done()

      it "should use the name formatter", (done)->
        @sut.run (err)=>
          BrowserProxy.prototype.renderThumbnail.should.have.been.calledWithMatch path.join(@outputPath1, 'my_thumbs_1.png')
          BrowserProxy.prototype.renderThumbnail.should.have.been.calledWithMatch path.join(@outputPath2, 'my_thumbs_9.png')
          done()


