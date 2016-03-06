{CompositeDisposable, Range} = require 'atom'
{processMarkdownTable} = require './table-processors.coffee'
# {ScopeSelector} = require 'first-mate'
TableFormatter = require './table-formatter.coffee'
Q = require 'q'

log_debug = ->
#log_debug = console.debug.bind(console, "table-editor")

module.exports = TableEditor =
  # config:
  #   enableCharacterMnemonics:
  #     type: "boolean"
  #     default: false
  #     description: """
  #       If enabled, you can use character mnemonics for inserting unicode
  #       characters as described in RFC 1345.  You may know this feature from
  #       VIM as "digraphs".
  #     """

  subscriptions: null

  activate: (state) ->
    #@atomTableEditorView = new AtomTableEditorView(state.atomTableEditorViewState)
    #@modalPanel = atom.workspace.addModalPanel(item: @atomTableEditorView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    # @subscriptions.add atom.commands.add 'atom-workspace', 'atom-table-editor:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-text-editor.table-editor-active',
      'table-editor:next-cell': => @formatTable moveCell: 1
    @subscriptions.add atom.commands.add 'atom-text-editor.table-editor-active',
      'table-editor:prev-cell': => @formatTable moveCell: -1
    @subscriptions.add atom.commands.add 'atom-text-editor.table-editor-active',
      'table-editor:format': => @formatTable()

    @subscriptions.add atom.commands.add 'atom-text-editor.table-editor-active',
      'table-editor:insert-row-after-current-row': => @formatTable moveToColumn: 1, moveRow: 1, withTable: (table) ->
         table.insertRow()

    @subscriptions.add atom.commands.add 'atom-text-editor.table-editor-active',
      'table-editor:insert-row-before-current-row': => @formatTable moveToColumn: 1, moveRow: 0, withTable: (table) ->
         table.insertRow(before: yes)

    # @subscriptions.add atom.commands.add 'atom-text-editor.table-editor-active',
    #   'table-editor:add-row': => @formatTable moveToColumn: 1, moveRow: 1, withTable: (table) ->
    #     table.insertRow()

    # @subscriptions.add atom.commands.add 'atom-text-editor.table-editor-active.table-editor-multi-line',
    #   'table-editor:add-new-cell-line': => @formatTable()


    atom.workspace.observeTextEditors (editor) =>
      @subscriptions.add editor.onDidChangeCursorPosition (event) =>
        @didChangeCursorPosition(editor)

    grammar = require './table-grammar.coffee'
    @subscriptions.add atom.grammars.addGrammar grammar

  didChangeCursorPosition: (editor) ->
    view = atom.views.getView(editor)
    isActive = 'table-editor-active' in view.classList
    log_debug("didChangeCursorPosition: #{isActive}")

    for position in editor.getCursorBufferPositions()
      if @isInTable editor, position
        log_debug("isInTable!")
        return if isActive

        view.classList.add('table-editor-active')
        if @isMultiLine(editor, position)
          view.classList.add('table-editor-multi-line')

        #atom.notifications.addInfo "Classes: "+view.classList

        return

    if isActive
      view.classList.remove('table-editor-active')
      if 'table-editor-multi-line' in view.classList
        view.classList.remove('table-editor-multi-line')

      #atom.notifications.addInfo "Classes: "+view.classList

  deactivate: ->
    #@modalPanel.destroy()
    @subscriptions.dispose()
    #@atomTableEditorView.destroy()

  serialize: ->
    #atomTableEditorViewState: @atomTableEditorView.serialize()

  tableContaining: (tables, position) ->
    for table in tables
      return table if table.containsPoint position
    return false

  isInTable: (editor, position) ->
    # first we assume, there is a table, if there are more than 2 | in a row
    # and it starts and ends with |
    line = editor.lineTextForBufferRow position.row ? position[0]
    if line.match /^\s*\|.*?\|.*\|\s*$/
      return true

    # this would be the elegant way, but requiring first-mate is a mess
    # @scopeSelector = new ScopeSelector('source table, text meta.table')
    # @scopeSelector.matches editor.scopeDescriptorForBufferPosition(position).scopes
    scopes = editor.scopeDescriptorForBufferPosition(position).scopes
    if scopes[0].match /^text\.restructuredtext/
      line = editor.lineTextForBufferRow position.row
      #log_debug position, line
      if line and line.match /(^\s*\|.*\|$|^\s*\+(\=+\+)+$|^\s*\+(\-+\+)+$)/
        return true

    log_debug scopes
    return false unless scopes[0].match /^(text|source)(\.|$)/

    for scope in scopes
      log_debug scope
      return true if scope.match /^(table|meta\.table|markup\.other\.table)(\.|$)/

    return false


  isMultiLine: (editor, position) ->
    'restructuredtext' in editor.scopeDescriptorForBufferPosition(position).scopes[0]


  getTablesForSelections: (editor, selections) ->
    tables = []
    ranges = []
    for selection in selections
      position = selection.cursor.getBufferPosition()
      if table = @tableContaining tables, position
        table.addSelection selection
        continue

      if table = @getTableForSelection editor, selection
        tables.push table
        table.addSelection selection
      else
        ranges.push selection.getBufferRange().copy()

    {tables, ranges}

  getTableForSelection: (editor, selection) ->
    position = selection.cursor.getBufferPosition()
    return unless @isInTable editor, position

    # TODO: respect indentation?

    row = position.row
    while @isInTable editor, [row, position.column]
      row -= 1

    start = [row+1, 0]

    row = position.row
    while @isInTable editor, [row, position.column]
      row += 1

    end = editor.getBuffer().rangeForRow(row-1, includeNewLine: true).end

    range     = new Range start, end
    tableText = editor.getTextInBufferRange range
    scopeName = editor.scopeDescriptorForBufferPosition(position).scopes[0]

    new TableFormatter {range, tableText, scopeName}

  formatTable: (options={}) ->
    editor = atom.workspace.getActiveTextEditor()
    selections = editor.getSelections()
    {tables, ranges} = @getTablesForSelections editor, selections

    for table in tables
      if options.withTable
        options.withTable(table)

      for range in table.getSelectionRanges(options)
        ranges.push range

      editor.setTextInBufferRange table.getTableRange(), table.getFormattedTableText()

    log_debug ranges
    ranges.sort (a,b) -> a.compare b

    for selection in selections
      selection.destroy()

    selection = editor.getLastSelection()

    for range in ranges
      log_debug range
      editor.addSelectionForBufferRange range

    selection.destroy()

    @didChangeCursorPosition(editor)



  # toggle: ->
  #   console.log 'AtomTableEditor was toggled!'
  #
  #   if @modalPanel.isVisible()
  #     @modalPanel.hide()
  #   else
  #     @modalPanel.show()
