{Range} = require 'atom'
{processTableText} = require './table-processors.coffee'
module.exports =
class TableFormatter

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

      if _cell == cell
        start = i

      if _cell == cell+1
        end = i
        break

    start += 1 while lineText[start] != ' '
    end -= 1 while lineText[end] != ' '

    return new Range [start, row], [end, row]

  constructor: (@editor, @range) ->

    @tableText = @editor?.getTextInBufferRange @range
    @scopeName = @editor?.scopeDescriptorForBufferPosition(range.start).scopes[0]
    @selections = []

    console.log "text\n", @tableText

  setRelativePosition: (position) ->

  containsPoint: (point) -> @range.containsPoint point

  linesEqual: (a, b) ->
    a = a.replace /\s*\|\s*/g, ''
    b = b.replace /\s*\|\s*/g, ''

    (a == b) or a.match(/^[\+=\-]+$/) and b.match(/^[\+=\-]+$/)

  isTableRow: (line) ->
    line.match /^\s*\|[^-=].*\|$/

  # returns promise for this
  format: (options) ->
    {moveCell} = options
    moveCell ?= 0

    @newTableText = processTableText @tableText, @scopeName

    tail = if (moveCell > 0) then 'end' else 'start'
    @editor.getBuffer().setTextInRange @range, @newTableText

    oldLines = @tableText.replace(/\r?\n$/, '').split(/\r?\n/)
    newLines = @newTableText.replace(/\r?\n$/, '').split(/\r?\n/)

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
      while (range = @selections[selIndex])[tail].row == baseRow+i
        position = range[tail]
        cellPosition = @getCellPosition line, position
        cellPosition.row = baseRow + lineMap[i]

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
