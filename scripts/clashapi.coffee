# Description:
#   Clash of Clans API
#
# Dependencies:
#
# Commands:
#

jsonfile = require('jsonfile')
util = require('util')
queryString = require('query-string')

authKey = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiIsImtpZCI6IjI4YTMxOGY3LTAwMD
AtYTFlYi03ZmExLTJjNzQzM2M2Y2NhNSJ9.eyJpc3MiOiJzdXBlcmNlbGwiLCJhdWQiOiJzdXBlcmNlb
Gw6Z2FtZWFwaSIsImp0aSI6IjFlNzRlMjViLTg4YTAtNDRlNS05ZTY1LTZiMjQ2Mzk0NmQ4NCIsImlhd
CI6MTQ2MzUwMzI1OCwic3ViIjoiZGV2ZWxvcGVyLzI1MzYwOTNkLTdiYTAtZjdiOC04YzM1LTg0MTIzZ
GNlNWI5YSIsInNjb3BlcyI6WyJjbGFzaCJdLCJsaW1pdHMiOlt7InRpZXIiOiJkZXZlbG9wZXIvc2lsd
mVyIiwidHlwZSI6InRocm90dGxpbmcifSx7ImNpZHJzIjpbIjEwNy4xNTUuMTE2LjYxIl0sInR5cGUiO
iJjbGllbnQifV19.c48ZWnGWBfJWTtcVLuBghoqK-14m0pbiP8QUiCCwot6GYFzmheyg6SkXJNcdULpP
k0jjH_7BDKrok1MXGdxxPg"

module.exports = (robot) ->
  robot.respond /test ?(.*)?/i, (msg) ->
    toParse = {}
    toParse.clanTag = msg.match[1]
    queryData = queryString.stringify(toParse.clanTag)
    robot.http("https://api.clashofclans.com/v1/clans/#{queryData}")
    #robot.http("https://api.clashofclans.com/v1/clans/%232GRY8029")
      .header('Accept', 'application/json')
      .header('authorization', authKey)
      .get() (err, res, body) ->
        msg.send body
        console.log "body: " + body
        console.log "queryData: " + queryData

#botData = loadFile()
#toparse = {}
#toParse.REQUEST = "GET_FULL_UPDATE"
#toParse.warcode = botData.clashcaller
#data = queryString.stringify(toParse)

loadFile = ->
  filePath = 'bot_data.json'
  fileData = jsonfile.readFileSync(filePath)

saveFile = (dataObj) ->
  jsonfile.writeFileSync('random_data.json', dataObj)
