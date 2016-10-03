TableFormatter = require '../lib/table-formatter.coffee'
describe "TableFormatter", ->
  it "can get a range from cell position", ->
    tf = new TableFormatter
    range = tf.getRangeFromCellPosition "| A | b | C |", {cell: 2, row: 2}
    expect(range).toEqual
    expect(range.serialize()).toEqual [[2,5],[2,8]]
    expect(range.start.row).toEqual 2

  it "formats a table", ->
    tableText = """
      | A | B |
      |---|---|
      | foo |
    """
    range = new Range [0,0], [2,7]
    scopeName = 'source.gfm'

    tf = new TableFormatter {tableText, scopeName, range}
    expect(tf.getFormattedTableText()).toBe """
      |  A  | B |
      |-----|---|
      | foo |   |\n
      """

  it "formats a headless table", ->
    tableText = """
      | a | b |\n
    """
    range = new Range [0,0], [0,9]
    scopeName = 'source.gfm'

    tf = new TableFormatter {tableText, scopeName, range}
    expect(tf.getFormattedTableText()).toBe """
      | a | b |
      |---|---|
      |   |   |\n
    """

  it "can format a rst table", ->
    tableText = """
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
    range = new Range [0,0], [9,102]
    scopeName = 'text.restructuredtext'

    tf = new TableFormatter {tableText, scopeName, range}

    expect(tf.getFormattedTableText()).toBe """
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
