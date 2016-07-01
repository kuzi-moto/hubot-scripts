# Description:
#   Commands for clan war preparation and planning.
#
# Dependencies:
#   "jsonfile": "~2.2.3"
#   "util": "^0.10.3"
#
# Commands:
#   hubot setcc (<link> | <war id>) - Sets the ClashCaller link
#   hubot cc - Prints the ClashCaller link
#   hubot setws <link> - Sets the war sheet
#   hubot ws - Prints the war sheet
#   hubot cw - Prints the ClashCaller and War Sheet

jsonfile = require('jsonfile')
util = require('util')

# Begin robot
module.exports = (robot) ->

  robot.respond /setcc\s?(.*)/i, (res) ->
    someText = res.match[1]
    if someText.length > 0
      res.send checkCCLink(someText)
    else
      res.send "Usage: /setcc http://clashcaller.com/war/abc12 \n /setcc abc12"

  robot.respond /cc/i, (res) ->
    botData = loadFile()
    res.send "http://clashcaller.com/war/#{botData.clashcaller}"

  robot.respond /setws\s?(.*)/i, (res) ->
    someText = res.match[1]
    if someText.length > 0
      res.send checkWSLink(someText)
    else
      res.send "Usage: /setws https://i.groupme.com/image-uploaded-to-groupme"

  robot.respond /ws/i, (res) ->
    botData = loadFile()
    res.send botData.warsheet

  robot.respond /cw/i, (res) ->
    botData = loadFile()
    res.send botData.clashcaller
    res.send botData.warsheet

checkCCLink = (linkText) ->
  linkTest = /^http:\/\/(?:www.)?clashcaller.com\/war\/[\w\d][\w\d][\w\d][\w\d][\w\d]$/i.test(linkText)
  idTest = /^[\w\d][\w\d][\w\d][\w\d][\w\d]$/i.test(linkText)
  if linkTest is true
    warCode = linkText.match(/war\/(.*)/)
    botData = loadFile()
    botData.clashcaller = warCode[1]
    console.log(warCode)
    saveFile(botData)
    return "ClashCaller link saved!"
  else if idTest is true
    botData = loadFile()
    botData.clashcaller = linkText
    saveFile(botData)
    return "ClashCaller ID saved!"
  else
    return "Sorry '#{linkText}' is not a valid ClashCaller link."

checkWSLink = (linkText) ->
  match = /^https?:\/\/i.groupme.com\//i.test(linkText)
  if match is true
    botData = loadFile()
    botData.warsheet = linkText
    saveFile(botData)
    return "War Sheet link saved!"
  else
    return "Sorry '#{linkText}' is not a valid War Sheet link."

loadFile = ->
  filePath = 'bot_data.json'
  fileData = jsonfile.readFileSync(filePath)

saveFile = (dataObj) ->
  jsonfile.writeFileSync('bot_data.json', dataObj)
