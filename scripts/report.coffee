# Commands:
#   hubot general-report - IRC 全体の発言数情報を表示する
#   hubot report - 発言した ユーザ のIRC 発言数情報を表示する
#   hubot report <username> - 指定したユーザの IRC 発言数情報を表示する

{CronJob} = require 'cron'
moment = require 'moment'
sparkline = require 'sparkline'
_ = require 'lodash'


module.exports = (robot) ->
  class Recorder
    constructor: ->
      if robot.brain.data.report?
        @data = robot.brain.data.report
      else
        @reset()

    reset: ->
      robot.brain.data.report =
        records: {}
        rankingRecords: {}
      @data = robot.brain.data.report
      @save()

    save: ->
      robot.brain.save()

    getRecord: (userName) ->
      @data.records[userName]

    getOrCreateRecord: (userName) ->
      record = @getRecord userName
      unless record?
        record = (0 for i in [0...48])
        @data.records[userName] = record
        @save()
      record

    getGeneralRecord: ->
      generalRecord = (0 for i in [0...48])
      for userName, record of @data.records
        for value, index in record
          generalRecord[index] += value
      generalRecord

    getRanking: ->
      pairs = _.pairs @data.rankingRecords
      _.sortBy(pairs, (pair) -> pair[1]).reverse()

    increment: (userName, value=1) ->
      unless @data.rankingRecords[userName]?
        @data.rankingRecords[userName] = 0
      @data.rankingRecords[userName] += value

      record = @getOrCreateRecord userName
      now = moment()
      part = if now.minute() < 30 then 0 else 1
      record[now.hour() * 2 + part] += value
      @save()

  rec = new Recorder()

  postReport = (room, record, userName) ->
    prefix = if userName? then "#{userName} さんの" else ''
    total = _.reduce record, ((memo, num) -> memo + num), 0
    ranking = rec.getRanking()

    robot.messageRoom room, "#{prefix}本日の総発言数: #{total}"
    robot.messageRoom room, "#{prefix}本日の発言数グラフ: [10時] #{sparkline record[20...38]} [19時]"

    if userName?
      pair = _.find ranking, (pair) -> pair[0] is userName
      robot.messageRoom room, "#{prefix}本日の発言数ランキング: #{ranking.indexOf(pair) + 1}/#{ranking.length}"
    else
      rankingStrings = ("[#{i + 1}]#{pair[0]}(#{pair[1]})" for pair, i in ranking[0...5])
      robot.messageRoom room, "本日の発言数ランキング: #{rankingStrings.join(', ')}"

  postGeneralReport = (msg) ->
    room = if msg? then msg.message.room else process.env.HUBOT_REPORT_ROOM
    postReport room, rec.getGeneralRecord()

  postUserReport = (msg, userName) ->
    record = rec.getRecord userName
    if record?
      postReport msg.message.room, record, userName
    else
      msg.send "#{userName} さんのデータは見つかりませんでした"

  robot.hear /.+/, (msg) ->
    rec.increment msg.message.user.name

  robot.respond /report\s+(.*)/i, (msg) ->
    postUserReport msg, msg.match[1]

  robot.respond /report\s*$/i, (msg) ->
    postUserReport msg, msg.message.user.name

  robot.respond /general-report\s*$/i, (msg) ->
    postGeneralReport msg

  new CronJob('00 00 19 * * 1-5', postGeneralReport, null, true, 'Asia/Tokyo')
  new CronJob('00 00 00 * * 1-5', (-> rec.reset()), null, true, 'Asia/Tokyo')
