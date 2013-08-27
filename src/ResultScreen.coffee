define 'ResultScreen', [
  'combo/cg'
  'combo/Scene'
  'VerticalMenu'
  'combo/Tween'
  'combo/SpriteActor'
  'combo/text/TextString'
], (
  cg
  Scene
  VerticalMenu
  Tween
  SpriteActor
  TextString
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
      @layers.items.scaleX = @layers.items.scaleY = 2
      @layers.bg.scaleX = @layers.bg.scaleY = 2

      bg = new SpriteActor
        texture: 'black'
        anchor:
          x: 0.5
          y: 0.5
        scaleX: 750
        scaleY: 750
        x: 1
        y: -1
        alpha: 0.4
      
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
        y: -85
        visible: false

      @excellent = @addChild new SpriteActor
        texture: 'excellent'
        anchor:
          x: 0.5
          y: 0.5
        y: -85
        visible: false

      @excellentText = @addChild new TextString cg.app.font, ''
      @excellentText.scaleX = @excellentText.scaleY = 2
      @excellentText.x = -150
      @excellentText.y = -20

      @timeLeftText = @addChild new TextString cg.app.font, ''
      @timeLeftText.scaleX = @timeLeftText.scaleY = 2
      @timeLeftText.x = -150
      @timeLeftText.y = 0

      @input.mapKey cg.K_Q, 'back'
      @input.mapKey cg.K_R, 'retry'

      @visible = false
      @pause()

      # @scaleX = 0
      # @scaleY = 12

      @tweenIn = @tween
        duration: 250
        values:
          alpha: 1

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
      
      @excellentTween = @excellent.tween
        duration: 700
        values:
          scaleX: 1.1
          scaleY: 1.1
          rotation: 0
        easeFunc: Tween.Elastic.Out

      @tweenIn.onComplete.add =>
        @scaleY = @scaleX = 1

        @fail.y = -250
        @fail.rotation = 0
        @failTween.start()
        
        @clear.scaleX = 0
        @clear.scaleY = 0
        @clear.rotation = -2
        @clearTween.start()

        @excellent.scaleX = 0
        @excellent.scaleY = 0
        @excellent.rotation = -6
        @excellentTween.start()

        if @fail.visible
          cg.app.sfx.badnom.play()
        else
          cg.app.sfx.yay.play()

        @visible = true

      @tweenOut = @tween
        values:
          scaleX: 0
          # scaleY: 12
        duration: 75
        easeFunc: Tween.Back.In
      
      @tweenOut.onComplete.add =>
        @visible = false
        return

    hide: (cb) ->
      @pause()
      @tweenOut.onComplete.addOnce cb  if cb?
      @tweenOut.start()

    show: (cb) ->
      @selectItem @items['Next Level']
      @alpha = 0
      excellent = cg.app.world.timeSplit > cg.app.world.level.excellent
      failed = cg.app.world.dotCount > 0
      @fail.visible = failed
      @clear.visible = !failed and !excellent
      @excellent.visible = excellent and !failed
      @excellentText.string = 'excellent: ' + cg.app.world.timer.timeStringFor cg.app.world.level.excellent
      @excellentText.updateText()
      @excellentText.visible = true

      @timeLeftText.visible = !failed
      @timeLeftText.string = 'score: ' + cg.app.world.timer.timeStringFor cg.app.world.timeSplit
      @timeLeftText.updateText()

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
      @items['Next Level'].onSelect.add =>
        @hide =>
          if cg.app.world.levelNumber >= cg.app.levels.length - 1
            cg.app.world.hide ->
              cg.app.levelSelect.show()
          else
            cg.app.world.resume()
            cg.app.world.loadLevel cg.app.world.levelNumber + 1
            cg.app.world.refreshMap()
            cg.app.world.resetLevel()

      @items['Level Select'].onSelect.add =>
        @hide ->
          cg.app.world.hide ->
            cg.app.levelSelect.show()
      retry = =>
        @hide ->
          cg.app.world.resume()
          cg.app.world.refreshMap()
          cg.app.world.resetLevel()

      @actions.retry.onHit.add retry
      @items['Retry'].onSelect.add retry
      
      super