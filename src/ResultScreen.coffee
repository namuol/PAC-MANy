define 'ResultScreen', [
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

  class ResultScreen extends VerticalMenu
    items: [
      'Next Level'
      'Retry'
      'Level Select'
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

      @layers.items.y = @layers.bg.y = 100
      @layers.items.scaleX = @layers.items.scaleY = 4
      @layers.bg.scaleX = @layers.bg.scaleY = 4

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

      @fail = @addChild new SpriteActor
        texture: 'fail'
        anchor:
          x: 0.25
          y: 0.5
        # visible: false
        x: -0.25 * 320
        y: -75

      @clear = @addChild new SpriteActor
        texture: 'clear'
        anchor:
          x: 0.5
          y: 0.5
        y: -50
        visible: false

      @input.mapKey cg.K_Q, 'back'

      @visible = false
      @pause()

      # @scaleX = 0
      # @scaleY = 12

      @tweenIn = @tween
        duration: 150
        easeFunc: Tween.Elastic.Out
        # values:
        #   scaleX: 4
        #   scaleY: 4

      @failTween = @fail.tween
        values:
          y: @fail.y
        easeFunc: Tween.Bounce.Out
        duration: 700

      @failTween2 = @fail.tween
        values:
          rotation: 0.35
        easeFunc: Tween.Bounce.Out
        duration: 600

      @failTween.onComplete.add =>
        @failTween2.start()

      @clearTween = @clear.tween
        duration: 700
        values:
          scaleX: 1.1
          scaleY: 1.1
          rotation: 0
        easeFunc: Tween.Elastic.Out
      
      @tweenIn.onStart.add =>
        @scaleY = @scaleX = 1

        @fail.y = -250
        @fail.rotation = 0
        @failTween.start()
        
        @clear.scaleX = 0
        @clear.scaleY = 0
        @clear.rotation = -2
        @clearTween.start()

        @visible = true

      @tweenOut = @tween
        values:
          scaleX: 0
          # scaleY: 12
        duration: 75
        easeFunc: Tween.Back.In
      
      @tweenOut.onComplete.add =>
        @visible = false
        @selectItem @items['Level Select']
        return

    hide: (cb) ->
      @pause()
      @tweenOut.onComplete.addOnce cb  if cb?
      @tweenOut.start()

    show: (cb) ->
      failed = cg.app.world.dotCount > 0
      @fail.visible = failed
      @clear.visible = !failed

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

      @items['Level Select'].onSelect.add =>
        @hide ->
          cg.app.world.hide ->
            cg.app.levelSelect.show()
      @items['Retry'].onSelect.add =>
        @hide ->
          cg.app.world.resume()
          cg.app.world.refreshMap()
          cg.app.world.resetLevel()
      
      super