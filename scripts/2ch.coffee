# Commands:
#   hubot 2ch watch <bbsname> <query> <interval> - <query> にマッチした 2ch スレッドをウォッチする
#   hubot 2ch stop - 現在のルームでの 2ch スレッドのウォッチを停止する

{ThreadWatcher, BbsMenu} = require '2ch'
ent = require 'ent'

module.exports = (robot) ->
  watchers = {}
  bbsMenu = new BbsMenu()

  toMessageString = (message) ->
    date = message.postedAt.format('YYYY/MM/DD HH:mm:ss')
    body = ent.decode(message.body.replace /<[^<>]+>/g, '')
    "[#{message.number}]#{message.name}(#{message.tripId}): #{body}"

  stopWatching = (room) ->
    watchers[room].destroy()
    delete watchers[room]

  startWatching = (room, bbsName, query, interval) ->
    if watchers[room]
      watchers[room].destroy()

    canMessage = false
    watcher = new ThreadWatcher
      bbsName: bbsName
      query: query
      interval: interval
      bbsMenu: bbsMenu
    watcher.on 'update', (messages) ->
      return canMessage = true unless canMessage
      messages.forEach (message) ->
        robot.messageRoom room, toMessageString(message)[0...100]
    watcher.on 'error', (error) ->
      robot.messageRoom room, error.toString()
      stopWatching room
    watcher.on 'reload', (title) ->
      robot.messageRoom room, "「#{title}」スレッドを再読込します"
      canMessage = false
    watcher.on 'begin', (title) ->
      robot.messageRoom room, "「#{title}」スレッドが開始しました"
    watcher.on 'end', (title) ->
      robot.messageRoom room, "「#{title}」スレッドが終了しました"
    watcher.start()
    watchers[room] = watcher

  robot.respond /2ch\s+watch\s+(.*)\s+(.*)\s+([0-9]+)\s*$/i, (msg) ->
    return unless msg.message.user.name in process.env.HUBOT_ADMINS.split(',')
    bbsName = msg.match[1]
    query = new RegExp(msg.match[2])
    interval = Number(msg.match[3] or 180000)
    msg.send "「#{bbsName} 」の「#{query}」にマッチする 2ch スレッドを「#{interval}」の間隔でウォッチします"
    startWatching msg.room, bbsName, query, interval

  robot.respond /2ch\s+stop\s*$/i, (msg) ->
    return unless msg.message.user.name in process.env.HUBOT_ADMINS.split(',')
    stopWatching msg.room
