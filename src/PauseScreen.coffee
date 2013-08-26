define 'PauseScreen', [
  'combo/cg'
  'combo/Scene'
  'VerticalMenu'
  'combo/Tween'
  'combo/SpriteActor'
], (
  cg
  Scene
  VerticalMenu
  Tween
  SpriteActor
) ->

  class PauseScreen extends VerticalMenu
    items: [
      'Restart'
      'Level Select'
      'Resume'
      'Options'
    ]
    layers: [
      'bg'
      'items'
    ]
    constructor: ->
      @font = cg.app.font
      @selectKey = [cg.K_X, cg.K_ENTER]
      @alignment = 'center'
      @spacing = 0.85
      @lineHeight = 0.75
      
      super

      bg = new SpriteActor
        texture: 'black'
        anchor:
          x: 0.5
          y: 0.5
        scaleX: 75
        scaleY: @height + 2
        x: 1
        y: -1
        alpha: 0.8
      
      @addChild bg, 'bg'

      @input.mapKey cg.K_Q, 'back'

      @visible = false
      @pause()

      @scaleX = 0
      # @scaleY = 12

      @tweenIn = @tween
        values:
          scaleX: 4
          # scaleY: 4
        duration: 150
        easeFunc: Tween.Elastic.Out
      
      @tweenIn.onStart.add =>
        @visible = true

      @tweenOut = @tween
        values:
          scaleX: 0
          # scaleY: 12
        duration: 75
        easeFunc: Tween.Back.In
      
      @tweenOut.onComplete.add =>
        @visible = false
        @selectItem @items['Restart']
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
      for own k,item of @items
        item.alpha = 0.5
        item.onFocus.add (item) ->
          item.alpha = 1
        item.onBlur.add (item) ->
          item.alpha = 0.5
      resume = =>
        @hide =>
          cg.app.world.resume()

      @items.Resume.onSelect.add resume
      @actions.back.onHit.add resume
      @items.Restart.onSelect.add =>
        @hide =>
          world = cg.app.world
          world.resume()
          world.refreshMap()
          world.resetLevel()

      @items['Level Select'].onSelect.add =>
        @hide ->
          cg.app.world.hide ->
            cg.app.levelSelect.show()

      @items.Options.onSelect.add =>
        @hide =>
          options = cg.app.optionScreen
          options.onBack.addOnce => options.hide => @show()
          options.show()
      
      super