{processTableText} = require '../lib/table-processors.coffee'

describe 'Table Processors', ->
  describe 'Markdown Processor', ->
    it "can format a Markdown Table 1", ->
      inputTable = '''
        | first | second |
        |-------|--------|
        | hello | world |
        | another value | here |
      '''

      expect(processTableText(inputTable)).toBe '''
        |     first     | second |
        |---------------|--------|
        | hello         | world  |
        | another value | here   |\n
      '''

    it "can format a Markdown Table 2", ->
      inputTable = '''
        | first | second |
        |-------|--------|
        | hello | world |
        | another value |
      '''

      expect(processTableText(inputTable)).toBe '''
        |     first     | second |
        |---------------|--------|
        | hello         | world  |
        | another value |        |\n
      '''
