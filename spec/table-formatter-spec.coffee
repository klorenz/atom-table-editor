TableFormatter = require '../lib/table-formatter.coffee'
describe "TableFormatter", ->
  it "can get a range from cell position", ->
    tf = new TableFormatter
    range = tf.getRangeFromCellPosition "| A | b | C |", {cell: 2, row: 2}
    expect(range).toEqual
    expect(range.serialize()).toEqual [[2,5],[2,7]]
    expect(range.start.row).toEqual 2

  it "format a table", ->
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
