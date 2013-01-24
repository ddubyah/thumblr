# Thumblr

Create thumbnails for a list of urls in a headless browser (using [PhantomJS](http://phantomjs.org/)).

## Getting Started
Install the module with: `npm install thumblr` or add it to your package.json. You'll need PhantomJS installed and available in your path too. [Get it here](http://phantomjs.org/download.html)

```javascript
var thumblr = require('thumblr');

var myThumblr;
myThumblr = new Thumblr(browserOptions);
myThumblr.addJob('output/folder/path', ['http://url1', 'http://url2']);
myThumblr.run(callback);
```

## Documentation

### new Thumblr(browserOptions)

Wher `browserOptions` is an object describing the dimensions and zoom of the headless browser used to render each thumbnail.

```coffee
browserOptions = {
  viewportSize: 
    height: 600
    width: 800
  # A zoomFactor of 0.5 will give us thumbnails 400x300px in size
  zoomFactor: 0.5 
}
```

### thumblr.addJob(outputFolder, urlList)

Adds a thumbnail job to the queue. Returns a job object for reference.

- `outputFolder` - the path you want to save the thumbnails to. e.g. `./thumbs`
- `urlList` - list of urls you want to generate thumbnails for. e.g. `['http://bbc.co.uk', 'http://twitter.com']`

### thumblr.queue

Returns the current job queue as an array of job objects:

```coffee
	[
		{
			path: './thumbs',
			urls: ['http://bbc.co.uk', 'http://twitter.com']
		}
	]
```

### thumblr.run(callback)

Runs all the jobs in the queue. The callback accepts an `err` parameter as per usual.

```coffee
	thumblr.run (err)->
	  throw err if err
	  console.log "Thumblr complete. Say yay!"
```
## Examples

### Rendering a list of Urls

```coffee

	Thumblr = require 'thumblr'
	path = require 'path'

	urls = [
	  'http://www.bbc.co.uk'
	  'http://www.google.com'
	  'http://www.twitter.com'
	]

	outputPath = './thumbs'
	outputPath2 = './thumbs2'

	# Set the virtual browser dimensions and zoom factor. This will determine the
	# thumbnail size.

	browserOptions = {
	  viewportSize: 
	    height: 600
	    width: 800
	  # A zoomFactor of 0.5 will give us thumbnails 400x300px in size
	  zoomFactor: 0.5 
	}

	# create a new thumblr instance.
	thumblr = new Thumblr(browserOptions)

	# create any number of 'jobs'
	thumblr.addJob(outputPath, urls)
	thumblr.addJob(outputPath2, urls)

	# run the jobs asynchronously. Callback accepts an err as the first param.
	thumblr.run (err)->
	  throw err if err
	  console.log "Thumblr complete. Say yay!"

```

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [grunt](https://github.com/gruntjs/grunt).

## Release History
_(Nothing yet)_

## License
Copyright (c) 2013 Darren Wallace  
Licensed under the MIT license.
