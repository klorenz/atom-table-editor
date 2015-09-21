grammar = require '../lib/table-grammar.coffee'
{CompositeDisposable} = require 'atom'

describe 'TableGrammar', ->
  [editor, subscriptions, editorPromise] = []

  describe 'it can highlight tables', ->
    beforeEach ->
      subscriptions = new CompositeDisposable
      subscriptions.add atom.grammars.addGrammar grammar
      waitsForPromise ->
        atom.workspace.open('test.md').then (e) ->
          editor = e
        .catch (e) ->
          console.log e.stack

    afterEach ->
      subscriptions.dispose()

    it "can highlight a simple grammar", ->
      editor.insertText '''
        | no | pet |
        |----|-----|
        |  1 | cat |
        |  2 | dog |
      '''
      expect(editor.scopeDescriptorForBufferPosition([0, 0]).scopes).toEqual [
         'text.plain.null-grammar', 'meta.table', 'meta.table.row.table',
         'keyword.operator.table-border.vertical.table'
      ]
