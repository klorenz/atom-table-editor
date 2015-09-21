{processMarkdownTable} = require '../lib/table-processors.coffee'

describe 'Table Processors', ->
  describe 'Markdown Processor', ->
    it "can format a Markdown Table 1", ->
      inputTable = '''
        | first | second |
        |-------|--------|
        | hello | world |
        | another value | here |
      '''

      waitsForPromise ->
        processMarkdownTable(inputTable).then (table) ->
          expect(table).toBe '''
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

      waitsForPromise ->
        processMarkdownTable(inputTable).then (table) ->
          expect(table).toBe '''
            |     first     | second |
            |---------------|--------|
            | hello         | world  |
            | another value |        |\n
            '''
