# Commands:
#   hubot summon <channel> - ボットを召喚する
#   hubot dismiss - ボットを帰らせる

module.exports = (robot) ->
  robot.respond /summon\s+(.*)$/i, (msg) ->
    return unless msg.message.user.name is process.env.HUBOT_IRC_REALNAME
    room = msg.match[1]
    return unless room
    robot.adapter.command 'JOIN', room

  robot.respond /dismiss$/i, (msg) ->
    return unless msg.message.user.name is process.env.HUBOT_IRC_REALNAME
    robot.adapter.command 'PART', msg.message.room
