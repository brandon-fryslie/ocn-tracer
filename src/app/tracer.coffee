#!/usr/bin/env coffee


# read in all logs
# follow trace-id - im gonna need a gui

# need to get some good logs from a spoon

# pull all messages w/ trace id
# sort by timestamp
# print


fs = require('fs')
util = require('util')
stream = require('stream')
es = require("event-stream")
_ = require 'lodash'

# render fn
RENDER = null

PROJECT_DIR = "#{process.env.HOME}/projects"
lineNo = 0

# LOGPATH = process.argv[2]

# logpaths
# "#{PROJECT_DIR}/birdseed/logs/birdseed-application.log"
# "#{PROJECT_DIR}/bag-boy/logs/bagboy-application.log"
# "#{PROJECT_DIR}/bag-boy/logs/bagboy-cletus.log"
# "#{PROJECT_DIR}/bag-boy/logs/bagboy-datomic.log"
# "#{PROJECT_DIR}/bag-boy/logs/bagboy-marshmallow.log"
LOGPATH = "#{PROJECT_DIR}/pigeon/logs/pigeon-application.log"


TRACES = []

BLACKLIST = [
  'per-transaction-log'
  'bagboy-down-retry'
  'HTTP request retry'
]

TIMEPOINT_BLACKLIST = [
  'bagboy-receive'
  'bagboy-complete'

]


contents = fs.createReadStream(LOGPATH)
    .pipe(es.split())
    # .pipe(es.parse())
    .pipe(es.mapSync((line) ->

        lineNo += []
        # // pause the readstream
        contents.pause()

        (->
          event_json = {}

          # save to map?
          try
            event_json = JSON.parse(line)
          catch e
            console.log 'error parsing line', line

          if event_json?.mdc?['trace-id']? && !_.contains(BLACKLIST, event_json?.message)
            trace_id = event_json.mdc['trace-id']

            if TRACES[trace_id]?
              TRACES[trace_id].push event_json
            else
              TRACES[trace_id] = [event_json]

          # // resume the readstream
          contents.resume()
          lineNo
        )()
    ).on('error', ->
      console.log('Error while reading file.')
    ).on 'end', ->

      output = for trace_id, events of TRACES when events.length > 2
        format_trace trace_id, events
      RENDER ("<div>#{s}</div>" for s in output).join('')

)

syntax_highlight = (json) ->
  if typeof json isnt 'string'
    json = JSON.stringify json, null, 2

    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    json.replace /("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, (match) ->
      cls = 'number'
      if /^"/.test(match)
          if /:$/.test(match)
              cls = 'key'
          else
              cls = 'string'
      else if /true|false/.test(match)
          cls = 'boolean'
      else if /null/.test(match)
          cls = 'null'

      '<span class="' + cls + '">' + match + '</span>'


# PRINT TRACES

format_trace = (trace_id, events) ->
  output = ["Viewing trace: #{trace_id} #{events.length} events"]
  for e in events
    output.push format_event e
  output.push '<hr>'
  ("<div>#{s}</div>" for s in output).join('')

format_event = (e) ->
  output = ["#{e.timestamp} #{e.level} "]

  if e.message is 'timepoint'
    if !_.contains TIMEPOINT_BLACKLIST, e.mdc?['timepoint-id']
      output.push "timepoint: #{"#{new Date(e.mdc.timepoint)}"} "
      # output.push JSON.stringify e.mdc
      output.push "timepoint-id: #{e.mdc['timepoint-id']} "
  else
    output.push e.message
    output.push syntax_highlight e.mdc

  ("<div>#{s}</div>" for s in output).join('')


module.exports =
  set_render: (render) ->
    RENDER = render