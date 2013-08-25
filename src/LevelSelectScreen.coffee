define 'LevelSelectScreen', [
  'combo/cg'
  'combo/Scene'
  'VerticalMenu'
  'combo/Tween'
  'combo/SpriteActor'
  'combo/util/Signal'
], (
  cg
  Scene
  VerticalMenu
  Tween
  SpriteActor
  Signal
) ->

  pad = (n, width, z) -> 
    z = z || '0'
    n = n + ''
    if n.length >= width then n else new Array(width - n.length + 1).join(z) + n

  class LevelSelectScreen extends VerticalMenu
    constructor: ->
      @font = cg.app.font
      @selectKey = [cg.K_X, cg.K_ENTER]
      @alignment = 'center'
      @spacing = 0.85
      @lineHeight = 0.75

      @items = ['back']
      for levels,i in cg.app.levels
        @items.push pad i, 2
      
      super
      
      @startX = @x

      @onBack = new Signal
      
      @input.mapKey cg.K_Q, 'back'

      @visible = false
      @pause()

      @tweenIn = @tween
        values:
          x: @startX
        duration: 150
        easeFunc: Tween.Back.Out
      
      @tweenIn.onStart.add =>
        @visible = true

      @tweenOut = @tween
        values:
          x: cg.app.width
        duration: 150
        easeFunc: Tween.Back.In
      
      @tweenOut.onComplete.add =>
        @visible = false
        return

    hide: (cb) ->
      @pause()
      @tweenOut.onComplete.addOnce cb  if cb?
      @tweenOut.start()

    show: (cb) ->
      @resume()
      @tweenIn.onComplete.addOnce cb  if cb?
      @tweenIn.start()

    init: ->
      @actions.back.onHit.add =>
        @hide => @onBack.dispatch @

      @items.back.onSelect.add =>
        @hide => @onBack.dispatch @

      for own k,item of @items
        item.alpha = 0.5
        item.onFocus.add (item) ->
          item.alpha = 1
        item.onBlur.add (item) ->
          item.alpha = 0.5

        continue  if k is 'back'
        item.onSelect.add (item) =>
          levelNum = parseInt item.string
          cg.app.world.loadLevel levelNum
          cg.app.world.resetLevel()
          @hide => cg.app.world.show()

      super

  return LevelSelectScreen