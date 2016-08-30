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



    it "can format a RST Table", ->
      inputTable = """
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

      expect(processTableText(inputTable)).toBe '''
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
      '''
