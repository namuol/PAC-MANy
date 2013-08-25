define 'VerticalMenu', [
  'combo/util'
  'combo/cg'
  'Menu'
  'TextMenuItem'
], (
  util
  cg
  Menu
  TextMenuItem
) ->

  class VerticalMenu extends Menu
    constructor: ->
      super

      @spacing ?= 1
      @items ?= []
      _items = @items
      itemNames = []
      @items = {}
      @alignment ?= 'center'
      @lineHeight ?= @font.lineHeight
      itemHeight = (@lineHeight * @font.charHeight) + @spacing
      @anchor = {}

      if @alignment is 'center'
        @anchor.x = @anchor.y = 0.5
      @height = itemHeight * _items.length - @spacing
      
      top = -@height/2 + itemHeight/2

      for item, num in _items
        name = '_UNDEFINED_'
        switch typeof item
          when 'string'
            if not @font?
              throw new Error 'No font specified.'
            name = item
            @items[name] = @addChild new TextMenuItem(@font, item,
              alignment: @alignment
              spacing: @spacing
              y: top + num * itemHeight
            ), 'items'
          when 'object'
            name = item.name
            item = item.item
            item.y = top + num * itemHeight
            @items[name] = @addChild item, 'items'
          else
            throw new Error 'Unexpected menu item type: ' + typeof item
        itemNames.push name
      i=0
      for own k,item of @items
        item.above = @items[itemNames[util.mod(i-1, itemNames.length)]]
        item.below = @items[itemNames[util.mod(i+1, itemNames.length)]]
        ++i