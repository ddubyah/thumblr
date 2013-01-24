# # Rendering a list of Urls

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

