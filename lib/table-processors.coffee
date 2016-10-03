Q = require 'q'

log_debug = require('./log_debug') "table-editor, table-processors"

processRestructuredTextTable = (tableText) ->
  console.log "process restructured text table"
  result = null

  asciiparser = require('asciiparse')

  tableData = asciiparser.parseString tableText,
    rowSeparator: '-'
    junction: '|'
    colSeparator: '|'
    multiline: false
    header: off
  , (error, tableData) ->
    return reject error if error

    tableHeader = tableData[0]
    tableRows = tableData[1...]

    console.log tableHeader, tableRows

    TableFormatter = require('cli-table')

    formatter = new TableFormatter {
      chars:
        'top': '-'
        'top-mid': '+'
        'top-left': '+'
        'top-right': '+'
        'bottom': '-'
        'bottom-mid': '+'
        'bottom-left': '+'
        'bottom-right': '+'
        'left': '|'
        'left-mid': '+'
        'mid': '-'
        'mid-mid': '+'
        'right': '|'
        'right-mid': '+'
        'middle': '|'
      style:
        head: []
        border: []

      head: tableHeader
    }

    for row in tableRows
      if row.length
        formatter.push row

    tableString = formatter.toString()

    # remove top and bottom row
    #tableString = tableString.replace(/^[^\n]+\n/, '').replace(/[^\n]+\n?$/, "")

    # remove mid rows
    #tableString = tableString.replace(/^(?:\|-+)+\|$/m, '')

    # rows =
    # tableString =
    #

    # replace border under header row
    [ border ] = tableString.match(/^.*\r?\n/)
    border = border.replace /-/g, '='
    tableString = tableString.replace /^(.*\r?\n(\|.*\r?\n)+).*\r?\n/, "$1#{border}"

#    tableString = tableString.replace /^((.*\r?\n)(.*\r?\n)).*\r?\n/, "$1$2"

    result = tableString

  result

processMarkdownTable = (tableText) ->
  console.log "process markdown table"
  result = null

  asciiparser = require('asciiparse')

  headerPart = /^\|.*\|\n(\|-+)+\|\n/

  hasHeader = tableText.match headerPart

  tableData = asciiparser.parseString tableText,
    rowSeparator: '-'
    junction: '|'
    colSeparator: '|'
    multiline: false
    header: off
  , (error, tableData) ->

    debugger

    if hasHeader
      tableHeader = tableData[0]
      tableRows = tableData[1...]

    # else if tableData.length is 1
    #   tableHeader = tableData[0]
    #   tableRows   = [ ('' for cell in tableHeader) ]
    else
      tableHeader = null
      tableRows = tableData

    log_debug "tableHeader", tableHeader
    log_debug "tableRows", tableRows

    # make sure the first line has same number of columns like header
    if tableRows.length and tableHeader?
      firstRow = tableRows[0]
      while firstRow.length < tableHeader.length
        firstRow.push ''

    try

      AsciiTable = require('ascii-table')

      formatter = AsciiTable.factory(
        heading: tableHeader
        rows: tableRows
      )

      tableString = formatter.toString()

      # remove top and bottom row
      tableString = tableString.replace(/^[^\n]+\n/, '').replace(/[^\n]+\n?$/, "")

      unless tableHeader?
        debugger
        tableString = tableString.replace headerPart, ''

      result = tableString
      log_debug "result", tableString

    catch error
      result = error

  if result instanceof Error
    throw result
  else
    return result

processSimpleTable = (tableText) ->
  processMarkdownTable tableText

processTableText = (tableText, scopeName) =>
  log_debug tableText

  if tableText.match /^(\+=+)+\+\r?\n\|.*\|\r?\n/
    processor = processRestructuredTextTable
  else if tableText.match /^(\+-+)+\+\r?\n\|.*\|\r?\n/
    processor = processRestructuredTextTable
  else if tableText.match /^\|.*\|\r?\n(?:\|:?-+:?)+\|/
    processor = processMarkdownTable
  else if scopeName.match /restructuredtext/
    processor = processRestructuredTextTable
  else if scopeName.match /markdown|source\.gfm/
    processor = processMarkdownTable
  else
    processor = processSimpleTable

  console.log processor

  processor tableText

module.exports = {processTableText}
