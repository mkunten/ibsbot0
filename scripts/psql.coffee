# Description:
#   ibsbot - dict bot for the Indian and Buddhist Studies
#
# Commands:
#   ibsbot :pg <sql>

pg = require 'pg'
conString = 'postgresql://adminfvw6vb1:npdjQ18-KUmc@$OPENSHIFT_POSTGRESQL_DB_HOST:$OPENSHIFT_POSTGRESQL_DB_PORT/ibsbot0'

module.exports = (robot) ->
  robot.respond /:pg\s*(.*)$/, (msg) ->
    robot.send "```#{msg.match[1]}```"
    robot.send 'done'



