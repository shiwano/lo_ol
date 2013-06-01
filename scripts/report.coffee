# Commands:
#   hubot report - IRC 全体の発言数情報を表示する
#   hubot report <username> - 指定したユーザの IRC の発言数情報を表示する

{CronJob} = require 'cron'
moment = require 'moment'
sparkline = require 'sparkline'
_ = require 'lodash'

class Recorder
  constructor: ->
    @_records = {}

  getRecord: (userName) ->
    @_records[userName]

  getOrCreateRecord: (userName) ->
    record = @getRecord userName
    unless record?
      record = (0 for i in [0...48])
      @_records[userName] = record
    record

  getTotalRecord: ->
    totalRecord = (0 for i in [0...48])
    for userName, record of @_records
      for value, index in record
        totalRecord[index] += value
    totalRecord

  increment: (userName, value) ->
    record = @getOrCreateRecord userName
    now = moment()
    part = if now.minute() < 30 then 0 else 1
    record[now.hour() * 2 + part] += value

module.exports = (robot) ->
  rec = new Recorder()

  sum = (array) ->
    _.reduce array, ((memo, num) -> memo + num), 0

  postReport = (msg, record, userName) ->
    prefix = if userName? then "#{userName} さんの" else ''
    commentNum = sum record
    msg.send "#{prefix}本日の総発言数: #{commentNum}"
    msg.send "#{prefix}本日の1時間あたりの平均発言数: #{Math.floor(commentNum / 24 * 100) / 100}"
    msg.send "#{prefix}本日の発言数グラフ: [10時] #{sparkline record[20..38]} [19時]"

  postTotalReport = (msg) ->
    postReport msg, rec.getTotalRecord()

  robot.hear /.+/, (msg) ->
    rec.increment msg.message.user.name, 1

  robot.respond /report\s+(.*)/i, (msg) ->
    userName = msg.match[1]
    record = rec.getRecord userName
    if record?
      postReport msg, record, userName
    else
      msg.send "#{userName} さんのデータは見つかりませんでした"

  robot.respond /report\s*$/i, postTotalReport
  new CronJob('00 00 19 * * 1-5', postTotalReport, null, true, 'Asia/Tokyo')
  new CronJob('00 00 00 * * 1-5', (-> rec = new Recorder()), null, true, 'Asia/Tokyo')
