# Commands:
#   hubot naruto - オペレータ権限を付与する

module.exports = (robot) ->
  robot.respond /naruto/i, (msg) ->
    robot.adapter.command 'MODE', msg.message.room, '+o', msg.message.user.name
