# Commands:
#   hubot nick - nickname を変える

_ = require 'lodash'
{CronJob} = require 'cron'
{TextListener} = require 'hubot'

module.exports = (robot) ->
  faces = do ->
    mouths = ['o', 'x', 'q', 'w', '_', 'A', 'v', 'r', 'm', 'c']
    eyes = ['^', 'o', 'T', '-']
    faces = []
    for eye in eyes
      for mouth in mouths
        faces.push "[#{eye}#{mouth}#{eye}]"
    faces

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

  changeNickname = ->
    nickname = chooseByRandom faces
    textListeners = robot.listeners.filter (l) -> l instanceof TextListener
    robot.listeners = _.difference robot.listeners, textListeners

    for listener in textListeners
      regex = replaceRegExp listener.regex, robot.name, nickname
      newListener = new TextListener(robot, regex, listener.callback)
      robot.listeners.push newListener

    robot.adapter.command 'NICK', nickname
    robot.name = nickname

  robot.respond /nick/i, changeNickname
  job = new CronJob('00 00 10,13,16,19 * * 1-5', changeNickname, null, true, 'Asia/Tokyo')
