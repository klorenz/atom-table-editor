{CompositeDisposable, Range} = require 'atom'
{processMarkdownTable} = require './table-processors.coffee'
{ScopeSelector} = require 'first-mate'
TableFormatter = require './table-formatter.coffee'
Q = require 'q'

module.exports = TableEditor =
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

    @scopeSelector = new ScopeSelector('source table, text meta.table')

    atom.workspace.observeTextEditors (editor) =>
      @subscriptions.add editor.onDidChangeCursorPosition (event) =>
        # TODO: attach .table-editor-active to editor if cursor in .table env
        view = atom.views.getView(editor)
        isActive = 'table-editor-active' in view.classList

        for position in editor.getCursorBufferPositions()
          scopes = editor.scopeDescriptorForBufferPosition(position).scopes
          if @scopeSelector.matches scopes
            return if isActive
            return view.classList.add('table-editor-active')

        if isActive
          view.classList.remove('table-editor-active')

    grammar = require './table-grammar.coffee'
    @subscriptions.add atom.grammars.addGrammar grammar

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
    @scopeSelector.matches editor.scopeDescriptorForBufferPosition(position).scopes

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

    row = position.row
    while @isInTable editor, [row, position.column]
      row -= 1

    start = [row+1, 0]

    row = position.row
    while @isInTable editor, [row, position.column]
      row += 1

    end = editor.getBuffer().rangeForRow(row-1, includeNewLine: true).end

    new TableFormatter editor, new Range start, end

  formatTable: (options) ->
    editor = atom.workspace.getActiveTextEditor()
    selections = editor.getSelections()
    {tables, ranges} = @getTablesForSelections editor, selections

    for table in tables
      for range in table.format(options)
        ranges.push range

    ranges.sort (a,b) -> a.compare b

    for selection in selections
      selection.destroy()

    selection = editor.getLastSelection()

    for range in ranges
      console.log range
      editor.addSelectionForBufferRange range

    selection.destroy()

  # toggle: ->
  #   console.log 'AtomTableEditor was toggled!'
  #
  #   if @modalPanel.isVisible()
  #     @modalPanel.hide()
  #   else
  #     @modalPanel.show()
