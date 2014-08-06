# Description:
#   Chatterbot
#
# URLS:
#   /hubot/munoh

generateHTML = (name, dict, dictUpdatedAt, info = '') ->
  """
<html>
  <head>
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
          <p class="help-block">「元気？,元気ですよ」のようにカンマ区切りで入力してください</p>
        </div>
        <input type="hidden" name="dictUpdatedAt" value="#{dictUpdatedAt}">
        <button type="submit" class="btn btn-primary">Submit</button>
      </form>
    </div>
  </body>
</html>
  """

module.exports = (robot) ->
  robot.brain.data.munoh ?=
    dictUpdatedAt: 0
    dict: {}
  robot.brain.save()

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
    res.setHeader 'content-type', 'text/html'
    res.end getHTMLContent '辞書を更新しました'

  robot.hear /.+/, (msg) ->
    answer = robot.brain.data.munoh.dict[msg.message.text]
    return unless answer?
    msg.send answer
