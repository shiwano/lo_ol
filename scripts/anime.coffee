# Commands:
#   hubot anime start <query> - <query> にマッチしたアニメーション GIF 画像を淡々と貼る
#   hubot anime stop - アニメーション GIF 画像を淡々と貼るのをやめる

_ = require 'lodash'
async = require 'async'
{CronJob} = require 'cron'

class Retriever
  constructor: (@robot, @room, @query, @interval) ->
    @cacheUrls = []
    @retrieveCount = 0
    @_running = false

  isRunning: ->
    @_running

  start: ->
    return if @isRunning()
    @_running = true
    @retrieveAnimations @showAnimations

  stop: ->
    @_running = false

  message: (message) ->
    @robot.messageRoom @room, message

  retrieveAnimations: (callback) ->
    if @retrieveCount >= 8
      return callback _.shuffle(@cacheUrls)

    q = v: '1.0', rsz: '8', q: @query, safe: 'active', start: (@retrieveCount * 8).toString(), imgtype: 'animated'
    @robot.http('http://ajax.googleapis.com/ajax/services/search/images')
      .query(q)
      .get() (err, res, body) =>
        return @message err.toString() if err?
        res = JSON.parse(body)
        return @message '画像が見つかりませんでした' unless res?.responseData?
        data = res.responseData
        return @message '画像が見つかりませんでした' if _.isEmpty(data.results) and _.isEmpty(@cacheUrls)

        urls = _.pluck(data.results, 'unescapedUrl')
        @retrieveCount += 1
        @cacheUrls = _.union @cacheUrls, urls
        callback urls

  showAnimations: (urls) =>
    async.forEachSeries urls, (url, done) =>
      return done() if not @isRunning() or url.length > 450
      @message "[#{@query}] #{url}#.png"
      setTimeout done, @interval
    , =>
      return unless @isRunning()
      @retrieveAnimations @showAnimations

module.exports = (robot) ->
  retrievers = {}

  robot.respond /anime\s+start\s+(.+)$/i, (msg) ->
    query = msg.match[1]
    room = msg.message.room
    retrievers[room]?.stop()
    retriever = new Retriever(robot, room, query, 60000)
    retriever.start()
    retrievers[room] = retriever
    msg.send "[#{query}] に一致するGIFアニメを淡々と貼り続けます"

  robot.respond /anime\s+stop\s*$/i, (msg) ->
    room = msg.message.room
    retrievers[room]?.stop()
    delete retrievers[room]
    msg.send 'GIFアニメを淡々と貼り続けるのをやめます'

  startAll = ->
    for room, retriever of retrievers
      robot.messageRoom room, 'おはようございます'
      retriever.start()

  stopAll = ->
    for room, retriever of retrievers
      robot.messageRoom room, '21時なので、休みます'
      retriever.stop()

  new CronJob('00 00 9 * * 1-5', startAll, null, true, 'Asia/Tokyo')
  new CronJob('00 00 21 * * 1-5', stopAll, null, true, 'Asia/Tokyo')
