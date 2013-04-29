# Commands:
#   hubot translate <phrase> - <phrase> の翻訳結果を返す
#   hubot translate from <source> into <target> <phrase> - <phrase> を <source> から <target> の言語へ翻訳した結果を返す。<source> と <target> はオプション

languages =
  "af": "Afrikaans",
  "sq": "Albanian",
  "ar": "Arabic",
  "az": "Azerbaijani",
  "eu": "Basque",
  "bn": "Bengali",
  "be": "Belarusian",
  "bg": "Bulgarian",
  "ca": "Catalan",
  "zh-CN": "Simplified Chinese",
  "zh-TW": "Traditional Chinese",
  "hr": "Croatian",
  "cs": "Czech",
  "da": "Danish",
  "nl": "Dutch",
  "en": "English",
  "eo": "Esperanto",
  "et": "Estonian",
  "tl": "Filipino",
  "fi": "Finnish",
  "fr": "French",
  "gl": "Galician",
  "ka": "Georgian",
  "de": "German",
  "el": "Greek",
  "gu": "Gujarati",
  "ht": "Haitian Creole",
  "iw": "Hebrew",
  "hi": "Hindi",
  "hu": "Hungarian",
  "is": "Icelandic",
  "id": "Indonesian",
  "ga": "Irish",
  "it": "Italian",
  "ja": "Japanese",
  "kn": "Kannada",
  "ko": "Korean",
  "la": "Latin",
  "lv": "Latvian",
  "lt": "Lithuanian",
  "mk": "Macedonian",
  "ms": "Malay",
  "mt": "Maltese",
  "no": "Norwegian",
  "fa": "Persian",
  "pl": "Polish",
  "pt": "Portuguese",
  "ro": "Romanian",
  "ru": "Russian",
  "sr": "Serbian",
  "sk": "Slovak",
  "sl": "Slovenian",
  "es": "Spanish",
  "sw": "Swahili",
  "sv": "Swedish",
  "ta": "Tamil",
  "te": "Telugu",
  "th": "Thai",
  "tr": "Turkish",
  "uk": "Ukranian",
  "ur": "Urdu",
  "vi": "Vietnamese",
  "cy": "Welsh",
  "yi": "Yiddish"

getCode = (language,languages) ->
  for code, lang of languages
      return code if lang.toLowerCase() is language.toLowerCase()

module.exports = (robot) ->
  robot.respond /(?:translate)(?: me)?(?:(?: from) ([a-z]*))?(?:(?: (?:in)?to) ([a-z]*))? (.*)/i, (msg) ->
    term   = "\"#{msg.match[3]}\""
    origin = if msg.match[1] isnt undefined then getCode(msg.match[1], languages) else 'auto'
    target = if msg.match[2] isnt undefined then getCode(msg.match[2], languages) else 'en'

    msg.http("https://translate.google.com/translate_a/t")
      .query({
        client: 't'
        hl: 'en'
        multires: 1
        sc: 1
        sl: origin
        ssel: 0
        tl: target
        tsel: 0
        uptl: "ja"
        text: term
      })
      .header('User-Agent', 'Mozilla/5.0')
      .get() (err, res, body) ->
        data   = body
        if data.length > 4 and data[0] == '['
          parsed = eval(data)
          language =languages[parsed[2]]
          parsed = parsed[0] and parsed[0][0] and parsed[0][0][0]
          if parsed
            if msg.match[2] is undefined
              msg.send "#{term} は #{language} だと #{parsed} です"
            else
              msg.send "#{language} の #{term} は、 #{languages[target]} だと #{parsed} です"
