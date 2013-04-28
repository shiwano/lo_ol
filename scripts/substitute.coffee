# Commands:
#   hubot sub <pattern> - 前のメッセージを <pattern> で置換して返す

module.exports = (robot) ->
  lastMessages = {}

  robot.hear /.+/, (msg) ->
    return if /s\/([^/]*)\/([^/]*)\//.test msg.message.text
    lastMessages[msg.message.user.name] = msg.message.text

  replaceText = (msg) ->
    lastMessage = lastMessages[msg.message.user.name]
    unless lastMessage
      return msg.send "#{msg.message.user.name} さんの前のメッセージを覚えてないので置換できません"

    result = lastMessage.replace (new RegExp msg.match[1]), msg.match[2]
    msg.send "#{msg.message.user.name}: #{result}"

  robot.respond /sub\s+s\/([^/]*)\/([^/]*)\/\s*/i, replaceText
  robot.hear /^s\/([^/]*)\/([^/]*)\/\s*/i, replaceText
