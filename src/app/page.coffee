fs = require 'fs'
path = require 'path'
{$} = require 'space-pen'

module.exports = class Page
  render: (data) ->
    $('body').html