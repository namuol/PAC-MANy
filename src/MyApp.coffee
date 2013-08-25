define 'MyApp', [
  'combo/cg'
  'combo/util'
  'combo/Actor'
  'combo/SpriteActor'
  'combo/modules/ui'
  'combo/TextureGrid'
  'Coffixi/primitives/Graphics'
  'combo/util/Signal'
  'combo/Tween'
  'combo/tile/BitwiseTileMap'
  'combo/text/BitmapFont'
  'Pac'
  'LoadingScreen'
  'TitleScreen'
], (
  cg
  util
  Actor
  SpriteActor
  ui
  TextureGrid
  Graphics
  Signal
  Tween
  BitwiseTileMap
  BitmapFont
  Pac
  LoadingScreen
  TitleScreen
) ->

  SCR_W = 352
  SCR_H = 352
  
  MyApp = (App) ->
    class _MyApp extends App
      displayMode: 'pixel'
      width: SCR_W
      height: SCR_H
      resizeFilter: 'nearest'
      textureFilter: 'nearest'
      gfx:
        gfx: 'assets/gfx.png'
        tiles: 'assets/tiles.png'
        offscreen: 'assets/offscreen.png'
        title: 'assets/title.png'
      allowSfxFailures: true
      constructor: ->
        super
        @onPostPreload = new Signal

      run: ->
        @assets.loadTexture('assets/font.png').then((fontTexture) =>
          @assets.font = fontTexture
          @font = new BitmapFont fontTexture

          @init()
          
          @loadingScreen = @addChild new LoadingScreen
          @loadingScreen.onHide.addOnce =>
            @onPostPreload.dispatch @
          @loadingScreen.show()

          @preload
            error: (src) =>
              cg.error 'Failed to load asset ' + src
            progress: (src, asset, number, count) =>
              cg.log 'Loaded asset ' + src
              @loadingScreen.setText Math.round(number/count*100) + '%'
              @lastCall = Date.now()
              @update()
              @draw()
            complete: =>
              @postInit()
              @lastCall = Date.now()
              @mainLoop()
              @loadingScreen.hide()
        ).then null, (err) ->
          cg.error 'FONT LOAD ERROR: ' + err
          throw new Error 'Could not load font.png ... aborting!!!'
      init: ->
        super
        @stage.setBackgroundColor 0x394f64
      postInit: ->

        @titleScreen = @addChild new TitleScreen
          x: @width/2
        @titleScreen.y = 0
        @titleScreen.show()

        @addChild new SpriteActor
          texture: @gfx.offscreen
          alpha: 0.5
    return _MyApp

  return MyApp