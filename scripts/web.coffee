# Description:
#   Webutility returns title of urls
#
# Dependencies:
#   "superagent": "0.16.0"
#   "iconv": "2.0.7"
#   "encoding": "0.1.7"
#   "jschardet": "1.1.0"
#   "htmlparser": "1.7.6"
#   "soupselect": "0.2.0"
#   "jsdom": "0.2.14"
#
# Commands:
#   None
#
# Author:
#   KevinTraver
#   Shogo Iwano

Request    = require 'superagent'
Encoding   = require 'encoding'
Jschardet  = require 'jschardet'
Select     = require("soupselect").select
HtmlParser = require "htmlparser"
JSDom      = require "jsdom"

# Decode HTML entities
unEntity = (str) ->
  e = JSDom.jsdom().createElement("div")
  e.innerHTML = str
  if e.childNodes.length == 0 then "" else e.childNodes[0].nodeValue

requestParser = (res, callback) ->
  res.text = ''
  res.setEncoding 'binary'
  res.on 'data', (chunk) -> res.text += chunk
  res.on 'end', ->
    charset = Jschardet.detect(res.text).encoding
    buffer = new Buffer(res.text, 'binary')
    text = Encoding.convert(buffer, 'utf-8', charset).toString()
    callback null, text

module.exports = (robot) ->
  robot.hear /(http|ftp|https):\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:/~\+#]*[\w\-\@?^=%&amp;/~\+#])?/i, (msg) ->
    url = msg.match[0]
    httpResponse = (url) ->
      Request.get(url).parse(requestParser).end (error, res) ->
        return if error?

        if res.status in [301, 302]
          httpResponse(res.header.location)
        else if res.status is 200
          return unless res.header['content-type']?.indexOf('text/html') is 0

          handler = new HtmlParser.DefaultHandler()
          parser  = new HtmlParser.Parser handler
          parser.parseComplete res.body

          # abort if soupselect runs out of stack space
          try
            results = (Select handler.dom, "head title")
          catch RangeError
            return

          processResult = (elem) ->
            unEntity(elem.children[0].data.replace(/(\r\n|\n|\r)/gm,"").trim())

          if results[0]
            msg.send 'Title: ' + processResult(results[0])
          else
            results = (Select handler.dom, "title")
            if results[0]
              msg.send 'Title: ' + processResult(results[0])
        else
          msg.send "Error: " + res.statusCode

    httpResponse(url)
