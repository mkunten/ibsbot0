# Description:
#   ibsbot - dict bot for the Indian and Buddhist Studies
#
# Commands:
#   mw <word> - Monier-Williams Sanskrit English Dictionary
#
# Notes:
#   --

module.exports = (robot) ->
  robot.hear /^mw\s+(.*)/i, (msg) ->
    msg.send "http://www.sanskrit-lexicon.uni-koeln.de/cgi-bin/monier/monierv1a.pl?key=#{msg.match[1]}&filter=SktDevaUnicode&noLit=off&transLit=HK&scandir=../..MWScan/MWScanpng&filterdir=../../docs/filter"

