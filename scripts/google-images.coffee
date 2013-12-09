# Commands:
#   hubot image <query> - <query> にマッチした画像を返す
#   hubot animate <query> - <query> にマッチしたアニメーション GIF 画像を返す
#   hubot mustache <url> - <url> にひげをつけた画像を返す
#   hubot mustache <query> - <query> にマッチした画像にひげをつけて返す

module.exports = (robot) ->
  robot.respond /(image|img)( me)? (.*)/i, (msg) ->
    imageMe msg, msg.match[3], (url) ->
      msg.send url

  robot.respond /animate( me)? (.*)/i, (msg) ->
    query = msg.match[2] + ' -site:yahoo-mbga.jp'
    imageMe msg, query, true, (url) ->
      msg.send url

  robot.respond /(?:mo?u)?sta(?:s|c)he?(?: me)? (.*)/i, (msg) ->
    type = Math.floor(Math.random() * 3)
    mustachify = "http://mustachify.me/#{type}?src="
    imagery = msg.match[1]

    if imagery.match /^https?:\/\//i
      msg.send "#{mustachify}#{imagery}"
    else
      imageMe msg, imagery, false, true, (url) ->
        msg.send "#{mustachify}#{url}"

imageMe = (msg, query, animated, faces, cb) ->
  cb = animated if typeof animated == 'function'
  cb = faces if typeof faces == 'function'
  q = v: '1.0', rsz: '8', q: query, safe: 'active'
  q.imgtype = 'animated' if typeof animated is 'boolean' and animated is true
  q.imgtype = 'face' if typeof faces is 'boolean' and faces is true
  msg.http('http://ajax.googleapis.com/ajax/services/search/images')
    .query(q)
    .get() (err, res, body) ->
      images = JSON.parse(body)
      images = images.responseData?.results
      if images?.length > 0
        image  = msg.random images
        cb "#{image.unescapedUrl}#.png"
