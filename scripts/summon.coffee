# Commands:
#   hubot summon <channel> - ボットを召喚する
#   hubot dismiss - ボットを帰らせる

module.exports = (robot) ->
  robot.respond /summon\s+(.+)$/i, (msg) ->
    robot.adapter.command 'JOIN', room

  robot.respond /dismiss$/i, (msg) ->
    robot.adapter.command 'PART', msg.message.room
