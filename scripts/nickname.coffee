# Commands:
#   hubot nick - nickname を変える

_ = require 'lodash'
{CronJob} = require 'cron'
{TextListener} = require 'hubot'

module.exports = (robot) ->
  faces = do ->
    mouths = ['o', 'x', 'q', 'w', '_', 'A', 'v', 'r', 'm', 'c', 'L']
    eyes = ['^', 'O', 'T', '-', '`', '^-', '進捗']
    faces = []
    for eye in eyes
      for mouth in mouths
        if eye.length is 2
          faces.push "[#{eye[0]}#{mouth}#{eye[1]}]"
        else
          faces.push "[#{eye}#{mouth}#{eye}]"
    faces.push '[o_o]'
    faces

  hands = ['9m', 'v', 'o']

  chooseByRandom = (array) ->
    array[_.random(0, array.length - 1)]

  quoteRegExp = (s) ->
    s.replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1")

  replaceRegExp = (regex, oldStr, newStr) ->
    re = regex.toString().split('/')
    re.shift()
    modifiers = re.pop()
    re = re.join('/').replace quoteRegExp(oldStr), quoteRegExp(newStr)
    new RegExp(re, modifiers)

  getNickname = ->
    nickname = chooseByRandom faces
    if _.random(0, 2) is 0
      nickname += chooseByRandom hands
    nickname

  updateNickname = ->
    nickname = getNickname()
    textListeners = robot.listeners.filter (l) -> l instanceof TextListener
    robot.listeners = _.difference robot.listeners, textListeners

    for listener in textListeners
      regex = replaceRegExp listener.regex, robot.name, nickname
      newListener = new TextListener(robot, regex, listener.callback)
      robot.listeners.push newListener

    robot.adapter.command 'NICK', nickname
    robot.name = nickname

  robot.respond /nick/i, updateNickname
  new CronJob('00 00 10,13,16,19 * * 1-5', updateNickname, null, true, 'Asia/Tokyo')
