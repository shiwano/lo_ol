# Commands:
#   hubot ping - pong
#   hubot echo <text> - <text> をそのまま返す
#   hubot time - 現在の時刻を返す
#   hubot die - Bot のプロセスを終了させる

module.exports = (robot) ->
  robot.respond /PING$/i, (msg) ->
    msg.send "PONG"

  robot.respond /ECHO (.*)$/i, (msg) ->
    msg.send msg.match[1]

  robot.respond /TIME$/i, (msg) ->
    msg.send "つ #{new Date()}"

  robot.respond /DIE$/i, (msg) ->
    msg.send "Goodbye, cruel world."
    # process.exit 0
