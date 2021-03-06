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
  'PauseScreen'
  'ResultScreen'
  'OptionScreen'
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
  PauseScreen
  ResultScreen
  OptionScreen
) ->

  SCR_W = 352
  SCR_H = 352

  levels = [
      excellent: 2400
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
      excellent: 7400
      center: true
      map: [
        '                      '
        '                      '
        '                      '
        '                      '
        '                      '
        '    ############      '
        '    #0.........#      '
        '    ##########.#      '
        '     #.......#.#      '
        '     #.#####.#.#      '
        '     #.#..o..#.#      '
        '     #.#.#####.#      '
        '     #.#.......#      '
        '     #.##########     '
        '     #.........1#     '
        '     ############     '
        '                      '
        '                      '
        '                      '
        '                      '
        '                      '
      ]
    ,
      excellent: 1000
      map: [
        ' # # # # #  # # # # # '
        '##.#.#.#.####.#.#.#.##'
        ' .3 . . .    . . . .. '
        '##  . . .    . . .  ##'
        ' ...2 . .    . . .... '
        '##    . .    . .    ##'
        ' .....1 .    . ...... '
        '##      .    .      ##'
        ' .......0    ........ '
        '##                  ##'
        ' #                  # '
        ' #                  # '
        '##                  ##'
        ' ........    ........ '
        '##      .    .      ##'
        ' ...... .    . ...... '
        '##    . .    . .    ##'
        ' .... . .    . . .... '
        '##  . . .    . . .  ##'
        ' .. . . .    . . . .. '
        '##.#.#.#.####.#.#.#.##'
        ' # # # # #  # # # # # '
      ]
    ,
      excellent: 7300
      center: true
      map: [
        '                      '
        '                ###   '
        ' ################1#   '
        ' #0.............#.#   '
        ' ##############.#.#   '
        '  #...........o.#.#   '
        '  #.#o#######.#.#.#   '
        '  #.#.........#.#.#   '
        '  #.#.#.##.##.#.#.#   '
        '  #.#.#.#...#.#.#.#   '
        '  #.#.#...4...#.#.#   '
        '  #.#.#.#...#.#.#.#   '
        '  #.#.#.##.##.#.#.#   '
        '  #.#.#.........#.#   '
        '  #.#.#.#######o#.#   '
        '  #.#.o...........#   '
        '  #.#.##############  '
        '  #.#.............2#  '
        '  #3################  '
        '  ###                 '
        '                      '
        '                      '
      ]
  ]

  MyApp = (App) ->
    class _MyApp extends App
      displayMode: 'pixel'
      width: SCR_W
      height: SCR_H
      resizeFilter: 'nearest'
      textureFilter: 'nearest'
      sfx:
        badnom: ['assets/badnom.ogg', 'assets/badnom.mp3', 'assets/badnom.m4a']
        bignom: ['assets/bignom.ogg', 'assets/bignom.mp3', 'assets/bignom.m4a']
        evilnom: ['assets/evilnom.ogg', 'assets/evilnom.mp3', 'assets/evilnom.m4a']
        nom: ['assets/nom.ogg', 'assets/nom.mp3', 'assets/nom.m4a']
        powerup: ['assets/powerup.ogg', 'assets/powerup.mp3', 'assets/powerup.m4a']
        yay: ['assets/yay.ogg', 'assets/yay.mp3', 'assets/yay.m4a']
      gfx:
        gfx: 'assets/gfx.png'
        tiles: 'assets/tiles.png'
        offscreen: 'assets/offscreen.png'
        title: 'assets/title.png'
        black: 'assets/black.png'
        excellent: 'assets/excellent.png'
        clear: 'assets/clear.png'
        fail: 'assets/fail.png'
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
        @sheet = TextureGrid.create 'gfx', 13,13

        @titleScreen = @addChild new TitleScreen
          x: @width/2
        @titleScreen.show()

        @levelSelect = @addChild new LevelSelectScreen
          scaleX: 2
          scaleY: 2
          x: @width/2
          y: @height/2
        @levelSelect.hide()

        @world = @addChild new GameWorld
        @world.hide()
        
        @pauseScreen = @addChild new PauseScreen
          x: @width/2
          y: @height/2 - 0.5
          scaleX: 4
          scaleY: 4

        @resultScreen = @addChild new ResultScreen
          x: @width / 2
          y: @height / 2 - 0.5

        @optionScreen = @addChild new OptionScreen
          x: @width / 2
          y: @height / 2 - 0.5
          scaleX: 4
          scaleY: 4
        @optionScreen.hide()

        @offscreen = @addChild new SpriteActor
          texture: "offscreen"

    return _MyApp

  return MyApp