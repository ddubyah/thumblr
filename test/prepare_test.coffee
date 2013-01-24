# Since this 'before' block isn't contained inside a describe block, it runs
# before all tests
path = require 'path'
fs = require 'fs'
wrench = require 'wrench'
cleanDir = path.resolve __dirname, './fixtures/delete_me'

before ->
  wrench.rmdirSyncRecursive cleanDir, true
  wrench.mkdirSyncRecursive cleanDir
