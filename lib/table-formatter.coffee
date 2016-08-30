{Range} = require 'atom'
{processTableText} = require './table-processors.coffee'

log_debug = ->
#log_debug = console.debug.bind(console, "table-editor, table-processors")

module.exports =
class TableFormatter
  constructor: ({@tableText, @scopeName, @range}={}) ->

    #@tableText = @editor?.getTextInBufferRange @range
    #@scopeName = @editor?.scopeDescriptorForBufferPosition(range.start).scopes[0]
    @selections = []
    @newLine = "\n"

    log_debug "TableFormatter: @tableText", @tableText

    #console.log "text\n", @tableText

  getCellPosition: (lineText, position) ->
    {row, column} = position
    [cell, offset, cells] = [0, 0, 0]

    cellBorder = '|'

    for c,i in lineText
      if c == cellBorder
        cells += 1

      if i >= column
        continue

      if c == cellBorder
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

    start += 1 while lineText[start] != ' ' and start < lineText.length
    end -= 1 while lineText[end] != ' ' and end > 0

    # end counted one too far
    return new Range [row, start], [row, end+1]

  getTableRange: -> @range

  containsPoint: (point) -> @range.containsPoint point

  linesEqual: (a, b) ->
    return false unless b

    a = a.replace /\s*\|\s*/g, ''
    b = b.replace /\s*\|\s*/g, ''

    (a == b) or a.match(/^[\+=\-]+$/) and b.match(/^[\+=\-]+$/)

  isRowSeparator: (line) ->
    return line.match /^((\+=+)+\+|(\+-+)+\+|(\|-+)+\|)$/

  isTableRow: (line) ->
    line.match /^\s*\|[^-=].*\|$/

  getFormattedTableText: ->
    return @newTableText if @newTableText

    tableText = @tableText
    indent = null
    if m = tableText.match(/^(\s+)/)
      indent = m[1]
      tableText = @tableText.replace(new RegExp("(^|\\n)#{indent}", 'g'), (m, nl) -> nl)

    @newTableText = processTableText tableText, @scopeName

    if indent?
      @newTableText = @newTableText.replace(/(^|\n)/g, (m, nl) -> nl + indent).replace(/\s+$/, @newLine)

    return @newTableText

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
  insertRow: ({before}={})->
    baseRow = @range.start.row
    offset = 0
    lines = @tableText.replace(/\r?\n$/, '').split(/\r?\n/)

    for range in @selections
      range.translate [offset, 0], [offset, 0]
      index = range.end.row - baseRow
      if not before
        index += 1

      line = lines[index]
      newLine = line.replace(/[^\|\s]/g, ' ')
      lines.splice index, 0, newLine
      offset += 1

    @tableText = lines.join @newLine
    @newTableText = null

  appendRow: ->
    lines = @tableText.replace(/\r?\n$/, '').split(/\r?\n/)

    lastTableRow = ''
    i = 0
    while not @isTableRow lastTableRow
      i += 1
      lastTableRow = lines[lines.length - i]

    @tableText = @tableText + lastTableRow.replace(/[^\|\s]/g, ' ') + @newLine

    if i > 1
      @tableText += lines[lines.length-1] + @newLine

    @newTableText = null


  # returns promise for this
  getSelectionRanges: (options) ->
    {moveCell, moveRow, moveToColumn, moveToCell} = options
    moveCell ?= 0

    tail = if (moveCell > 0) then 'end' else 'start'

    oldLines = @tableText.replace(/\r?\n$/, '').split(/\r?\n/)
    newLines = @getFormattedTableText().replace(/\r?\n$/, '').split(/\r?\n/)

#    console.log "oldLines", oldLines
#    console.log "newLines", newLines

    newIndex = 0
    selIndex = 0

    baseRow = @range.start.row

    lineMap = {}

    for line,i in oldLines
      while not @linesEqual line, newLines[newIndex]
        newIndex += 1

      lineMap[i] = newIndex

      # count up, also two equal sequential lines are mapped correct
      newIndex += 1

    # have counted one too far
    newIndex -= 1

    debugger

    ranges = []

    for line,i in oldLines
      continue unless @selections.length

      while (range = @selections[selIndex])[tail].row == baseRow+i
        position = range[tail]

        oldIndex = i

        if @isRowSeparator line
          _i = oldIndex+1
          while @isRowSeparator oldLines[_i]
            _i += 1
          oldIndex = _i

          position = {column: 1}

          if moveCell > 0
            moveCell -= 1

        cellPosition = @getCellPosition oldLines[oldIndex], position
        cellPosition.row = baseRow + lineMap[oldIndex]

        if moveRow
          if oldIndex+moveRow < oldLines.length
            _i = oldIndex+moveRow
            while @isRowSeparator newLines[lineMap[_i]]
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
            cellPosition.cell = cellPosition.cells - 1
            searchLine = oldIndex
            while searchLine > 0
              searchLine -= 1
              if @isTableRow oldLines[searchLine]
                cellPosition.row = baseRow + lineMap[searchLine]
                break

          if cellPosition.cell >= cellPosition.cells
            cellPosition.cell = 1
            searchLine = oldIndex
            while searchLine < oldLines.length
              searchLine += 1
              if searchLine >= oldLines.length
                @appendRow()
                cellPosition.row = baseRow + lineMap[searchLine-1] + 1
                break

              if @isTableRow oldLines[searchLine]
                cellPosition.row = baseRow + lineMap[searchLine]
                break

        debugger

        #ranges.push @getRangeFromCellPosition newLines[newIndex], cellPosition
        ranges.push @getRangeFromCellPosition newLines[lineMap[oldIndex]], cellPosition
        selIndex += 1

        if selIndex >= @selections.length
          return ranges

    ranges

  addSelection: (selection) ->
    @selections.push selection.getBufferRange().copy()
    @selections.sort (a,b) -> a.compare b
