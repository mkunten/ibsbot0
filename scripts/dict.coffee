# Description:
#   ibsbot - dict bot for the Indian and Buddhist Studies
#
# Commands:
#   :pginit - reset postgres (UNCANCELLABLE!!)
#   :pgany <query> - do query with some results
#   :pgnone <query> -do query without results
#   :pgone <query> - do query with a result (e.g. insert?)
#   :pg \dt - SHOW TABLES
#   :pg \dt <table> - SHOW COLUMNS
#   [:,.]mw <word> - Monier-Williams Sanskrit English Dictionary

botName = 'ibsbot' #process.env.OPENSHIFT_APP_NAME
dicTrigger = '[:,.]'

# cron
cron = require('cron') .CronJob
#  postgresql
pg = require 'pg'
promise = require 'bluebird'
pgp = require('pg-promise')({
  promiseLib: promise
})
conString = "#{process.env.OPENSHIFT_POSTGRESQL_DB_URL}/ibsbot0"
db = pgp(conString)

# utitilies
if 'undefined' == typeof String.prototype.repeat
  String.prototype.repeat = (len) ->
    new Array(len + 1).join this

# formatter: array to table
formatter = (arr) ->
  res = ''
  if arr.length > 0
    lens = {}
    spacer = {}
    keys = Object.keys arr[0]
    keys.forEach (key) ->
      lens[key] = key.length
    arr.forEach (n) ->
      keys.forEach (key) ->
        if n[key] == null
          n[key] = '_null_'
        else if n[key].toString
          n[key] = n[key].toString()
        lens[key] = Math.max lens[key], n[key].length
    for key of lens
      spacer[key] = ' '.repeat lens[key]
    res += (keys.map (key) ->
      (key + spacer[key]).slice( 0, lens[key] + 1)
    .join(' | '))
    res += "\n" + res.replace /[^|]/g, '-'
    res += "\n" + (arr.map (n) ->
      (keys.map (key) ->
        (n[key] + spacer[key]).slice( 0, lens[key] + 1)
      .join(' | '))
    .join("\n"))
    res = "```\n#{res}\n```"
  res

# module
module.exports = (robot) ->
# initial massage
  robot.send { room: '#general' }, 'hi, i have just woke up!'

# cron
  new cron '0 0 */6 * * *', () ->
    robot.send { room: 'mk' }, "http://#{process.env.OPENSHIFT_APP_DNS}/ping"
  , null, true, 'Asia/Tokyo'

# env
  # robot.hear ///^(@?#{botName} ?)?:env$///i, (msg) ->
  #   msg.send "env:\n#{JSON.stringify process.env}"

# postgresql
  robot.hear ///^(@?#{botName}:?\x20)?:pginit$///i, (msg) ->
    db.tx (t) ->
      t.batch [
        t.any 'DROP TABLE IF EXISTS config'
        t.any 'CREATE TABLE config (key TEXT NOT NULL PRIMARY KEY, value TEXT)'
      ]
    .then (data) ->
      msg.send 'done'
    .catch (err) ->
      msg.send err.message || err

  robot.hear ///^(@?#{botName}:?\x20)?:pg\x20\\dt$///i, (msg) ->
    db.any('SELECT table_name FROM information_schema.tables WHERE table_schema = \'public\'')
    .then (data) ->
      msg.send formatter data
    .catch (err) ->
      msg.send err.message || err

  robot.hear ///^(@?#{botName}:?\x20)?:pg\x20\\d\x20(.+)$///i, (msg) ->
    db.any('SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = $1', msg.match[2])
    .then (data) ->
      msg.send formatter data
    .catch (err) ->
      msg.send err.message || err

  robot.hear ///^(@?#{botName}:?\x20)?:pgany\x20(.+)$///i, (msg) ->
    query = msg.match[2]
    db.any(query)
    .then (data) ->
      msg.send "result: #{data.length}"
      msg.send formatter data if data.length
    .catch (err) ->
      msg.send err.message || err

  robot.hear ///^(@?#{botName}:?\x20)?:pgnone\x20(.+)$///i, (msg) ->
    query = msg.match[2]
    db.any(query)
    .then () ->
      msg.send "done" 
    .catch (err) ->
      msg.send err.message || err

  robot.hear ///^(@?#{botName}:? )?:pgone\x20(.+)$///i, (msg) ->
    query = msg.match[2]
    db.one(query)
    .then (data) ->
      msg.send formatter [data]
    .catch (err) ->
      msg.send err.message || err

# dictionaries
  robot.hear ///^(@?#{botName}:?\x20)?#{dicTrigger}mw\x20(.+)$///i, (msg) ->
    query = ".*\\|#{msg.match[2]}\\|.*"
    db.one('SELECT count(id) FROM table_dict_sa_en_mw WHERE key ~ $1', query)
    .then (data) ->
      cnt = data.cnt
      msg.send "hit: #{data.count}"
      db.any('SELECT word, description FROM table_dict_sa_en_mw WHERE key ~ $1 ORDER BY id LIMIT 2', query)
    .then (data) ->
      res = data.map (n) ->
        "#{n.word}\n#{n.description}\n"
      if res.length > 0
        res = "```\n#{res.join('')}\n```"
        msg.send res
    .catch (err) ->
      msg.send err.message || err
    # msg.send "http://www.sanskrit-lexicon.uni-koeln.de/cgi-bin/monier/monierv1a.pl?key=#{msg.match[1]}&filter=SktDevaUnicode&noLit=off&transLit=HK&scandir=../..MWScan/MWScanpng&filterdir=../../docs/filter"

# router
  robot.router.get '/ping', (req, res) ->
    res.type 'html'
    res.send """
      <!doctype html>
      <html>
        <head>
          <meta charset="utf-8" />
          <meta name="description" content="hi! i'm @#{botName}!" />
          <title></title>
        </head>
        <body>
          pong
        </body>
      </html>
    """

  robot.router.get '/data/tables', (req, res) ->
    res.type 'json'
    db.any('SELECT table_name FROM information_schema.tables WHERE table_schema = \'public\'')
    .then (data) ->
      res.send JSON.stringify data
    .catch (err) ->
      res.send err.message || err
