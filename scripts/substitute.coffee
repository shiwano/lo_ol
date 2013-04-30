# Commands:
#   hubot sub <pattern> - 前のメッセージを <pattern> で置換して返す

module.exports = (robot) ->
  lastMessages = {}
  regexStr = 's/(([^/]|\\/)*)/(([^/]|\\/)*)/([ig]*)'
  regex = new RegExp(regexStr)

  robot.hear /.+/, (msg) ->
    return if regex.test msg.message.text
    lastMessages[msg.message.user.name] = msg.message.text

  substituteText = (msg) ->
    lastMessage = lastMessages[msg.message.user.name]
    unless lastMessage
      return msg.send "#{msg.message.user.name} さんの前のメッセージを覚えてないので置換できません"

    result = lastMessage.replace (new RegExp msg.match[1], msg.match[5]), msg.match[3]
    msg.send "#{msg.message.user.name}: #{result}"

  robot.respond (new RegExp "sub #{regexStr}$", 'i'), substituteText
  robot.hear (new RegExp "^#{regexStr}$"), substituteText
