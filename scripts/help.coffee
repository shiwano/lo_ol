# Description:
#   Generates help commands for Hubot.
#
# Commands:
#   hubot help - 使用できるコマンドの一覧を表示
#   hubot help <query> - <query> にマッチしたコマンドのヘルプを表示
#
# URLS:
#   /hubot/help
#
# Notes:
#   These commands are grabbed from comment blocks at the top of each file.

_ = require 'lodash'
helpContents = (name, commands) ->

  """
<html>
  <head>
  <title>#{name} Help</title>
  <style type="text/css">
    body {
      background: #d3d6d9;
      color: #636c75;
      text-shadow: 0 1px 1px rgba(255, 255, 255, .5);
      font-family: Helvetica, Arial, sans-serif;
    }
    h1 {
      margin: 8px 0;
      padding: 0;
    }
    .commands {
      font-size: 13px;
    }
    p {
      border-bottom: 1px solid #eee;
      margin: 6px 0 0 0;
      padding-bottom: 5px;
    }
    p:last-child {
      border: 0;
    }
  </style>
  </head>
  <body>
    <h1>#{name} Help</h1>
    <div class="commands">
      #{commands}
    </div>
  </body>
</html>
  """

module.exports = (robot) ->
  robot.respond /help\s*(.*)?$/i, (msg) ->
    cmds = robot.helpCommands()

    if msg.match[1]
      cmds = cmds.filter (cmd) ->
        cmd.match new RegExp(msg.match[1], 'i')

      if cmds.length == 0
        msg.send "#{msg.match[1]} というコマンドはありません"
        return
    else
      cmds = cmds.map (cmd) -> cmd.split(' ')[1]
      cmds = _.uniq cmds, true

    emit = cmds.join " | "

    unless robot.name.toLowerCase() is 'hubot'
      emit = emit.replace /hubot/ig, robot.name

    msg.send emit

  robot.router.get "/help", (req, res) ->
    cmds = robot.helpCommands().map (cmd) ->
      cmd.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')

    emit = "<p>#{cmds.join '</p><p>'}</p>"

    emit = emit.replace /hubot/ig, "<b>#{robot.name}</b>"

    res.setHeader 'content-type', 'text/html'
    res.end helpContents robot.name, emit
