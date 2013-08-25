define 'LoadingScreen', [
  'combo/cg'
  'combo/Scene'
  'combo/Tween'
  'combo/util/Signal'
  'combo/text/TextString'
], (
  cg
  Scene
  Tween
  Signal
  TextString
) ->
  class LoadingScreen extends Scene
   constructor: ->
      super
      @onHide = new Signal

    init: ->
      super
      app = cg.app

      @text = @addChild new TextString app.font, '0%',
        alignment: 'center'
        x: Math.round app.width/2
        y: Math.round app.height/2
        scaleX: 2
        scaleY: 2
      
      @alpha = 1
      @visible = false

      @tweenIn = @tween
        values:
          alpha: 1
        duration: 250

      @tweenOut = @tween
        values:
          alpha: 0
        duration: 250
      
      @tweenIn.onStart.add =>
        @visible = true
       
      @tweenOut.onComplete.add =>
        @visible = false
        @onHide.dispatch @

      @tweenIn.start()

    hide: (cb) ->
      @pause()
      @tweenOut.onComplete.addOnce cb  if cb?
      @tweenOut.start()

    show: (cb) ->
      @resume()
      @tweenIn.onComplete.addOnce cb  if cb?
      @tweenIn.start()

    setText: (text) ->
      @text.string = text
      @text.updateText()

  return LoadingScreen