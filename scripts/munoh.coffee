# Description:
#   Chatterbot
#
# URLS:
#   /hubot/munoh

generateHTML = (name, dict, dictUpdatedAt, info = '') ->
  """
<html>
  <head>
    <meta charset="utf-8">
    <title>人工無脳 #{name}</title>
    <link href="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css" rel="stylesheet">
    <script src="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
    <style>
      body {
        padding-top: 70px;
        padding-bottom: 70px;
      }
    </style>
  </head>
  <body>
    <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
      <div class="container">
        <div class="navbar-header">
          <a class="navbar-brand" href="#">人工無脳 #{name}</a>
        </div>
      </div>
    </div>
    <div class="container">
      #{info}
      <form action="" method="post" role="form">
        <div class="form-group">
          <label for="dict">会話に使う辞書</label>
          <textarea id="dict" class="form-control" name="dict" rows="10">#{dict}</textarea>
          <p class="help-block">
            「こんにちは,こんにちは、{name}」のようにカンマ区切りで入力してください。<br />
            {name} は、話しかけた人の名前に置換されます。
          </p>
        </div>
        <input type="hidden" name="dictUpdatedAt" value="#{dictUpdatedAt}">
        <button type="submit" class="btn btn-primary">更新</button>
      </form>
    </div>
  </body>
</html>
  """

class Listener
  constructor: (@regex, @answer) ->

  call: (msg) ->
    if @regex.test msg.message.text
      name = msg.message.user.name
      msg.send @answer.replace '{name}', name

module.exports = (robot) ->
  listeners = []

  updateListeners = ->
    robot.brain.data.munoh ?=
      dictUpdatedAt: 0
      dict: {}
    listeners = []
    for key, value of robot.brain.data.munoh.dict
      regex = new RegExp(".*#{key}.*", 'im')
      listeners.push new Listener(regex, value)

  getHTMLContent = (infoText = null) ->
    dictStrings = ("#{key},#{value}" for key, value of robot.brain.data.munoh.dict)
    dictUpdatedAt = robot.brain.data.munoh.dictUpdatedAt
    info = "<div class=\"alert alert-info\" role=\"alert\">#{infoText}</div>" if infoText?
    generateHTML robot.name, dictStrings.join('\n'), dictUpdatedAt, info

  robot.router.get "/munoh", (req, res) ->
    res.setHeader 'content-type', 'text/html'
    res.end getHTMLContent()

  robot.router.post "/munoh", (req, res) ->
    unless Number(req.body.dictUpdatedAt) is robot.brain.data.munoh.dictUpdatedAt
      res.end '他の人が編集してしまったので更新できませんでした。\nリロードしてやり直してください。'
      return

    robot.brain.data.munoh.dict = {}
    for dictString in req.body.dict.replace('\r', '').split('\n')
      [key, value] = dictString.split(',')
      if key?.length > 0 and value?.length > 0
        robot.brain.data.munoh.dict[key] = value
    robot.brain.data.munoh.dictUpdatedAt = new Date().getTime()
    robot.brain.save()
    updateListeners()
    res.setHeader 'content-type', 'text/html'
    res.end getHTMLContent '辞書を更新しました'

  robot.brain.on 'loaded', -> updateListeners()

  robot.respond /munoh$/i, (msg) ->
    msg.send process.env.HUBOT_MUNOH_URL

  robot.respond /無脳$/i, (msg) ->
    msg.send process.env.HUBOT_MUNOH_URL

  robot.hear /.+/, (msg) ->
    for listener in listeners
      listener.call msg
