# Description:
#   Commands for clan war preparation and planning.
#
# Dependencies:
#   "jsonfile": "~2.2.3"
#   "util": "^0.10.3"
#   "moment": "~2.12.0"
#   "moment-duration-format": "~1.3.0"
#
# Commands:
#   hubot timeleft - Prints the time left until war starts or ends

jsonfile = require('jsonfile')
util = require('util')
moment = require('moment')
require('moment-duration-format')

# Begin robot
module.exports = (robot) ->

  # /timeleft
  robot.respond /timeleft/i, (res) ->
    currentTime = moment()
    botData = loadFile()
    endTime = moment(botData.time, "X")
    timeDiff = endTime.diff(currentTime, 'seconds')
    diffMinutes = moment.duration(timeDiff, "seconds").format("m [minutes,] s [seconds]")
    diffHours = moment.duration(timeDiff, "seconds").format("h [hours,] m [minutes]")

    switch
      when timeDiff < 0 then res.send "The previous war ended #{endTime.fromNow()}"
      when timeDiff >= 0 and timeDiff < 30 then res.send "The war will end in #{endTime.fromNow()}"
      when timeDiff >= 30 and timeDiff < 3600 then res.send "The war will end in #{diffMinutes}"
      when timeDiff >= 3600 and timeDiff < 86400 then res.send "The war will end in #{diffHours}"
      when timeDiff >= 86400 and timeDiff < 169200
        startTime = endTime.subtract(1, 'days')
        startDiff = startTime.diff(currentTime, 'seconds')
        startMinutes = moment.duration(startDiff, "seconds").format("m [minutes,] s [seconds]")
        startHours = moment.duration(startDiff, "seconds").format("h [hours,] m [minutes]")
        switch
          when startDiff >= 0 and startDiff < 5 then res.send "The war is starting NOW!"
          when startDiff >= 5 and startDiff < 3600 then res.send "The war will start in #{startMinutes}"
          when startDiff >= 3600 and startDiff < 82800 then res.send "The war will start in #{startHours}"
          else res.send "If you get this message, something has gone horribly wrong."
      else res.send "If you get this message, something has gone horribly wrong."

loadFile = ->
  filePath = 'bot_data.json'
  fileData = jsonfile.readFileSync(filePath)

saveFile = (dataObj) ->
  jsonfile.writeFileSync('bot_data.json', dataObj)
