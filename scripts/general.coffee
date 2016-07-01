# Description:
#   General commands for Reddit Templars's groups.
#
# Dependencies:
#   "cool-ascii-faces": "~1.3.x"
#
# Commands:
#   hubot cool - (Doesn't work :/) Prints a random face.
cool = require('cool-ascii-faces')

module.exports = (robot) ->
  robot.respond /cool/i, (res) ->
    res.send "Not working at the moment... :/"

  robot.respond /cow/i, (res) ->
    moo = ['Moo...', '...Moo...', '...Moo', 'Mooooooooo...', 'Moo...Moo...Moo']
    res.send res.random moo

  robot.respond /salt/i, (res) ->
    res.send "http://i.imgur.com/WEp91o5.png"

  robot.hear /ayy/i, (res) ->
    ayy = [
      'http://i1.kym-cdn.com/photos/images/newsfeed/000/632/639/87c.gif'
      'http://i2.kym-cdn.com/photos/images/newsfeed/000/632/652/6ca.jpg'
      'http://i2.kym-cdn.com/photos/images/newsfeed/000/632/634/72d.jpg'
      'http://i3.kym-cdn.com/photos/images/newsfeed/000/632/636/d3b.png'
      'http://i2.kym-cdn.com/photos/images/newsfeed/000/632/635/11f.jpg'
      'http://i2.kym-cdn.com/photos/images/newsfeed/000/632/596/2b3.jpg'
      'http://i1.kym-cdn.com/photos/images/newsfeed/000/633/736/177.jpg'
      'http://i0.kym-cdn.com/photos/images/newsfeed/000/632/613/42d.jpg'
    ]
    res.send res.random ayy

  robot.respond /help|commands/i, (res) ->
    helpOne =
      """
      /call <target> [<name>] - Calls a base on ClashCaller. (beta)
      /cc - Prints the ClashCaller link.
      /changeclan <name> <tag> - Changes the clan name and tag for Clashcaller. (beta)
      /check - (todo) Checks ClashCaller for a target to see if it's called.
      /cool - (Doesn't work :/) Prints a random face.
      /createwar <name> <size> - Creates a new war in ClashCaller. (beta)
      /cw - Prints the ClashCaller and War Sheet.
      /help - Displays all of the help commands that Hubot knows about.
      /open - Checks to see which bases are open to call.
      /setcc (<link>|<war id>) - Sets the ClashCaller link.
      /setwarend <time> [<time>] - Sents the end time of the war. (beta)
      /setwarstart <time> [<time>] - Sets the start time of the war. (beta)
      /setws <link> - Sets the war sheet.
      /skitch [apple|android] - Displays a link to the Skitch app.
      """
    helpTwo =
      """
      /targetname <position> <name> - Sets the enemy name on ClashCaller. (beta)
      /targetsleft - Displays all targets that haven't been 3-starred.
      /timeleft - Prints the time left until war starts or ends.
      /updatestars - (todo) Updates stars for a target on ClashCaller.
      /ws - Prints the war sheet.
      """
    res.send helpOne
    delay = (ms, func) -> setTimeout func, ms
    delay 250, -> res.send helpTwo

  robot.respond /skitch(?:\s(android|apple))?/i, (msg) ->
    if msg.match[1]? then deviceOption = msg.match[1]
    androidLink = "https://dl.dropboxusercontent.com" +
                  "/u/5292229/com.evernote.skitch-2.8.5.apk"
    appleLink = "https://itunes.apple.com/us/app/" +
                "skitch-snap.-mark-up.-send./id490505997?mt=8"
    if deviceOption?
      if deviceOption is "android"
        msg.send androidLink
      else
        msg.send appleLink
    else
      msg.send "Android:\n#{androidLink}\nApple:\n#{appleLink}"

  robot.respond /robot/i, (msg) ->
    console.log robot
