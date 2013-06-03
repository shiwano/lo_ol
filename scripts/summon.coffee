# Commands:
#   hubot summon <channel> - ボットを召喚する
#   hubot dismiss - ボットを帰らせる

module.exports = (robot) ->
  robot.respond /summon\s+(.*)$/i, (msg) ->
    admins = process.env.HUBOT_ADMINS.split ','
    return unless msg.message.user.name in admins
    room = msg.match[1]
    return unless room
    robot.adapter.command 'JOIN', room

  robot.respond /dismiss$/i, (msg) ->
    admins = process.env.HUBOT_ADMINS.split ','
    return unless msg.message.user.name in admins
    robot.adapter.command 'PART', msg.message.room
