define 'TextMenuItem', [
  'combo/cg'
  'MenuItem'
  'combo/text/TextString'
], (
  cg
  MenuItem
  TextString
) ->

  class TextMenuItem extends MenuItem
    constructor: (@font, @string='', params) ->
      super params

      @textString = @addChild new TextString @font, @string,
        alignment: @alignment
        spacing: @spacing

    updateText: ->
      @textString.string = @string
      @textString.updateText()