define 'TitleScreen', [
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
  STR = 'Press X or Enter to Play'
  class TitleScreen extends VerticalMenu
    items: [
      STR
    ]
    constructor: ->
      
      @font = cg.app.font
      @selectKey = [cg.K_X, cg.K_ENTER]
      @alignment = 'center'
      @spacing = 0.85
      @lineHeight = 0.75
      super

      @pakku = new SpriteActor
        anim: cg.app.sheet.anim [0,1,2,3,4,5,4,3,2,1], 30
        scaleX: 6
        scaleY: 6
        width: 13
        height: 13
        anchor:
          x: 0.5
          y: 0.5
        y: 230
      @addChild @pakku

      @startX = @x
      @title = @addChild new SpriteActor
        y: -130
        anchor:
          x: 0.5
          y: 0.5
        texture: app.gfx.title
      
      @items[STR].y = cg.app.height - 80

      @titleTweenIn = @title.tween
        duration: 1000
        values:
          y: @title.height/2 + 10
        easeFunc: Tween.Elastic.Out
      @titleTweenIn.onComplete.add => @titleTweenA.start()

      @titleTweenA = @title.tween
        duration: 1000
        # values:
        #   scaleX: 0.95
        #   scaleY: 0.95
      @titleTweenA.onComplete.add => @titleTweenB.start()
      @titleTweenB = @title.tween
        duration: 1000
        # values:
        #   scaleX: 1
        #   scaleY: 1
      @titleTweenB.onComplete.add => @titleTweenA.start()

      @visible = false
      @alpha = 0
      @pause()

      @tweenIn = @tween
        values:
          alpha: 1
          x: @startX
        duration: 150
        easeFunc: Tween.Back.Out
      
      @tweenIn.onStart.add =>
        @title.y = -100
        @visible = true
      @tweenIn.onComplete.add =>
        @titleTweenIn.start()

      @tweenOut = @tween
        values:
          x: -cg.app.width
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
      for own k,item of @items
        item.alpha = 0.5
        item.onFocus.add (item) ->
          item.alpha = 1
        item.onBlur.add (item) ->
          item.alpha = 0.5

      @items[STR].onSelect.add =>
        @hide =>
          levelSelect = cg.app.levelSelect
          levelSelect.onBack.addOnce =>
            @show()
          levelSelect.show()

      super

    update: ->
      super
      @pakku.rotation += 0.1
