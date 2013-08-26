define 'Timer', [
  'combo/cg'
  'combo/util'
  'combo/Actor'
  'combo/SpriteActor'
  'combo/modules/ui'
  'combo/TextureGrid'
  'Coffixi/primitives/Graphics'
  'combo/Tween'
  'combo/text/TextString'
  'combo/util/Signal'
], (
  cg
  util
  Actor
  SpriteActor
  ui
  TextureGrid
  Graphics
  Tween
  TextString
  Signal
) ->
  pad = (n, width, z) -> 
    z = z || '0'
    n = n + ''
    if n.length >= width then n else new Array(width - n.length + 1).join(z) + n

  DEFAULT_DURATION = 10 * 1000

  class Timer extends Actor
    anchor:
      x: 0.5
      y: 0.5
    constructor: ->
      super
      @font = cg.app.font
      @timeLeft = DEFAULT_DURATION
      @bonusTime = 0
      @seconds = new TextString @font, ''+Math.floor(@timeLeft/1000),
        alignment: 'right'
      @seconds.x = 25
      @seconds.scaleX = @seconds.scaleY = 2
      @ms = new TextString @font, '.000'
      @ms.x = 25
      @ms.y = 5

      @addChild @ms
      @addChild @seconds

      @onDrain = new Signal
      @onTick = new Signal

      tickTween = @seconds.tween
        duration: 500
        values:
          scaleX: 2
          scaleY: 2

      @onTick.add =>
        if @timeLeft > 0
          @seconds.scaleX = @seconds.scaleY = 2 + 4 * (1/Math.max(1, @timeLeft/1000))
          tickTween.start()
        else
          @timeLeft = 0
          @ms.string = '.000'
          @ms.updateText()
          @onDrain.dispatch()
          @stop()
    updateText: ->
      secs = Math.floor(@timeLeft/1000)
      @seconds.string = '' + secs
      @seconds.updateText()
      @ms.string = '.' + pad(@timeLeft - 1000*secs, 3)
      @ms.updateText()
    stop: ->
      @stopped = true
    resetBonus: ->
      @bonusTime = 0
      @updateText()
    addBonus: (amt) ->
      @timeLeft += amt
      @bonusTime += amt
      @updateText()
    restart: ->
      @timeLeft = DEFAULT_DURATION + @bonusTime
      @stopped = false
      @updateText()
    timeString: -> pad @timeLeft/1000, 3
    update: ->
      super

      return  if @stopped

      prevSeconds = Math.floor(@timeLeft/1000)
      @timeLeft -= cg.app.dt
      currentSeconds = Math.floor(@timeLeft/1000)

      @ms.string = '.' + pad(@timeLeft - 1000*currentSeconds, 3)
      @ms.updateText()

      if prevSeconds isnt currentSeconds
        @seconds.string = '' + Math.max(0,currentSeconds)
        @seconds.updateText()
        @onTick.dispatch @


  return Timer