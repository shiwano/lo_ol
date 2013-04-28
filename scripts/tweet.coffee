# Commands:
#   hubot tweet <keyword> - <keyword> に関連するツイートを返す

module.exports = (robot) ->
  robot.respond /tweet\s+(.*)/i, (msg) ->
    search = escape(msg.match[1])
    msg.http('http://search.twitter.com/search.json')
      .query(q: search)
      .get() (err, res, body) ->
        tweets = JSON.parse(body)

        if tweets.results? and tweets.results.length > 0
          tweet  = msg.random tweets.results
          msg.send "つ http://twitter.com/#!/#{tweet.from_user}/status/#{tweet.id_str}"
        else
          msg.reply "ツイートが見つからなかったよ！"
