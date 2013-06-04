# Commands:
#   hubot general-report - IRC 全体の発言数情報を表示する
#   hubot report - 発言した ユーザ のIRC 発言数情報を表示する
#   hubot report <username> - 指定したユーザの IRC 発言数情報を表示する

{CronJob} = require 'cron'
moment = require 'moment'
sparkline = require 'sparkline'
_ = require 'lodash'

class Recorder
  constructor: ->
    @_records = {}
    @_rankingRecords = {}

  getRecord: (userName) ->
    @_records[userName]

  getOrCreateRecord: (userName) ->
    record = @getRecord userName
    unless record?
      record = (0 for i in [0...48])
      @_records[userName] = record
    record

  getGeneralRecord: ->
    generalRecord = (0 for i in [0...48])
    for userName, record of @_records
      for value, index in record
        generalRecord[index] += value
    generalRecord

  getRanking: ->
    pairs = _.pairs @_rankingRecords
    _.sortBy(pairs, (pair) -> pair[1]).reverse()

  increment: (userName, value=1) ->
    unless @_rankingRecords[userName]?
      @_rankingRecords[userName] = 0
    @_rankingRecords[userName] += value

    record = @getOrCreateRecord userName
    now = moment()
    part = if now.minute() < 30 then 0 else 1
    record[now.hour() * 2 + part] += value

module.exports = (robot) ->
  rec = new Recorder()

  postReport = (room, record, userName) ->
    prefix = if userName? then "#{userName} さんの" else ''
    total = _.reduce record, ((memo, num) -> memo + num), 0
    ranking = rec.getRanking()

    robot.messageRoom room, "#{prefix}本日の総発言数: #{total}"
    robot.messageRoom room, "#{prefix}本日の1時間あたりの平均発言数: #{Math.floor(total / 24 * 100) / 100}"
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
  new CronJob('00 00 00 * * 1-5', (-> rec = new Recorder()), null, true, 'Asia/Tokyo')
