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
colors = require 'colors'

# set from the window out there
MAIN_WINDOW = null

PROJECT_DIR = "#{process.env.HOME}/projects"
lineNo = 0

LOGPATH = process.argv[2]

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
    ).on('end', ->



      # for trace_id, events of TRACES
      #   print_trace trace_id, events
      # )
)


# PRINT TRACES

format_trace = (trace_id, events) ->
  output = "Viewing trace: #{trace_id}"
  for e in events
    output += format_output e
  output += "\n"

format_output = (e) ->

  output = "#{e.timestamp} #{e.level} "

  if e.message is 'timepoint'
    if !_.contains TIMEPOINT_BLACKLIST, e.mdc?['timepoint-id']
      output += "timepoint: #{"#{new Date(e.mdc.timepoint)}".green} "
      # output += JSON.stringify e.mdc
      output += "timepoint-id: #{e.mdc['timepoint-id'].cyan} "
  else
    output += e.message
    output += JSON.stringify e.mdc

  output



module.exports =
  set_window = (window) -> MAIN_WINDOW = window