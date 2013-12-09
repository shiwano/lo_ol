# Commands:
#   hubot 2ch watch <bbsname> /<query>/ - <query> にマッチした 2ch スレッドを監視する
#   hubot 2ch stop - 現在のルームでの 2ch スレッドの監視を停止する

{ThreadWatcher, BbsMenu} = require '2ch'
ent = require 'ent'

module.exports = (robot) ->
  watchers = {}

  toMessageString = (message) ->
    name = message.name.replace /<[^<>]+>/g, ''
    body = message.body.replace /<[^<>]+>/g, ''
    body = ent.decode(body).replace /([^h]|^)ttp:\/\//, '$1http://'
    "[#{message.number}] #{name} (#{message.tripId}): #{body}"

  stopWatching = (room) ->
    robot.messageRoom room, '2ch スレッドの監視をストップします'
    watchers[room].stop()
    delete watchers[room]

  startWatching = (room, bbsName, query, interval=600000) ->
    watchers[room].stop() unless watchers[room]?
    watcher = new ThreadWatcher(bbsName, query, interval)
    loaded = false

    watcher.on 'update', (messages) ->
      return loaded = true unless loaded
      messages.forEach (message) ->
        string = toMessageString(message)
        for i in [0...Math.ceil(string.length / 150)]
          robot.messageRoom room, string[150 * i...150 * (i + 1)]

    watcher.on 'error', (error) ->
      robot.messageRoom room, "エラーが発生しました(#{error.toString()})"
      watchers[room].stop()

    watcher.on 'reload', (title) ->
      robot.messageRoom room, "「#{title}」スレッドを再読込します"
      loaded = false

    watcher.on 'begin', (title) ->
      robot.messageRoom room, "「#{title}」スレッドが開始しました"

    watcher.on 'end', (title) ->
      robot.messageRoom room, "「#{title}」スレッドが終了しました"

    robot.messageRoom room, "#{bbsName} 板の #{query.toString()} にマッチする 2ch スレッドを #{interval} ミリ秒の間隔で監視します"
    watcher.start()
    watchers[room] = watcher

  robot.respond /2ch\s+stop\s*$/i, (msg) ->
    return unless msg.message.user.name in process.env.HUBOT_ADMINS.split(',')
    stopWatching msg.message.room

  robot.respond /2ch\s+watch\s+(.*)\s+\/(.*)\/\s*$/i, (msg) ->
    return unless msg.message.user.name in process.env.HUBOT_ADMINS.split(',')
    bbsName = msg.match[1]
    query = new RegExp(msg.match[2])
    startWatching msg.message.room, bbsName, query

  robot.respond /2ch\s+watch\s*$/i, (msg) ->
    return unless msg.message.user.name in process.env.HUBOT_ADMINS.split(',')
    return unless process.env.HUBOT_2CH_WATCHED_THREAD
    for threadString in process.env.HUBOT_2CH_WATCHED_THREADS.split('\n')
      match = /^([^\s]+)\s+(.*)\s+\/(.*)\/\s*$/.exec threadString
      room = match[1]
      bbsName = match[2]
      query = new RegExp(match[3])
      startWatching room, bbsName, query
