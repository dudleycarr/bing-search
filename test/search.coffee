Search = require '../src/search'
nock = require 'nock'
should = require 'should'
util = require 'util'
fs = require 'fs'

ACCOUNT_KEY = 'test'
RECORD = false
RECORDED_FILE = 'test/bing_nock.json'

describe 'search', ->
  search = null

  beforeEach ->
    search = new Search ACCOUNT_KEY
    search.useGzip = false

  before ->
    if RECORD
      nock.recorder.rec output_objects: true
    else
      nock.load RECORDED_FILE

  after ->
    if RECORD
      out = JSON.stringify nock.recorder.play(), null, 2
      fs.writeFileSync RECORDED_FILE, out

  describe 'top generation', ->
    describe 'when the number of results is 40', ->
      it 'should generate a 1 item list', ->
        search.generateTops(40).should.eql [40]

    describe 'when the number of results is 50', ->
      it 'should generate a 1 item list', ->
        search.generateTops(50).should.eql [50]

    describe 'when the number of results is 80', ->
      it 'should generate a 2 item list', ->
        search.generateTops(80).should.eql [50, 30]

    describe 'when the number of results is 100', ->
      it 'should generate a 2 item list', ->
        search.generateTops(100).should.eql [50, 50]

    describe 'when the number of results is 112', ->
      it 'should generate a 3 item list', ->
        search.generateTops(112).should.eql [50, 50, 12]

  describe 'skip generation', ->
    describe 'offset of 0', ->
      it 'when the number of results is 40', ->
        search.generateSkips(40, 0).should.eql [0]
      it 'when the number of results is 50', ->
        search.generateSkips(50, 0).should.eql [0]
      it 'when the number of results is 80', ->
        search.generateSkips(80, 0).should.eql [0, 50]
      it 'when the number of results is 100', ->
        search.generateSkips(100, 0).should.eql [0, 50]
      it 'when the number of results is 112', ->
        search.generateSkips(112, 0).should.eql [0, 50, 100]
    describe 'offset of 30', ->
      it 'when the number of results is 40', ->
        search.generateSkips(40, 30).should.eql [30]
      it 'when the number of results is 50', ->
        search.generateSkips(50, 30).should.eql [30]
      it 'when the number of results is 80', ->
        search.generateSkips(80, 30).should.eql [30, 80]
      it 'when the number of results is 100', ->
        search.generateSkips(100, 30).should.eql [30, 80]
      it 'when the number of results is 112', ->
        search.generateSkips(112, 30).should.eql [30, 80, 130]

  describe 'quoted', ->
    it 'should wrap a string in single quotes', ->
      search.quoted('hello').should.eql "'hello'"

    it 'should escape strings contain quotes', ->
      search.quoted("Jack's Coffee").should.eql "'Jack''s Coffee'"

    it 'should generated a quoted string with items seperated by + for a list',
      ->
        search.quoted(['web', 'image']).should.eql "'web+image'"

  describe 'counts', ->
    it 'should return counts for all verticals', (done) ->
      search.counts 'Tutta Bella Neapolitan Pizza', (err, results) ->
        should.not.exist err
        results.should.eql
          web: 463
          image: 896
          video: 29
          news: 84
          spelling: 0
        done()

  describe 'web', ->
    it 'should return results', (done) ->
      search.web 'Tutta Bella Neapolitan Pizza', (err, results) ->
        should.not.exist err
        results.length.should.eql 50
        results[0].should.have.properties [
          'id'
          'title'
          'description'
          'displayUrl'
          'url']
        done()
    it 'should return 100 results', (done) ->
      search.web 'Tutta Bella Neapolitan Pizza', {top: 100}, (err, results) ->
        should.not.exist err
        results.length.should.eql 100
        done()

  describe 'images', ->
    it 'should return results', (done) ->
      search.images 'Tutta Bella Neapolitan Pizza', (err, results) ->
        should.not.exist err
        results.length.should.eql 50
        results[0].should.have.properties [
          'id'
          'title'
          'url'
          'sourceUrl'
          'displayUrl'
          'width'
          'height'
          'size'
          'type'
          'thumbnail'
        ]
        results[0].thumbnail.should.have.properties [
          'url'
          'type'
          'width'
          'height'
          'size'
        ]
        done()

  describe 'videos', ->
    it 'should return results', (done) ->
      search.videos 'Tutta Bella Neapolitan Pizza', (err, results) ->
        should.not.exist err
        results.length.should.eql 29
        results[0].should.have.properties [
          'id'
          'title'
          'url'
          'displayUrl'
          'runtime'
          'thumbnail'
        ]
        results[0].thumbnail.should.have.properties [
          'url'
          'type'
          'width'
          'height'
          'size'
        ]
        done()

  describe 'news', ->
    it 'should return results', (done) ->
      search.news 'Tutta Bella Neapolitan Pizza', (err, results) ->
        should.not.exist err
        results.length.should.eql 13
        results[0].should.have.properties [
          'id'
          'title'
          'source'
          'url'
          'description'
          'date'
        ]
        done()

  describe 'spelling', ->
    it 'should return results', (done) ->
      search.spelling 'tutta bell', (err, results) ->
        should.not.exist err
        results.should.eql ['tutta bella']
        done()

  describe 'related', ->
    it 'should return results', (done) ->
      search.related 'tutta bella', (err, results) ->
        should.not.exist err
        results.length.should.eql 8
        results[0].should.have.properties ['query', 'url']
        done()

  describe 'composite', ->
    it 'should return results', (done) ->
      search.composite 'Tutta Bella Neapolitan Pizza', (err, result) ->
        should.not.exist err
        result.should.have.properties [
          'web'
          'images'
          'videos'
          'news'
          'spelling'
          'related'
        ]
        done()
