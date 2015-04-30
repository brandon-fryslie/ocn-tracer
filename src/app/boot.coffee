path = require 'path'
{$} = require 'space-pen'
Page = require './page'
tracer = require './tracer'

$ ->
  window.page = new Page
    tracer: tracer
  page.render()
