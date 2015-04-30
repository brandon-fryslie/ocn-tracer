fs = require 'fs'
path = require 'path'
{$} = require 'space-pen'

module.exports = class Page
  constructor: ({@tracer}) ->
    console.log 'tracer', @tracer
    @tracer.set_render @render
    @render 'loading page...'
  render: (str) ->
    $('body').html str