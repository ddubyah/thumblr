console.log( "Loading test helpers")

global.chai = require('chai')
global.should = chai.should()
global.sinon = require('sinon')
global.sinonChai = chai.use(require('sinon-chai'))
global.expect = chai.expect

global.SAFEKILLPATH = 'fixtures/delete_me'

