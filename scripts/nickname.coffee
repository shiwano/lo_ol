# Commands:
#   hubot nick - nickname を変える

_ = require 'lodash'
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

  quoteRegExp = (s) -> s.replace(/([.?*+^$[\]\\(){}|-])/g, "\\$1")

  replaceRegExp = (regex, oldStr, newStr) ->
    re = regex.toString().split('/')
    re.shift()
    modifiers = re.pop()
    re = re.join('/').replace quoteRegExp(oldStr), quoteRegExp(newStr)
    new RegExp(re, modifiers)

  robot.respond /nick/i, (msg) ->
    nickname = msg.random faces
    textListeners = robot.listeners.filter (l) -> l instanceof TextListener
    robot.listeners = _.difference robot.listeners, textListeners

    for listener in textListeners
      regex = replaceRegExp listener.regex, robot.name, nickname
      newListener = new TextListener(robot, regex, listener.callback)
      robot.listeners.push newListener

    robot.adapter.command 'NICK', nickname
    robot.name = nickname
