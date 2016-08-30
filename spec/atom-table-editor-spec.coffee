AtomTableEditor = require '../lib/table-editor'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AtomTableEditor", ->
  [workspaceElement, activationPromise, editor, editorElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('table-editor')

    waitsForPromise ->
      activationPromise

  describe "when a restructuredText file is opened", ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('test.rst').then (e) ->
          editor = e
          editorElement = atom.views.getView(editor)
        .catch (e) ->
          console.log e.stack

    describe "rst file 1", ->
      cleanTable = """
        Hello

        +------------------------+---------------------------------------------------------------------------------------------+
        | Sub Project            | Artifact Path                                                                               |
        +========================+=============================================================================================+
        | Sunflower Studio Tasks | ``src-root/sunflower-studio/sunflower-sri/com.sri.sunflower.distrib.tasks/target/products`` |
        +------------------------+---------------------------------------------------------------------------------------------+
        | Sunflower Studio CE    | ``src-root/sunflower-studio/sunflower-open/com.sri.sunflower.distrib.core/target/products`` |
        +------------------------+---------------------------------------------------------------------------------------------+
        | Floralib               | ``src-root/sunflower-foundation/floralib/target``                                           |
        +------------------------+---------------------------------------------------------------------------------------------+
        | Floralib External      | ``src-root/sunflower-foundation/floralib-ext/target``                                       |
        +------------------------+---------------------------------------------------------------------------------------------+
      """

      beforeEach ->
        editor.insertText """
          Hello

          +------------------------+----------------------------------------------------------------------------+
          | Sub Project            | Artifact Path                                                              |
          +========================+============================================================================+
          | Sunflower Studio Tasks | ``src-root/sunflower-studio/sunflower-sri/com.sri.sunflower.distrib.tasks/target/products`` |
          +------------------------+----------------------------------------------------------------------------+
          | Sunflower Studio CE    | ``src-root/sunflower-studio/sunflower-open/com.sri.sunflower.distrib.core/target/products`` |
          +------------------------+----------------------------------------------------------------------------+
          | Floralib               | ``src-root/sunflower-foundation/floralib/target``                                      |
          +------------------------+----------------------------------------------------------------------------+
          | Floralib External      | ``src-root/sunflower-foundation/floralib-ext/target``                                  |
          +------------------------+----------------------------------------------------------------------------+
        """

      it "can step to next cell", ->
        editor.setCursorBufferPosition [4,1]
        expect('table-editor-active' in editorElement.classList)

        atom.commands.onDidDispatch (event) =>
          expect(editor.getText()).toBe cleanTable
          console.log "did dispatch: ", editor.getCursorBufferPosition()
          console.log "did dispatch: ", (s.getBufferRange() for s in editor.getSelections())
          expect(editor.getCursorBufferPosition().toArray()).toEqual [5,25]

        expect(editor.getCursorBufferPosition().toArray()).toEqual [4,1]
        atom.commands.dispatch editorElement, 'table-editor:next-cell'


  describe "when a markdown file is opened", ->

    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('test.md').then (e) ->
          editor = e
          editorElement = atom.views.getView(editor)
        .catch (e) ->
          console.log e.stack

    describe "markdown file 1", ->
      beforeEach ->
        editor.insertText """
          Hello

          | A | B | C |
          |---|---|---|
          | a | b | c |
          | foo | bar |\n
        """

      it "adds table-editor-active class to text-editor, when cursor enters", ->
        editor.setCursorBufferPosition [0,0]
        expect('table-editor-active' not in editorElement.classList)

        editor.setCursorBufferPosition [4,0]
        expect('table-editor-active' in editorElement.classList)

      it "can step to next cell", ->
        editor.setCursorBufferPosition [4,1]
        expect('table-editor-active' in editorElement.classList)

        atom.commands.onDidDispatch (event) =>
          expect(editor.getText()).toBe """
            Hello

            |  A  |  B  | C |
            |-----|-----|---|
            | a   | b   | c |
            | foo | bar |   |\n
          """
          console.log "did dispatch: ", editor.getCursorBufferPosition()
          console.log "did dispatch: ", (s.getBufferRange() for s in editor.getSelections())
          expect(editor.getCursorBufferPosition().toArray()).toEqual [4,11]

        expect(editor.getCursorBufferPosition().toArray()).toEqual [4,1]
        atom.commands.dispatch editorElement, 'table-editor:next-cell'

      it 'can step to next cell if cursor on border', ->
        editor.setCursorBufferPosition [3,10]
        expect('table-editor-active' in editorElement.classList)

        atom.commands.onDidDispatch (event) =>
          expect(editor.getText()).toBe """
            Hello

            |  A  |  B  | C |
            |-----|-----|---|
            | a   | b   | c |
            | foo | bar |   |\n
          """
          console.log "did dispatch: ", editor.getCursorBufferPosition()
          console.log "did dispatch: ", (s.getBufferRange() for s in editor.getSelections())
          expect(editor.getCursorBufferPosition().toArray()).toEqual [4,1]

        expect(editor.getCursorBufferPosition().toArray()).toEqual [3,10]
        atom.commands.dispatch editorElement, 'table-editor:next-cell'

      it "automatically adds a row, if stepped over last cell", ->
        editor.setCursorBufferPosition [5,13]
        expect('table-editor-active' in editorElement.classList)

        atom.commands.onDidDispatch (event) =>
          expect(editor.getText()).toBe """
            Hello

            |  A  |  B  | C |
            |-----|-----|---|
            | a   | b   | c |
            | foo | bar |   |
            |     |     |   |\n
          """
          console.log "did dispatch: ", editor.getCursorBufferPosition()
          console.log "did dispatch: ", (s.getBufferRange() for s in editor.getSelections())
          expect(editor.getCursorBufferPosition().toArray()).toEqual [6,5]

        expect(editor.getCursorBufferPosition().toArray()).toEqual [5, 13]
        atom.commands.dispatch editorElement, 'table-editor:next-cell'

      it "can insert a new row", ->
        editor.setCursorBufferPosition [3,1]
        expect('table-editor-active' in editorElement.classList)

        atom.commands.onDidDispatch (event) =>
          expect(editor.getText()).toBe """
            Hello

            |  A  |  B  | C |
            |-----|-----|---|
            | a   | b   | c |
            |     |     |   |
            | foo | bar |   |\n
          """
          console.log "did dispatch: ", editor.getCursorBufferPosition()
          console.log "did dispatch: ", (s.getBufferRange() for s in editor.getSelections())
          expect(editor.getCursorBufferPosition().toArray()).toEqual [4,8]

        expect(editor.getCursorBufferPosition().toArray()).toEqual [3,1]
        atom.commands.dispatch editorElement, 'table-editor:add-row'


  # describe "when the atom-table-editor:toggle event is triggered", ->
  #   it "hides and shows the modal panel", ->
  #     # Before the activation event the view is not on the DOM, and no panel
  #     # has been created
  #     expect(workspaceElement.querySelector('.atom-table-editor')).not.toExist()
  #
  #     # This is an activation event, triggering it will cause the package to be
  #     # activated.
  #     atom.commands.dispatch workspaceElement, 'atom-table-editor:toggle'
  #
  #     waitsForPromise ->
  #       activationPromise
  #
  #     runs ->
  #       expect(workspaceElement.querySelector('.atom-table-editor')).toExist()
  #
  #       atomTableEditorElement = workspaceElement.querySelector('.atom-table-editor')
  #       expect(atomTableEditorElement).toExist()
  #
  #       atomTableEditorPanel = atom.workspace.panelForItem(atomTableEditorElement)
  #       expect(atomTableEditorPanel.isVisible()).toBe true
  #       atom.commands.dispatch workspaceElement, 'atom-table-editor:toggle'
  #       expect(atomTableEditorPanel.isVisible()).toBe false
  #
  #   it "hides and shows the view", ->
  #     # This test shows you an integration test testing at the view level.
  #
  #     # Attaching the workspaceElement to the DOM is required to allow the
  #     # `toBeVisible()` matchers to work. Anything testing visibility or focus
  #     # requires that the workspaceElement is on the DOM. Tests that attach the
  #     # workspaceElement to the DOM are generally slower than those off DOM.
  #     jasmine.attachToDOM(workspaceElement)
  #
  #     expect(workspaceElement.querySelector('.atom-table-editor')).not.toExist()
  #
  #     # This is an activation event, triggering it causes the package to be
  #     # activated.
  #     atom.commands.dispatch workspaceElement, 'atom-table-editor:toggle'
  #
  #     waitsForPromise ->
  #       activationPromise
  #
  #     runs ->
  #       # Now we can test for view visibility
  #       atomTableEditorElement = workspaceElement.querySelector('.atom-table-editor')
  #       expect(atomTableEditorElement).toBeVisible()
  #       atom.commands.dispatch workspaceElement, 'atom-table-editor:toggle'
  #       expect(atomTableEditorElement).not.toBeVisible()
