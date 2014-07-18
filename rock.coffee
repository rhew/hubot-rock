# Description
#   Rock paper scissors lizard spock
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot #1 hubot #2 fight!)
#   (rock|paper|scissors|lizard|spock)
#
# Notes:
#   None
#
# Author:
#   rhew

# each challenge and a list what it beats
CHALLENGES =
  rock: ['scissors', 'lizard']
  paper: ['rock', 'spock']
  scissors: ['paper', 'lizard']
  lizard: ['paper', 'spock']
  spock: ['rock', 'scissors']
WIN = ['(awyeah)', '(fuckyeah)', '(gates)', '(jobs)', '(lol)', '(yey)', '(successful)']
LOSE = ['(poo)', '(areyoukiddingme)', '(failed)', '(facepalm)', '(ohcrap)', '(rageguy)', '(tableflip)', '/me pulls the plug']
DRAW = ['(pokerface)', '(badpokerface)', '(jackie)', '(unknown)', 'jinx!', 'copy-cat', '(shrug)']

delay = (ms, func) -> setTimeout func, ms

module.exports = (robot) ->

  robot.brain.on 'loaded', =>
    robot.brain.data.opponentId = null
    robot.brain.data.myChallenge = null
    robot.brain.data.opponentChallenge = null

  idFromMention = (name) ->
    for own key, user of robot.brain.data.users
      return user if user['mention_name'] is name

  idFromName = (name) ->
    user = robot.brain.userForName(name)
    unless user?
      user = idFromMention(name)
    unless user?
      users = robot.brain.usersForFuzzyName(name)
      if users.length is 1
        user = users[0]
      else if users.length > 1
        console.log "#{users.length} users match '#{name}'."
        throw new Error "#{users.length} users match '#{name}'."
    if not user?
      console.log "No matching users for '#{name}'."
      throw new Error "No matching users for '#{name}'."
    return user.id

  checkWinner = (msg) ->
    myChallenge = robot.brain.data.myChallenge
    opponentChallenge = robot.brain.data.opponentChallenge
    if (not opponentChallenge?) or (not myChallenge?)
      return
    if opponentChallenge is myChallenge
      msg.send msg.random DRAW
    else if CHALLENGES[opponentChallenge].indexOf(myChallenge) isnt -1
      msg.send msg.random LOSE
    else
      msg.send msg.random WIN
    robot.brain.data.opponentId = null
    robot.brain.data.opponentChallenge = null
    robot.brain.data.myChallenge = null

  acceptChallenge = (opponentName, msg) ->
    robot.brain.data.opponentId = idFromName(opponentName)
    msg.send '3'
    delay 1000, -> msg.send '2'
    delay 2000, -> msg.send '1'
    delay 3000, ->
      robot.brain.data.myChallenge = msg.random Object.keys(CHALLENGES)
      msg.send "#{robot.brain.data.myChallenge}"
      checkWinner(msg)
    # wait one more second before cancelling the game
    delay 4000, ->
      robot.brain.data.opponentId = null
      robot.brain.data.opponentChallenge = null
      robot.brain.data.myChallenge = null
      
  # opponent hubot fight!
  robot.hear /(?:[@#])?(\w+)\s+(?:[@#])?(\w+)\s+fight!/i, (msg) ->
    if msg.match[2].trim() is robot.name
      acceptChallenge(msg.match[1].trim(), msg)

  # hubot opponent fight!
  robot.respond /(?:[@#])?(\w+)\s+fight!/i, (msg) ->
    acceptChallenge(msg.match[1].trim(), msg)

  # hubot *
  robot.hear /(.*)/i, (msg) ->
    opponentChallenge = msg.match[1].trim()
    if not robot.brain.data.opponentId?
      return
    if msg.envelope.user.id isnt robot.brain.data.opponentId
      return
    if Object.keys(CHALLENGES).indexOf(opponentChallenge) isnt -1
      robot.brain.data.opponentChallenge = opponentChallenge
      checkWinner(msg)
