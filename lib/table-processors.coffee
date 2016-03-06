Q = require 'q'

log_debug = ->
#log_debug = console.debug.bind(console, "table-editor, table-processors")

processRestructuredTextTable = (tableText) ->
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

    TableFormatter = require('cli-table')

    formatter = new TableFormatter {
      chars:
        'top': '='
        'top-mid': '+'
        'top-left': '+'
        'top-right': '+'
        'bottom': '='
        'bottom-mid': '+'
        'bottom-left': '+'
        'bottom-right': '+'
        'left': '|'
        'left-mid': '|'
        'mid': '-'
        'mid-mid': '|'
        'right': '|'
        'right-mid': '|'
        'middle': '|'
      style:
        head: []
        border: []

      head: tableHeader
    }

    for row in tableRows
      formatter.push row

    tableString = formatter.toString()

    # remove top and bottom row
    tableString = tableString.replace(/^[^\n]+\n/, '').replace(/[^\n]+\n?$/, "")

    # remove mid rows
    #tableString = tableString.replace(/^(?:\|-+)+\|$/m, '')

    # rows =
    # tableString =
    result = tableString

  result

processMarkdownTable = (tableText) ->
  result = null

  asciiparser = require('asciiparse')

  hasHeader = tableText.match /^\|.*\|\n(\|-+)+\|\n/

  tableData = asciiparser.parseString tableText,
    rowSeparator: '-'
    junction: '|'
    colSeparator: '|'
    multiline: false
    header: off
  , (error, tableData) ->
    if hasHeader
      tableHeader = tableData[0]
      tableRows = tableData[1...]
    else
      tableHeader = null
      tableRows = tableData

    # make sure the first line has same number of columns like header
    if tableRows.length
      firstRow = tableRows[0]
      log_debug "firstRow", firstRow
      log_debug "tableHeader", tableHeader

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

      result = tableString

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
  else if tableText.match /^\|.*\|\r?\n(?:\|:?-+:?)+\|/
    processor = processMarkdownTable
  else if scopeName.match /restructuredtext/
    processor = processRestructuredTextTable
  else if scopeName.match /markdown|source\.gfm/
    processor = processMarkdownTable
  else
    processor = processSimpleTable

  processor tableText

module.exports = {processTableText}
