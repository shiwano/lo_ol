# Commands:
#   hubot quiz <query> - クイズを出題する

_ = require 'lodash'

class Question
  question:    -> "問題 - #{@data.question}"
  rightAnswer: -> "答えは #{@rightAnswerIndex}:「#{@data.answers[0]}」 でした"
  isYesNo:     -> @data.answers[0] in ['×', '○']

  constructor: (@data, @room) ->
    @answers = {}
    @_answerList = if @isYesNo() then ['○', '×'] else _.shuffle(@data.answers)
    @rightAnswerIndex = _.indexOf(@_answerList, @data.answers[0]) + 1

  answerList: ->
    @_answerList.map((a, i) -> "#{i + 1}:「#{a}」").join(' ')

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

  setQuiz = (msg, url) ->
    return msg.send '解答中なので出題できません' if currentQuestion?

    robot.http(url).get() (err, res, body) ->
      result = msg.random JSON.parse(body)
      currentQuestion = new Question(result, msg.message.room)
      msg.send currentQuestion.question()
      msg.send currentQuestion.answerList()
      setTimeout ->
        # IRC だと、別の channel に誤爆することがあったので messageRoom を使用
        robot.messageRoom currentQuestion.room, currentQuestion.rightAnswer()
        robot.messageRoom currentQuestion.room, currentQuestion.solvers()
        currentQuestion = null
      , 60000

  robot.respond /quiz\s*(.*)?$/i, (msg) ->
    q = msg.match[1]
    if q?
      url = "http://api.quizken.jp/api/quiz-search/api_key/ma7/phrase/#{encodeURIComponent q}/count/50"
    else
      url = 'http://api.quizken.jp/api/quiz-index/api_key/ma7/count/1'
    setQuiz msg, url
