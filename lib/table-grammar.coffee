{makeGrammar} = require 'atom-syntax-tools'

grammar =
  name: "Ascii Table"
  scopeName: 'text.table'
  fileTypes: []
  injectionSelector: 'source, text'

  macros:
    rstTableBorder: /^\s*(?:\+=+)+\+$/
    rstRowBorder: /^\s*(?:\+-+)+\+$/
    mdTableBorder: /^\s*(?:\|(?:-+|:-+:|:-+|-+:))+\|$/
    tableRow: /^\s*\|.*\|$/
    EOR: '(?<=\\|)$'  # end of row

  patterns: [
    {
      n: 'meta.table.restructuredtext'
      b: /(?={rstTableBorder})/
      e: /(?!(?:{tableRow}|{rstTableBorder}|{rstRowBorder}))/
      p: [
        '#tableRow'
        '#restTableBorder'
      ]
    }
    {
      N: 'meta.table'
      b: /(?={tableRow})/
      e: /(?!{tableRow})/
      p: [
        '#markdownTableBorder'
        '#tableRow'
      ]
    }
  ]

  repository:
    tableRow:
      n: 'meta.table.row'
      b: /^(?=\s*\|)/
      e: /{EOR}/
      p: [
        '#tableCellBorder'
      ]

    tableCellBorder:
      n: 'keyword.operator.table-border.vertical'
      m: /\|/

    tableBorderHorizontal:
      n: 'keyword.operator.table-border.horizontal'
      m: /-+/

    markdownTableBorder:
      n: 'meta.table.border.markdown'
      b: /(?={mdTableBorder})/
      e: /{EOR}/
      p: [
        '#tableCellBorder'
        '#tableBorderHorizontal'
        {
          n: 'keyword.operator.align.markdown'
          m: /:/
        }
      ]

    rstTableBorder:
      n: 'meta.table.border.restructuredtext'
      b: /(?={rstTableBorder})/
      e: /{EOR}/

module.exports = atom.grammars.createGrammar __filename, makeGrammar grammar
