# Description:
#   ibsbot - dict bot for the Indian and Buddhist Studies
#
# Commands:
#   mw <word> - Monier-Williams Sanskrit English Dictionary
#
# Notes:
#   --

#  postgresql
pg = require 'pg'
promise = require 'bluebird'
pgp = require('pg-promise')({
  promiseLib: promise
})
conString = "#{process.env.OPENSHIFT_POSTGRESQL_DB_URL}/ibsbot0"
db = pgp(conString)

module.exports = (robot) ->
# postgresql
  robot.hear /^:pginit$/i, (msg) ->
    db.tx (t) ->
      t.batch [
        t.any 'DROP TABLE IF EXISTS test'
        t.any 'CREATE TABLE test (id SERIAL, name TEXT)'
      ]
    .then (data) ->
      msg.send 'done'
    .catch (err) ->
      msg.send err.message || err

  robot.hear /^:pgany (.*)$/i, (msg) ->
    query = msg.match[1]
    db.any(query)
    .then (data) ->
      msg.send "result: #{data.length}"
      msg.send JSON.stringify data if data.length
    .catch (err) ->
      msg.send err.message || err

  robot.hear /^:pgnone (.*)$/i, (msg) ->
    query = msg.match[1]
    db.any(query)
    .then () ->
      msg.send "done" 
    .catch (err) ->
      msg.send err.message || err

  robot.hear /^:pgone (.*)$/i, (msg) ->
    query = msg.match[1]
    db.one(query)
    .then (data) ->
      msg.send JSON.stringify data
    .catch (err) ->
      msg.send err.message || err

# dictionaries
  robot.hear /^mw\s+(.*)/i, (msg) ->
    msg.send "http://www.sanskrit-lexicon.uni-koeln.de/cgi-bin/monier/monierv1a.pl?key=#{msg.match[1]}&filter=SktDevaUnicode&noLit=off&transLit=HK&scandir=../..MWScan/MWScanpng&filterdir=../../docs/filter"

