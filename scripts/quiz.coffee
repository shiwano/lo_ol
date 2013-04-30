# Commands:
#   hubot quiz<time> <query> - クイズを出題する

_ = require 'lodash'

class Question
  constructor: (@data, @room, @time) ->
    @answers = {}
    @_answerList = if @isYesNo() then ['○', '×'] else _.shuffle(@data.answers)
    @rightAnswerIndex = _.indexOf(@_answerList, @data.answers[0]) + 1

  question:    -> "問題 - #{@data.question} (制限時間#{@time}秒)"
  answerList:  -> @_answerList.map((a, i) -> "#{i + 1}:「#{a}」").join(' ')
  rightAnswer: -> "答えは #{@rightAnswerIndex}:「#{@data.answers[0]}」 でした"
  isYesNo:     -> @data.answers[0] in ['×', '○']

  solvers: ->
    solvers = []
    for solver, answerIndex of @answers
      solvers.push solver + ' さん' if answerIndex is @rightAnswerIndex
    if solvers.length is 0
      '正解者はいませんでした'
    else
      "正解者は、#{solvers.join(', ')}"

module.exports = (robot) ->
  currentQuestion = null

  robot.hear /[1-4]$/, (msg) ->
    return unless currentQuestion?.room is msg.message.room
    currentQuestion.answers[msg.message.user.name] = Number msg.message.text

  setQuiz = (msg, url, time) ->
    return msg.send '解答中なので出題できません' if currentQuestion?

    robot.http(url).get() (err, res, body) ->
      result = JSON.parse body
      return msg.send '問題が見つかりませんでした' if result.length is 0

      quizData = msg.random result
      currentQuestion = new Question(quizData, msg.message.room, time)
      msg.send currentQuestion.question()
      msg.send currentQuestion.answerList()
      setTimeout ->
        # IRC だと、別の channel に誤爆することがあったので messageRoom を使用
        robot.messageRoom currentQuestion.room, currentQuestion.rightAnswer()
        robot.messageRoom currentQuestion.room, currentQuestion.solvers()
        currentQuestion = null
      , time * 1000

  robot.respond /quiz(\d*)\s*(.*)?$/i, (msg) ->
    time = Number(msg.match[1]) or 60
    time = 60 if time > 60
    q = msg.match[2]
    if q?
      url = "http://api.quizken.jp/api/quiz-search/api_key/ma7/phrase/#{encodeURIComponent q}/count/50"
    else
      url = 'http://api.quizken.jp/api/quiz-index/api_key/ma7/count/1'
    setQuiz msg, url, time
