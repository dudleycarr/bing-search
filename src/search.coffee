_ = require 'underscore'
async = require 'async'
debug = require('debug')('bing-search')
request = require 'request'
url = require 'url'

markets = require './markets'

class Search
  @SOURCES = ['web', 'image', 'video', 'news', 'spell', 'relatedsearch']

  constructor: (@accountKey, @parallel=10) ->
    @endPoint = 'https://api.datamarket.azure.com/Bing/Search'
    @userAgent = 'NodeJS (https://github.com/dudleycarr/bing-search/)'
    @useGzip = true

  requestOptions: (options) ->
    reqOptions =
      Query: @quoted(options.query)
      $top: options.top or 10
      $skip: options.skip or 0

    # Filter out unsupported sources
    sources = (s for s in options.sources or [] when s in Search.SOURCES)
    reqOptions.Sources = @quoted(sources) if sources.length

    if options.market in markets.identifiers
      reqOptions.Market = @quoted(options.market)

    reqOptions

  quoted: (values) ->
    values = [values] unless _.isArray values
    values = (v.replace("'", "''") for v in values)
    "'#{values.join '+'}'"

  # Generates a sequence of numbers no larger than 50 which the sum of the list
  # equal to numResults.
  generateTops: (numResults) ->
    tops = [numResults % 50] if numResults % 50 isnt 0
    (50 for i in [0...Math.floor(numResults/50)]).concat tops or []

  # Generate a sequence of offsets as a multiple of 50 starting at skipStart
  # and ending before skipStart + numResults.
  generateSkips: (numResults, skipStart) ->
    skips = [skipStart]
    for count in @generateTops(numResults)[...-1]
      skips.push skips[skips.length-1] + count
    skips

  parallelSearch: (vertical, options, callback) ->
    opts = _.defaults options, {top: 50, skip: 0}

    # Generate search options for each of the search requests.
    pairs = _.zip @generateTops(opts.top), @generateSkips(opts.top, opts.skip)
    requestOptions = _.map pairs, ([top, skip]) ->
      _.defaults {top, skip}, options

    search = (options, callback) =>
      @search vertical, options, callback

    async.mapLimit requestOptions, @parallel, search, callback

  search: (vertical, options, callback) ->
    requestOptions =
      uri: "#{@endPoint}/#{vertical}"
      qs: _.extend @requestOptions(options),
        $format: 'json'
      headers:
        'User-Agent': @userAgent
      auth:
        user: @accountKey
        pass: @accountKey
      json: true
      gzip: @useGzip

    req = request requestOptions, (err, res, body) ->
      if res.statusCode isnt 200
        err or= new Error("Bad Bing API response #{res.statusCode}")
      return callback err if err

      callback null, body

    debug url.format req.uri

  counts: (query, callback) ->
    getCounts = (options, callback) =>
      options = _.extend {}, options, {query, sources: Search.SOURCES}
      @search 'Composite', options, (err, result) =>
        return callback err if err
        callback null, @extractCounts result

    # Two requests are needed. The first request is to get an accurate
    # web results count and the second request is to get an accurate count
    # for the rest of the verticals.
    async.map [{skip: 1000}, {}], getCounts, (err, results) ->
      return callback err if err
      callback null, _.extend results[1], _.pick(results[0], 'web')

  extractCounts: (result) ->
    keyRe = /(\w+)Total$/

    _.chain(result?.d?.results)
      .first()
      .pairs()
      .filter ([key, value]) ->
        # Eg. WebTotal, ImageTotal, ...
        keyRe.test key
      .map ([key, value]) ->
        # Eg. WebTotal => web
        key = keyRe.exec(key)[1].toLowerCase()
        value = Number value

        switch key
          when 'spellingsuggestions' then ['spelling', value]
          else [key, value]
      .object()
      .value()

  verticalSearch: (vertical, verticalResultParser, query, options, callback) ->
    [callback, options] = [options, {}] if _.compact(arguments).length is 4

    @parallelSearch vertical, _.extend({}, options, {query}), (err, result) ->
      return callback err if err
      callback null, verticalResultParser result

  web: (query, options, callback) ->
    @verticalSearch 'Web', _.bind(@extractWebResults, this), query, options,
      callback

  extractWebResults: (results) ->
    _.chain(results)
      .pluck('d')
      .pluck('results')
      .flatten()
      .map (entry) ->
        id: entry.ID
        title: entry.Title
        description: entry.Description
        displayUrl: entry.DisplayUrl
        url: entry.Url
      .value()

  images: (query, options, callback) ->
    @verticalSearch 'Image', _.bind(@extractImageResults, this), query, options,
      callback

  extractImageResults: (results) ->
    _.chain(results)
      .pluck('d')
      .pluck('results')
      .flatten()
      .map (entry) =>
        id: entry.ID
        title: entry.Title
        url: entry.MediaUrl
        sourceUrl: entry.SourceUrl
        displayUrl: entry.DisplayUrl
        width: Number entry.Width
        height: Number entry.Height
        size: Number entry.FileSize
        type: entry.ContentType
        thumbnail: @extractThumbnail entry
      .value()

  extractThumbnail: (entry) ->
    url: entry.Thumbnail.MediaUrl
    type: entry.Thumbnail.ContentType
    width: Number entry.Thumbnail.Width
    height: Number entry.Thumbnail.Height
    size: Number entry.Thumbnail.FileSize

  videos: (query, options, callback) ->
    @verticalSearch 'Video', _.bind(@extractVideoResults, this), query, options,
      callback

  extractVideoResults: (results) ->
    _.chain(results)
      .pluck('d')
      .pluck('results')
      .flatten()
      .map (entry) =>
        id: entry.ID
        title: entry.Title
        url: entry.MediaUrl
        displayUrl: entry.DisplayUrl
        runtime: Number entry.RunTime
        thumbnail: @extractThumbnail entry
      .value()

  news: (query, options, callback) ->
    @verticalSearch 'News', _.bind(@extractNewsResults, this), query, options,
      callback

  extractNewsResults: (results) ->
    _.chain(results)
      .pluck('d')
      .pluck('results')
      .flatten()
      .map (entry) ->
        id: entry.ID
        title: entry.Title
        source: entry.Source
        url: entry.Url
        description: entry.Description
        date: new Date entry.Date
      .value()

  spelling: (query, options, callback) ->
    @verticalSearch 'SpellingSuggestions', _.bind(@extractSpellResults, this),
      query, options, callback

  extractSpellResults: (results) ->
    _.chain(results)
      .pluck('d')
      .pluck('results')
      .flatten()
      .map (entry) ->
        entry.Value
      .value()

  related: (query, options, callback) ->
    @verticalSearch 'RelatedSearch', _.bind(@extractRelatedResults, this),
      query, options, callback

  extractRelatedResults: (results) ->
    _.chain(results)
      .pluck('d')
      .pluck('results')
      .flatten()
      .map (entry) ->
        query: entry.Title
        url: entry.BingUrl
      .value()

  composite: (query, options, callback) ->
    [callback, options] = [options, {}] if arguments.length is 2
    options = _.defaults options, {query, sources: Search.SOURCES}

    @parallelSearch 'Composite', options, (err, results) =>
      return callback err if err

      convertToSingleSource = (results, source) ->
        {d: {results: r.d.results[0][source]}} for r in results

      callback null,
        web: @extractWebResults convertToSingleSource results, 'Web'
        images: @extractImageResults convertToSingleSource results, 'Image'
        videos: @extractVideoResults convertToSingleSource results, 'Video'
        news: @extractNewsResults convertToSingleSource results, 'News'
        spelling: @extractSpellResults convertToSingleSource results,
          'SpellingSuggestions'
        related: @extractRelatedResults convertToSingleSource results,
          'RelatedSearch'

module.exports = {Search}
