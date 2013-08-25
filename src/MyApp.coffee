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
  'LoadingScreen'
  'TitleScreen'
  'LevelSelectScreen'
  'GameWorld'
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
  LoadingScreen
  TitleScreen
  LevelSelectScreen
  GameWorld
) ->

  SCR_W = 352
  SCR_H = 352

  levels = [
      map: [
        '                      '
        '                      '
        '                      '
        '                      '
        '                      '
        '                      '
        '                      '
        '   ################   '
        '   #0.............#   '
        '   ##############.#   '
        '   #..............#   '
        '   #.##############   '
        '   #..............#   '
        '   ################   '
        '                      '
        '                      '
        '                      '
        '                      '
        '                      '
        '                      '
        '                      '
        '                      '
      ]
    ,
      map: [
        ' # # # # #  # # # # # '
        '##.#.#.#.####.#.#.#.# '
        ' .. . . .    . . . .. '
        '##  . . .    . . .  # '
        ' .... . .    . . .... '
        '##    . .    . .    ##'
        ' ...... .    . ...... '
        '##      .    .      ##'
        ' .......0    1....... '
        '##                  ##'
        ' #                  # '
        ' #                  # '
        '##                  ##'
        ' .......3    2....... '
        '##      .    .      ##'
        ' ...... .    . ...... '
        '##    . .    . .    ##'
        ' .... . .    . . .... '
        '##  . . .    . . .  ##'
        ' .. . . .    . . . .. '
        '##.#.#.#.####.#.#.#.##'
        ' # #.# # #  # # # # # '
      ]
  ]

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
        @levels = levels

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
        @titleScreen.show()

        @levelSelectScreen = @addChild new LevelSelectScreen
          scaleX: 2
          scaleY: 2
          x: @width/2
          y: @height/2
        @levelSelectScreen.hide()

        @world = @addChild new GameWorld
        @world.hide()

        @addChild new SpriteActor
          texture: @gfx.offscreen
          alpha: 0.8

        @sheet = TextureGrid.create 'gfx', 13,13

    return _MyApp

  return MyApp