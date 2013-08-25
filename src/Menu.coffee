define 'Menu', [
  'combo/cg'
  'combo/Scene'
  'MenuItem'
], (
  cg
  Scene
  MenuItem
) ->

  class Menu extends Scene
    constructor: ->
      super

      @upKey ?= cg.K_UP
      @downKey ?= cg.K_DOWN
      @leftKey ?= cg.K_LEFT
      @rightKey ?= cg.K_RIGHT
      @selectKey ?= cg.K_ENTER

    init: ->
      super

      @input.mapKey @upKey, 'up'
      @input.mapKey @downKey, 'down'
      @input.mapKey @leftKey, 'left'
      @input.mapKey @rightKey, 'right'
      @input.mapKey @selectKey, 'select'

      i=0
      for own k,item of @items
        break  if i isnt 0
        @selected = item
        @selected.focus()
        ++i

    selectItem: (item) ->
      return  if not item?
      @selected.blur()
      @selected = item
      item.focus()

    update: ->
      super
      return  if not @selected?

      btn = @actions

      if @selected.above? and btn.up.hit()
        @selectItem @selected.above
      else if @selected.below? and btn.down.hit()
        @selectItem @selected.below
      else if @selected.left? and btn.left.hit()
        @selectItem @selected.left
      else if @selected.right? and btn.right.hit()
        @selectItem @selected.right
      
      if btn.select.hit()
        @selected.select()