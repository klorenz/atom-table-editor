{Range} = require 'atom'
{processTableText} = require './table-processors.coffee'
module.exports =
class TableFormatter
  constructor: ({@tableText, @scopeName, @range}={}) ->

    #@tableText = @editor?.getTextInBufferRange @range
    #@scopeName = @editor?.scopeDescriptorForBufferPosition(range.start).scopes[0]
    @selections = []
    @newLine = "\n"

    console.log "text\n", @tableText

  getCellPosition: (lineText, position) ->
    {row, column} = position
    [cell, offset, cells] = [0, 0, 0]

    for c,i in lineText
      if c == '|'
        cells += 1

      if i >= column
        continue

      if c == '|'
        offset = 0
        cell += 1
      else
        offset += 1

    return {offset, cell, cells}

  getRangeFromCellPosition: (lineText, {cell, row}) ->
    _cell = 0
    search = '|'
    for c,i in lineText
      if c == '|'
        _cell += 1

      if (not start?) and _cell == cell
        start = i

      if (not end?) and _cell == cell+1
        end = i
        break

    start += 1 while lineText[start] != ' '
    end -= 1 while lineText[end] != ' '

    return new Range [row, start], [row, end]

  getTableRange: -> @range

  containsPoint: (point) -> @range.containsPoint point

  linesEqual: (a, b) ->
    a = a.replace /\s*\|\s*/g, ''
    b = b.replace /\s*\|\s*/g, ''

    (a == b) or a.match(/^[\+=\-]+$/) and b.match(/^[\+=\-]+$/)

  isRowSeparator: (line) ->
    return line.match(/^[\+=\-]+$/)

  isTableRow: (line) ->
    line.match /^\s*\|[^-=].*\|$/

  getFormattedTableText: ->
    return @newTableText if @newTableText
    console.log "tableText", @tableText
    @newTableText = processTableText @tableText, @scopeName

  getNumColumns: (line) ->
    return line.match(/\|/g).length - 1

  # insertRowAt: ->
  #   baseRow = @range.start.row
  #   @lines
  #   offset = 0
  #   for range in @selections
  #     range.end.row
  #     @tableText
  #
  #   @newTableText = null
  insertRow: ->
    baseRow = @range.start.row
    offset = 0
    lines = @tableText.replace(/\r?\n$/, '').split(/\r?\n/)

    for range in @selections
      range.translate [offset, 0], [offset, 0]
      index = range.end.row - baseRow
      line = lines[index]
      newLine = line.replace(/[^\|\s]/g, ' ')
      lines.splice index, 0, newLine
      offset += 1

    @tableText = lines.join @newLine
    @newTableText = null

  # returns promise for this
  getSelectionRanges: (options) ->
    {moveCell, moveRow, moveToColumn, moveToCell} = options
    moveCell ?= 0

    tail = if (moveCell > 0) then 'end' else 'start'

    oldLines = @tableText.replace(/\r?\n$/, '').split(/\r?\n/)
    newLines = @getFormattedTableText().replace(/\r?\n$/, '').split(/\r?\n/)

    newIndex = 0
    selIndex = 0

    baseRow = @range.start.row

    lineMap = {}

    for line,i in oldLines
      while not @linesEqual line, newLines[newIndex]
        newIndex += 1

      lineMap[i] = newIndex
      console.log "map #{i} -> #{newIndex}", line, newLines[newIndex]
      #newIndex += 1

    ranges = []

    for line,i in oldLines
      continue unless @selections.length

      while (range = @selections[selIndex])[tail].row == baseRow+i
        position = range[tail]
        cellPosition = @getCellPosition line, position
        cellPosition.row = baseRow + lineMap[i]

        if moveRow
          if i+moveRow < oldLines.length
            _i = i+moveRow
            while @isRowSeparator lineMap[_i]
              _i += 1

            cellPosition.row = baseRow + lineMap[_i]

        # if moveToRow
        #   cellPosition.row = baseRow + lineMap[moveToRow-1]

        if moveToColumn
          cellPosition.cell = moveToColumn

        if moveToCell
          cellPosition.cell = moveToCell

        if moveCell
          cellPosition.cell += moveCell
          if cellPosition.cell < 1
            # need to set row
            cellPosition.cell = cellPosition.cells -1
            searchLine = i
            while searchLine > 0
              searchLine -= 1
              if @isTableRow oldLines[searchLine]
                cellPosition.row = baseRow + lineMap[searchLine]
                break

          if cellPosition.cell >= cellPosition.cells
            cellPosition.cell = 1
            searchLine = i
            while searchLine < oldLines.length
              searchLine += 1
              if searchLine >= oldLines.length
                break

              if @isTableRow oldLines[searchLine]
                cellPosition.row = baseRow + lineMap[searchLine]
                break

        ranges.push @getRangeFromCellPosition newLines[newIndex], cellPosition
        selIndex += 1

        if selIndex >= @selections.length
          return ranges

    ranges

  addSelection: (selection) ->
    @selections.push selection.getBufferRange().copy()
    @selections.sort (a,b) -> a.compare b
