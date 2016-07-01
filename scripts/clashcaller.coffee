# Description:
#   Commands for accessing ClashCaller.com api.
#
# Dependencies:
#   "jsonfile": "~2.2.3"
#   "util": "^0.10.3"
#   "query-string": "~3.0.3"
#   "moment": "~2.12.0"
#   "moment-duration-format": "~1.3.0"
#
# Commands:
#   hubot createwar <name> <size> - (beta) Creates a new war in ClashCaller.
#   hubot setwarstart <time> [<time>] - (beta)  Sets the start time of the war.
#   hubot setwarend <time> [<time>] - (beta) Sents the end time of the war.
#   hubot call <target> [<name>] - (beta) Calls a base on ClashCaller.
#   hubot targetname <position> <name> - (beta) Sets the enemy name on ClashCaller.
#   hubot changeclan <name> <tag> - (beta) Changes the clan name and tag for Clashcaller.
#   hubot updatestars - (todo) Updates stars for a target on ClashCaller.
#   hubot check - (todo) Checks ClashCaller for a target to see if it's called.

jsonfile = require('jsonfile')
util = require('util')
queryString = require('query-string')
_ = require('lodash')
moment = require('moment')
require('moment-duration-format')

# Begin robot
module.exports = (robot) ->
  toParse = {}

  robot.respond ///
  createwar                 # Primary command
  (?:\s                     # Begin non-capture group for everything
  (.{1,15})\s               # Match 1, any 15 characters for clan name
  \#([\w\d]{1,10})\s        # Match 2, digit or character for clan tag
  (10|15|20|25|30|40|50)    # Match 3, for war size
  |(.+)?                    # Or, Match 4 for anything different
  )?///i, (msg) ->          # End non-capture group, case-insensitive.
    if msg.match[4] isnt undefined
      msg.send "Sorry, \"#{msg.match[4]}\" is not a valid input. " +
      "Please enter as \"<enemy name> <enemy tag> <war size>\""
    if msg.match[1] is undefined and msg.match[4] is undefined
      msg.send "Usage: /createwar <enemy name> <enemy tag> <war size>"
    if msg.match[1]?
      botData = loadFile()
      enemyName = msg.match[1]
      warSize = msg.match[3]
      toParse.REQUEST = "CREATE_WAR"
      toParse.cname = botData.clanname
      toParse.ename = enemyName
      toParse.size = warSize
      toParse.timer = -4
      toParse.searchable = 1
      toParse.clanid = botData.clanid
      toParse.enemyid = msg.match[2] if msg.match[2]?
      data = queryString.stringify(toParse)

      robot.http("http://clashcaller.com/api.php")
        .header('Content-Type', 'application/x-www-form-urlencoded')
        .post(data) (err, res, body) ->
          robot.logger.debug body
          if err
            robot.logger.error err
            return robot.emit 'error', err, msg
          try
            if res.statusCode is 200
              robot.logger.debug "body: #{body}"
            else
              return robot.emit 'error', "#{res.statusCode}: #{body}", msg
          catch error
            robot.logger.error error
            return msg.send "Error! #{body}"
          warCode = body.match(/war\/(.*)/)
          botData = loadFile()
          botData.clashcaller = warCode[1]
          saveFile(botData)
          msg.send "Created  war \"#{toParse.cname} Vs. #{toParse.ename}\" " +
          "with #{warSize} members. Clashcaller has been saved as " +
          "\"http://clashcaller.com/war/#{warCode[1]}\". " +
          "Please set the correct start time with /setwarstart."

  robot.respond ///
  setwarstart         # Primary command
  (?:\s               # Begin non-capture group for everything
  (\d{1,2}[hms])?\s?  # Match 1, 1 or 2 digits, and h, m, or s
  (\d{1,2}[ms])?$     # Match 2, 1 or 2 digits, and m, or s
  |(.+)               # Match everything else
  )?///i, (msg) ->    # End group and command, case-insensitive
    currentTime = moment()
    firstParm = msg.match[1]
    secondParm = msg.match[2]
    thirdParm = msg.match[3]
    botData = loadFile()

    toparse = {}
    toParse.REQUEST = "GET_FULL_UPDATE"
    toParse.warcode = botData.clashcaller
    data = queryString.stringify(toParse)
    robot.http("http://www.clashcaller.com/api.php")
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, res, body) ->
        if match = /Invalid War ID\./.test(body)
          if !firstParm? and !secondParm?
            msg.send """
                     Usage: /setwarstart <time> [<time>]
                     Ex. /setwarstart 20h 43m
                     Ex. /setwarstart 12m
                     """
          else
            msg.send "Sorry, the ClashCaller link seems to be invalid. Please
              re-set the ClashCaller ID."
        else
          switch
            when thirdParm? then msg.send "Sorry, '#{thirdParm}' is not a " +
              "valid input. Please use the format 'xxH yyM'"
            when firstParm?
              if secondParm?
                if match = /h/i.test(firstParm) and
                match = /[ms]/i.test(secondParm)
                  timeHours = parseInt(firstParm)
                  if match = /[m]/i.test(secondParm)
                    timeMinutes = parseInt(secondParm)
                  else timeSeconds = parseInt(secondParm)
                else if match = /m/i.test(firstParm) and
                match = /s/i.test(secondParm)
                  timeMinutes = parseInt(firstParm)
                  timeSeconds = parseInt(secondParm)
                else if match = /m/i.test(firstParm) and
                match = /s/i.test(secondParm)
                  msg.send "Detected both inputs as minutes. Please use hours" +
                  " before minutes, and minutes before seconds."
                else if match = /s/i.test(firstParm) and
                match = /s/i.test(secondParm)
                  msg.send "Detected both inputs as seconds.
                    Please make sure to enter minutes before seconds."
                else
                  msg.send "Please re-check your input. " +
                  "Use format xxH yyM, or xxM yyS."
                  return

              if match = /h/i.test(firstParm)
                timeHours = parseInt(firstParm) unless secondParm?
              if match = /m/i.test(firstParm)
                timeMinutes = parseInt(firstParm) unless secondParm?
              if match = /s/i.test(firstParm)
                timeSeconds = parseInt(firstParm) unless secondParm?

              timeHours = 0 unless timeHours?
              timeMinutes = 0 unless timeMinutes?
              timeSeconds = 0 unless timeSeconds?
              startTime = moment().add(timeHours, 'hours').add(timeMinutes, 'minutes').add(timeSeconds, 'seconds')
              timeDiff = startTime.diff(moment(), 'seconds')
              if timeDiff <= 82800
                diffHuman = moment.duration(timeDiff, "seconds").format("h [hours,] m [minutes,] s [seconds]")
                endTime = startTime.add(1, 'days')
                botData.time = moment(endTime).unix()
                saveFile(botData)

                toParse.REQUEST = "UPDATE_WAR_TIME"
                toParse.warcode = botData.clashcaller
                toParse.start = "s"
                toParse.minutes = (timeHours*60)+(timeMinutes)
                accessApi(toParse)

                msg.send "You have set the war to start in #{diffHuman}"
              else msg.send "Enter a time less than or equal to 23 Hours."
            else msg.send """
                          Usage: /setwarstart <time> [<time>]
                          Ex. /setwarstart 20h 43m
                          """

  robot.respond ///
  setwarend           # Primary command
  (?:\s               # Begin non-capture group for everything
  (\d{1,2}[hms])?\s?  # Match 1, 1 or 2 digits, and h, m, or s
  (\d{1,2}[ms])?$     # Match 2, 1 or 2 digits, and m, or s
  |(.+)               # Match everything else
  )?///i, (msg) ->    # End group and command, case-insensitive
    firstParm = msg.match[1]
    secondParm = msg.match[2]
    thirdParm = msg.match[3]
    botData = loadFile()

    toparse = {}
    toParse.REQUEST = "GET_FULL_UPDATE"
    toParse.warcode = botData.clashcaller
    data = queryString.stringify(toParse)
    robot.http("http://www.clashcaller.com/api.php")
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, res, body) ->
        if match = /Invalid War ID\./.test(body)
          if !firstParm? and !secondParm?
            msg.send """
                     Usage: /setwarend <time> [<time>]
                     Ex. /setwarend 20h 43m
                     Ex. /setwarend 12m
                     """
          else
            msg.send "Sorry, the ClashCaller link seems to be invalid. " +
              "Please re-set the ClashCaller ID."
        else
          switch
            when thirdParm? then msg.send "Sorry, '#{thirdParm}' is not a " +
                                 "valid input. Please use the format 'xxH yyM'"
            when firstParm?
              if secondParm?
                if match = /h/i.test(firstParm) and
                match = /[ms]/i.test(secondParm)
                  timeHours = parseInt(firstParm)
                  if match = /[m]/i.test(secondParm)
                    timeMinutes = parseInt(secondParm)
                  else timeSeconds = parseInt(secondParm)
                else if match = /m/i.test(firstParm) and
                match = /s/i.test(secondParm)
                  timeMinutes = parseInt(firstParm)
                  timeSeconds = parseInt(secondParm)
                else if match = /m/i.test(firstParm) and
                match = /s/i.test(secondParm)
                  msg.send "Detected both inputs as minutes. Please use hours" +
                  " before minutes, and minutes before seconds."
                else if match = /s/i.test(firstParm) and
                match = /s/i.test(secondParm)
                  msg.send "Detected both inputs as seconds.
                    Please make sure to enter minutes before seconds."
                else
                  msg.send "Please re-check your input.
                    Use format xxH yyM, or xxM yyS."
                  return

              if match = /h/i.test(firstParm)
                timeHours = parseInt(firstParm) unless secondParm?
              if match = /m/i.test(firstParm)
                timeMinutes = parseInt(firstParm) unless secondParm?
              if match = /s/i.test(firstParm)
                timeSeconds = parseInt(firstParm) unless secondParm?

              timeHours = 0 unless timeHours?
              timeMinutes = 0 unless timeMinutes?
              timeSeconds = 0 unless timeSeconds?
              endTime = moment().add(timeHours, 'hours').add(timeMinutes, 'minutes').add(timeSeconds, 'seconds')
              botData.time = moment(endTime).unix()
              timeDiff = endTime.diff(moment(), 'seconds')
              diffHuman = moment.duration(timeDiff, "seconds").format("h [hours,] m [minutes,] s [seconds]")
              saveFile(botData)

              toParse.REQUEST = "UPDATE_WAR_TIME"
              toParse.warcode = botData.clashcaller
              toParse.start = "e"
              toParse.minutes = (timeHours*60)+(timeMinutes)
              accessApi(toParse)

              msg.send "You have set the war to end in #{diffHuman}"
            else msg.send """
                          Usage: /setwarend <time> [<time>]
                          Ex. /setwarend 20h 43m"
                          """

  robot.respond ///
  targetname      # Primary command
  (?:\s           # Begin non-capture group
  (\d\d?)\.\s?    # Match 1, up to 2 digits for target number
  (.{1,20})       # match 2, up to 20 characters for name
  |(.+))          # Match 3, for everything else
  ?///i, (msg) ->
    botData = loadFile()
    toparse = {}
    toParse.REQUEST = "GET_FULL_UPDATE"
    toParse.warcode = botData.clashcaller
    data = queryString.stringify(toParse)
    robot.http("http://www.clashcaller.com/api.php")
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, res, body) ->
        if match = /Invalid War ID\./.test(body)
          if !msg.match[1]? and !msg.match[3]?
            msg.send """
                     Usage: /targetname <position>.<name>
                     Ex. /targetname 3.Some Guy"
                     """
          else
            msg.send "Sorry, the ClashCaller link seems to be invalid. Please" +
            " re-set the ClashCaller ID."
        else
          if msg.match[2]?
            botData = loadFile()
            toParse.REQUEST = "UPDATE_TARGET_NAME"
            toParse.warcode = botData.clashcaller
            toParse.posy = msg.match[1]-1
            toParse.value = msg.match[2]
            accessApi(toParse)
            msg.send "Set target #{msg.match[1]} as #{msg.match[2]}."
          else if msg.match[3]?
            msg.send "Sorry '#{msg.match[3]}' is not a valid input. " +
                     "Please use the format '1.name'"
          else
            msg.send """
                     Usage: /targetname <position>.<name>
                     Ex. /targetname 3.Some Guy"
                     """

  robot.respond ///
  call              # Primary command
  (?:\s             # begin non-capture group
  (\d\d?)\.?        # Match 1, target number
  (?:\s(.+))?       # Match 2, optional name
  |(.+)             # Match 3, for everything else
  )?///i, (msg) ->  # End non-capture group, case-insensitive
    console.log "1: " + msg.match[1]
    console.log "2: " + msg.match[2]
    console.log "3: " + msg.match[3]
    unless msg.match[1]?
      msg.send  """
                Sorry #{msg.match[3]} is not valid. Please use this format:
                /call <rank> [name]
                Where [name] is optional. Default uses your GroupMe name.
                """
      return
    botData = loadFile()
    toParse.REQUEST = "GET_FULL_UPDATE"
    toParse.warcode = botData.clashcaller
    data = queryString.stringify(toParse)
    robot.http("http://www.clashcaller.com/api.php")
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, res, body) ->
        if match = /Invalid War ID\./.test(body)
          msg.send "Sorry, the current ClashCaller link appears invalid. The " +
          "previous war has most likely ended, and a new link has not been set."
        else
          targetNumber = msg.match[1]-1
          if msg.match[2]?
            attackName = msg.match[2]
          else attackName = msg.message.user.name
          fullUpdate = JSON.parse(body)
          calls = fullUpdate.calls
          findTarget = _.find(calls, { "last":"1", "posy":"#{targetNumber}" })
          if findTarget?
            numStars = +findTarget.stars
          warSize = +fullUpdate.general.size
          switch
            when numStars is 5
              msg.send "This target has already been 3-starred!"
            when 1 < numStars < 5
              toParse = {}
              toParse.REQUEST = "APPEND_CALL"
              toParse.warcode = botData.clashcaller
              toParse.posy = targetNumber
              toParse.value = attackName
              data = queryString.stringify(toParse)
              msg.http("http://clashcaller.com/api.php")
                .header('Content-Type', 'application/x-www-form-urlencoded')
                .post(data) (err, res, body) ->
                  starsEarned = numStars - 2
                  randResponse = [
                    "who sucked it up and earned"
                    "who failed and earned"
                    "who really dropped the ball and earned"
                  ]
                  msg.send "called the base! Hope you have better luck than " +
                  "#{findTarget.playername} " + _.sample(randResponse) +
                  " #{starsEarned} stars."
            when numStars is 1
              startTime = moment(fullUpdate.general.starttime).subtract(1, "hours")
              endTime = moment(startTime)
              endTime.add(1, "days")
              callTime = moment(findTarget.calltime).subtract(1, "hours")
              # If this breaks someday in the future,
              # it's probably because of this subtracting 1 hours bullshit.
              warStart = startTime.isBefore(moment())
              if warStart is true
                if callTime.isBefore(startTime)
                  timeLeft = endTime.diff(moment(), 'minutes')
                  if timeLeft >= 1080
                    timeSinceStart =  1440 - timeLeft
                    timeLeftDur = 360 - timeSinceStart
                    flexDuration = moment.duration(timeLeftDur, 'minutes').format("h [Hours,] m [Minutes]")
                    msg.send "Sorry, this target has already been called by " +
                    "#{findTarget.playername}, and expires in #{flexDuration}."
                  else
                    toParse = {}
                    toParse.REQUEST = "APPEND_CALL"
                    toParse.warcode = botData.clashcaller
                    toParse.posy = targetNumber
                    toParse.value = attackName
                    data = queryString.stringify(toParse)
                    msg.http("http://clashcaller.com/api.php")
                      .header('Content-Type', 'application/x-www-form-urlencoded')
                      .post(data) (err, res, body) ->
                        if match = /^<success>$/.test(body)
                          msg.send "#{attackName} has called ##{msg.match[1]}" +
                          "! The previous call by #{findTarget.playername} " +
                          "expired."
                else
                  timeLeft = endTime.diff(callTime, 'minutes')
                  callLength = timeLeft / 4
                  callEnd = moment(callTime).add(callLength, "minutes")
                  if moment().isBefore(callEnd)
                    timeToCallEnd = callEnd.diff(moment(), 'minutes')
                    timeDiff = callLength - timeToCallEnd
                    msg.send "Sorry target #{msg.match[1]} has already been" +
                      " called by #{findTarget.playername}. Their call has " +
                      "#{moment.duration(timeToCallEnd, 'minutes').format("h [Hours,] m [Minutes]")} left."
                  else
                    toParse = {}
                    toParse.REQUEST = "APPEND_CALL"
                    toParse.warcode = botData.clashcaller
                    toParse.posy = targetNumber
                    toParse.value = attackName
                    data = queryString.stringify(toParse)
                    msg.http("http://clashcaller.com/api.php")
                      .header('Content-Type', 'application/x-www-form-urlencoded')
                      .post(data) (err, res, body) ->
                        if match = /^<success>$/.test(body)
                          msg.send "#{attackName} has called ##{msg.match[1]}" +
                          "! The previous call by #{findTarget.playername} " +
                          "expired."
              else
                msg.send "Sorry, ##{msg.match[1]} has already been called " +
                "by #{findTarget.playername}. Only one call per target " +
                "before war starts."
            when !findtarget?
              toParse = {}
              toParse.REQUEST = "APPEND_CALL"
              toParse.warcode = botData.clashcaller
              toParse.posy = targetNumber
              toParse.value = attackName
              data = queryString.stringify(toParse)
              msg.http("http://clashcaller.com/api.php")
                .header('Content-Type', 'application/x-www-form-urlencoded')
                .post(data) (err, res, body) ->
                  if match = /^<success>$/.test(body)
                    msg.send "#{attackName} has called ##{msg.match[1]}!"
                  else if match = /<error>Position input is invalid.<\/error>/.test(body)
                    msg.send "Sorry, you must submit a call within the range " +
                    "1-#{warSize}."
                  else
                    msg.send "Sorry, something has gone horribly wrong!! Here" +
                    " is the error: #{body}."
            else
              msg.send "something is not right..."


  robot.respond ///
  changeclan          # Primary command
  (?:\s               # Begin non-capture group
  (.{1,15})\s         # Match 1, up to 15 chars for clan name
  \#([\w\d]{1,10})$   # Match 2, up to 10 alphanumeric for clan tag
  |(.+)               # Match 3, for everything else
  )?///i, (msg) ->    # End of command, case-insensitive
    botData = loadFile()
    if !msg.match[1]? and !msg.match[3]?
      msg.send "Usage: /changeclan <name> #<clantag>"
    else if msg.match[3]?
      msg.send "Sorry, '#{msg.match[3]}' is not a valid input. Please use the
      format '/changeclan clan-name #clanid123'."
    else
      botData.clanname = msg.match[1]
      botData.clanid = msg.match[2]
      saveFile(botData)

  robot.respond ///
  addstars          # Primary command
  (?:\s             # Begin non-capture group
  (\d\d?)\s         # Match 1, target number
  (\d)\s?           # Match 2, number of stars
  (.{0,20})         # Match 3, name of attacker
  |(.+)             # Match 4, for evertything else
  )?///i, (msg) ->  # End of non-capture group, case-insensitive
    unless msg.match[1]?
      if msg.match[4]?
        msg.send """
                 Detected wrong format. Please use the following:
                 /addstars <target> <# stars> [name]
                 Where [name] is optional. Default uses groupme name, only need to enter part of a name
                 """
      else
        msg.send """
                 Usage: /addstars <target> <# stars> [name]
                 Where [name] matches the name on the call
                 Is optional, default uses groupme name, enter partial name
                 """
      return
    botData = loadFile()
    toParse.REQUEST = "GET_FULL_UPDATE"
    toParse.warcode = botData.clashcaller
    data = queryString.stringify(toParse)
    robot.http("http://www.clashcaller.com/api.php")
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, res, body) ->
        fullUpdate = JSON.parse(body)
        warSize = +fullUpdate.general.size
        callNum = msg.match[1]
        stars = +msg.match[2]
        if match = /Invalid War ID\./.test(body)
          msg.send "Sorry, the current ClashCaller link appears invalid. The " +
          "previous war has most likely ended, and a new link has not been set."
        else if callNum > warSize
          msg.send "Sorry, please select a target between 1 and #{warSize}."
        else if 0 > stars > 3
          msg.send "Sorry, #{msg.match[2]} is not valid. " +
                   "Please enter a number between 0 and 3."
        else
          targetNum = callNum - 1
          filterObj = {}
          filterObj.posy = targetNum.toString()
          targetCalls = _.filter(fullUpdate.calls, filterObj)
          console.log targetCalls
          matchedCalls = []
          if msg.match[3]?
            attackName = msg.match[3]
          else attackName = msg.message.user.name
          nameExp = new RegExp(attackName, 'ig')
          for call in targetCalls
            do (call) ->
              if match = nameExp.test(call.playername)
                matchedCalls.push call
          if matchedCalls.length > 1
            msg.send "Sorry, more than one call has been found for " +
            "#{attackName}, please make it more specific."
          else if matchedCalls.length < 1
            msg.send "Sorry, I didnt detect any valid calls for #{attackName}"
          else
            toParse.REQUEST = 'UPDATE_STARS'
            toParse.posy = matchedCalls[0].posy
            toParse.posx = matchedCalls[0].posx
            toParse.value = parseInt(msg.match[2]) + 2
            data = queryString.stringify(toParse)
            robot.http("http://www.clashcaller.com/api.php")
              .header('Content-Type', 'application/x-www-form-urlencoded')
              .post(data) (err, res, body) ->
                if match = /<success>/.test(body)
                  msg.send "Successfully added #{msg.match[2]} stars to " +
                  "target ##{msg.match[1]} for #{matchedCalls[0].playername}."
                else
                  msg.send "Sorry making the call failed, reason: " + body

  robot.respond /open$/i, (msg) ->
    botData = loadFile()
    toParse.REQUEST = "GET_FULL_UPDATE"
    toParse.warcode = botData.clashcaller
    data = queryString.stringify(toParse)
    robot.http("http://www.clashcaller.com/api.php")
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, res, body) ->
        if match = /Invalid War ID\./.test(body)
          msg.send "Sorry, the current ClashCaller link appears invalid. The " +
          "previous war has most likely ended, and a new link has not been set."
        else
          fullUpdate = JSON.parse(body)
          size = fullUpdate.general.size
          potentialCalls = [0...size]
          startTime = moment(fullUpdate.general.starttime).subtract(1, "hours")
          warStart = startTime.isBefore(moment())
          calls = fullUpdate.calls
          if warStart is false
            callArray = _.map(calls, 'posy')
            callDiff = _.differenceBy(potentialCalls, callArray, Math.floor)
            openCalls = (i + 1 for i in callDiff)
            msg.send "Currently open calls: #{openCalls.join(", ")}"
          else
            startTime = moment(fullUpdate.general.starttime).subtract(1, "hours")
            currentlyCalled = _.filter(calls, { 'stars': '1', 'last': '1' })
            endTime = moment(startTime)
            endTime.add(1, "days")
            callActive = []
            for call in currentlyCalled
              do (call) ->
                callTime = moment(call.calltime).subtract(1, "hours")
                # If call was made before war started.
                if callTime.isBefore(startTime)
                  timeLeft = endTime.diff(moment(), 'minutes')
                  if timeLeft >= 1080 #call expires after 6 hours, or < 1080 min
                    # call hasn't expired. Remove from array
                    callActive.push call.posy
                else
                  timeLeft = endTime.diff(callTime, 'minutes')
                  callLength = timeLeft / 4
                  callEnd = moment(callTime).add(callLength, "minutes")
                  if moment().isBefore(callEnd)
                    callActive.push call.posy
            threeStarred = _.filter(calls, { 'stars': '5' })
            for call in threeStarred
              callActive.push call.posy
            callArray = _.differenceBy(potentialCalls, callActive, Math.floor)
            openCalls = (i + 1 for i in callArray)
            callWithStars = []
            callObj = {}
            for call in openCalls
              do (call) ->
                callObj.posy = "#{call - 1}"
                targetCalls = _.filter(calls, callObj)
                console.log typeof targetCalls
                if targetCalls.length > 0
                  targetStars = (item.stars for item in targetCalls)
                  maxStar = Math.max targetStars...
                callStars = +maxStar if maxStar?
                console.log "callStars: " + callStars
                if callStars? is false
                  thisStars = ""
                else if callStars is 1
                  thisStars = "(exp)"
                else
                  callStars -= 2
                  thisStars = "(#{callStars})"
                callWithStars.push "#{call}#{thisStars}"
            msg.send "Currently open calls: #{callWithStars.join(", ")}"

  robot.respond /targetsleft$/i, (msg) ->
    botData = loadFile()
    toParse.REQUEST = "GET_FULL_UPDATE"
    toParse.warcode = botData.clashcaller
    data = queryString.stringify(toParse)
    robot.http("http://www.clashcaller.com/api.php")
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, res, body) ->
        if match = /Invalid War ID\./.test(body)
          msg.send "Sorry, the current ClashCaller link appears invalid. The " +
          "previous war has most likely ended, and a new link has not been set."
        else
          fullUpdate = JSON.parse(body)
          size = fullUpdate.general.size
          potentialCalls = [0...size]
          startTime = moment(fullUpdate.general.starttime).subtract(1, "hours")
          warStart = startTime.isBefore(moment())
          endTime = moment(startTime)
          endTime.add(1, "days")
          calls = fullUpdate.calls
          if warStart is false
            msg.send "War hasn't started yet, so all #{size} targets are left"
          else
            threeStarCalls = _.filter(calls, { 'stars': '5' })
            threeStarArr = (parseInt(call.posy) for call in threeStarCalls)
            _.pullAll(potentialCalls, threeStarArr)
            targetArray = []
            for callNum in potentialCalls
              do (callNum) ->
                targetFilter = { 'posy': "#{callNum}" }
                targetCalls = _.filter(calls, targetFilter)
                targetObj =
                  pos: callNum + 1
                # At least one call on target
                if targetCalls.length > 0
                  targetMax = _.maxBy(targetCalls, 'stars')
                  targetLast = _.find(targetCalls, {last: '1'})
                  if targetMax.stars is '1'
                    targetObj.stars = null
                  else
                    targetObj.stars = targetMax.stars - 2
                  # If the last call is called and valid/expired
                  if targetLast.stars is '1'
                    targetObj.calltime = targetLast.calltime
                    targetObj.iscalled = true
                  else
                    targetObj.iscalled = false
                  targetArray.push targetObj
                # No calls on target
                else
                  targetObj =
                    pos: callNum + 1
                    stars: null
                    iscalled: false
                  targetArray.push targetObj
            #begin loop to put together message and determine time
            toSend = []
            console.log "targetArray:\n", targetArray
            endTime = moment(startTime)
            endTime.add(1, "days")
            for target in targetArray
              do (target) ->
                if target.stars is null
                  stars = " (/)"
                else
                  stars = " (#{target.stars})"
                if target.iscalled is true
                  callTime = moment(target.calltime).subtract(1, "hours")
              #if warStart is true
                  if callTime.isBefore(startTime)
                    timeLeft = endTime.diff(moment(), 'minutes')
                    if timeLeft >= 1080
                      timeSinceStart =  1440 - timeLeft
                      timeLeftDur = 360 - timeSinceStart
                      targetCallTime = " (#{moment.duration(timeLeftDur, 'minutes').format("h[h]m[m]")})"
                    else
                      targetCallTime = " (exp)"
                  else
                    timeLeft = endTime.diff(callTime, 'minutes')
                    callLength = timeLeft / 4
                    callEnd = moment(callTime).add(callLength, "minutes")
                    if moment().isBefore(callEnd)
                      timeToCallEnd = callEnd.diff(moment(), 'minutes')
                      timeDiff = callLength - timeToCallEnd
                      targetCallTime = " (#{moment.duration(timeToCallEnd, 'minutes').format("h[h]m[m]")})"
                    else
                      targetCallTime = " (exp)"
                else
                  targetCallTime = " (open)"
                toSend.push "#{target.pos}" + stars + targetCallTime
            console.log "toSend:\n", toSend
            msg.send toSend.join("\n")


  ###
            startTime = moment(fullUpdate.general.starttime).subtract(1, "hours")
            currentlyCalled = _.filter(calls, { 'stars': '1', 'last': '1' })
            endTime = moment(startTime)
            endTime.add(1, "days")
            callActive = []
            for call in currentlyCalled
              do (call) ->
                callTime = moment(call.calltime).subtract(1, "hours")
                # If call was made before war started.
                if callTime.isBefore(startTime)
                  timeLeft = endTime.diff(moment(), 'minutes')
                  if timeLeft >= 1080 #call expires after 6 hours, or < 1080 min
                    # call hasn't expired. Remove from array
                    callActive.push call.posy
                else
                  timeLeft = endTime.diff(callTime, 'minutes')
                  callLength = timeLeft / 4
                  callEnd = moment(callTime).add(callLength, "minutes")
                  if moment().isBefore(callEnd)
                    callActive.push call.posy
            threeStarred = _.filter(calls, { 'stars': '5' })
            for call in threeStarred
              callActive.push call.posy
            callArray = _.differenceBy(potentialCalls, callActive, Math.floor)
            openCalls = (i + 1 for i in callArray)
            callWithStars = []
            callObj = {}
            for call in openCalls
              do (call) ->
                callObj.posy = "#{call - 1}"
                targetCalls = _.filter(calls, callObj)
                console.log typeof targetCalls
                if targetCalls.length > 0
                  targetStars = (item.stars for item in targetCalls)
                  maxStar = Math.max targetStars...
                callStars = +maxStar if maxStar?
                console.log "callStars: " + callStars
                if callStars? is false
                  thisStars = ""
                else if callStars is 1
                  thisStars = "(exp)"
                else
                  callStars -= 2
                  thisStars = "(#{callStars})"
                callWithStars.push "#{call}#{thisStars}"
            msg.send "Currently open calls: #{callWithStars.join(", ")}"
  ###


  accessApi = (parseString) ->
    data = queryString.stringify(parseString)
    robot.http("http://clashcaller.com/api.php")
      .header('Content-Type', 'application/x-www-form-urlencoded')
      .post(data) (err, res, body) ->
        robot.logger.debug body
        console.log(body)
        if err
          robot.logger.error err
          return robot.emit 'error', err, msg
        try
          if res.statusCode is 200
            robot.logger.debug "body: #{body}"
          else
            return robot.emit 'error', "#{res.statusCode}: #{body}", msg
        catch error
          robot.logger.error error
          return msg.send "Error! #{body}"
        if match = /^<success>$/.test(body)
          return "Success!"
        else if JSON.parse(body)
          console.log(JSON.parse(body))
          console.log(robot.http)
          return JSON.parse(body)
        else
          console.log(body)
          console.log(typeof body)
          return "Sorry encountered an error, please try again. " +
                 "Got response: #{body}"

loadFile = ->
  filePath = 'bot_data.json'
  fileData = jsonfile.readFileSync(filePath)

saveFile = (dataObj) ->
  jsonfile.writeFileSync('bot_data.json', dataObj)
