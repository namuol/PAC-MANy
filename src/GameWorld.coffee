define 'GameWorld', [
  'combo/cg'
  'combo/util'
  'combo/Scene'
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
  Scene
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
  
  levels = [
    [
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '   ################   '
      '   #0.............#   '
      '   ################   '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
      '                      '
    ]

    [
      '     # #      # #     '
      ' #####.########.##### '
      ' #    .        .    # '
      ' #    .        .    # '
      ' #    .        .    # '
      '##    .        .    ##'
      ' ......        ...... '
      '##                  ##'
      ' #                  # '
      ' #                  # '
      ' #                  # '
      ' #                  # '
      ' #                  # '
      ' #                  # '
      '##                  ##'
      ' ......        ...... '
      '##    .        .    ##'
      ' #    .        .    # '
      ' #    .        .    # '
      ' #    .        .    # '
      ' #####.########.##### '
      '     # #      # #     '
    ]
  ]

  class SpawnPoint extends SpriteActor

  class Dot extends SpriteActor

    constructor: ->
      super
      @anims ?= {}
      @anim = @anims.idle = cg.app.sheet.anim [20]
      @anims.eaten = cg.app.sheet.anim [21]
      @width = 13
      @height = 13
      @hitBox =
        x: 6
        y: 6
        width: 1
        height: 1
    getEaten: ->
      @eaten = true
      @anim = @anims.eaten

  class GameWorld extends Scene
    layers: [
      'dots'
      'spawnPoints'
      'pacs'
      'walls'
    ]
    ticks: 0
    init: ->
      super

      @input.mapKey cg.K_R, 'reset'
      @input.mapKey cg.K_UP, 'up'
      @input.mapKey cg.K_LEFT, 'left'
      @input.mapKey cg.K_DOWN, 'down'
      @input.mapKey cg.K_RIGHT, 'right'
      @input.mapKey [cg.K_UP, cg.K_LEFT, cg.K_DOWN, cg.K_RIGHT], 'any'

      @input.mapKey cg.K_0, '_0'
      @input.mapKey cg.K_1, '_1'
      @input.mapKey cg.K_2, '_2'
      @input.mapKey cg.K_3, '_3'
      @input.mapKey cg.K_4, '_4'
      @input.mapKey cg.K_5, '_5'
      @input.mapKey cg.K_6, '_6'
      @input.mapKey cg.K_7, '_7'
      @input.mapKey cg.K_8, '_8'
      @input.mapKey cg.K_9, '_9'

      @sheet = TextureGrid.create 'gfx', 13,13

      @map = BitwiseTileMap.create @gfx.tiles, 22,22, 16,16
      @addChild @map, 'walls'

      # @layers.pacs.x = @layers.pacs.y = @layers.walls.x = @layers.walls.y = -16
      @editing = true

      @onLevelChange = new Signal
      @onLevelChange.add =>
        $('textarea').html @mapData.join('\n')
      
      @titleScreen = @addChild new TitleScreen
        x: @width - 25
        scaleX: 4
        scaleY: 4
      @titleScreen.y = @height - (@titleScreen.scaleY * @titleScreen.height) - 25
      @titleScreen.hide()

      @loadLevel 0
      @resetLevel()
    
    refreshMap: ->
      @layers.pacs.clearChildren()
      @layers.spawnPoints.clearChildren()
      @layers.dots.clearChildren()

      @spawnPoints = []
      for row,y in @mapData
        continue if y >= @map.height
        for tile,x in row
          continue if x >= @map.height
          @map.setSolid x,y, tile is '#'
          switch tile
            when '.'
              dot = new Dot
                x: x * 16 + 1
                y: y * 16 + 1
              @addChild dot, 'dots'
            when 'o'
              2
            when '0','1','2','3','4','5','6','7','8','9'
              spawnPoint = new SpawnPoint
                x: x * 16
                y: y * 16
                texture: @sheet[30 + parseInt(tile)]
                alpha: 0.5
                number: parseInt(tile)
              @spawnPoints[parseInt(tile)] = @addChild spawnPoint, 'spawnPoints'
      @onLevelChange.dispatch null

    loadLevel: (number) ->
      @mapData = levels[number]

      @refreshMap()
    
    resetLevel: ->
      @currentSpawnPoint = 0
      @going = false
      @nextPac()

    nextPac: ->
      for pac in @layers.pacs.children
        pac.replay()

      return  if @currentSpawnPoint >= @spawnPoints.length

      @canGo = false

      @pac = new Pac
        x: @spawnPoints[@currentSpawnPoint].x + 8 - 0.5
        y: @spawnPoints[@currentSpawnPoint].y + 8 - 0.5
        number: @currentSpawnPoint

      @addChild @pac, 'pacs'

      @going = false
      ++@currentSpawnPoint
      @delay 500, => @canGo = true

    update: ->
      if @canGo and (not @going) and @actions.any.hit()
        @ticks = 0
        if @actions.left.hit()
          @pac.wantToGo = 'LEFT'
        if @actions.right.hit()
          @pac.wantToGo = 'RIGHT'
        if @actions.up.hit()
          @pac.wantToGo = 'UP'
        if @actions.down.hit()
          @pac.wantToGo = 'DOWN'
        @pac.play()
        @going = true
        @nextPacDelay?.stop()
        @nextPacDelay = @delay 10000, =>
          @nextPac()

      if @editing
        {x: x, y: y} = @map.tileCoordsAt @input.mouse.x, @input.mouse.y
        x = util.clamp x, 0, @map.mapWidth-1
        y = util.clamp y, 0, @map.mapHeight-1
        current = @mapData[y][x]

        ch = null
        if @actions.LMB.hit()
          if current isnt ' '
            ch = ' '
            @editorErasing = true
          else
            ch = '#'
            @editorErasing = false

        if @actions.LMB.held()
          if @editorErasing
            ch = ' '
          else
            ch = '#'
        ch = '.' if @actions.RMB.held()
        ch = 'o' if @actions.MMB.hit()
        ch = '0' if @actions._0.hit()
        ch = '1' if @actions._1.hit()
        ch = '2' if @actions._2.hit()
        ch = '3' if @actions._3.hit()
        ch = '4' if @actions._4.hit()
        ch = '5' if @actions._5.hit()
        ch = '6' if @actions._6.hit()
        ch = '7' if @actions._7.hit()
        ch = '8' if @actions._8.hit()
        ch = '9' if @actions._9.hit()

        if ch?
          @mapData[y] = @mapData[y].substr(0,x) + ch + @mapData[y].substr(x+1)
          @refreshMap()
          @resetLevel()

      super

      return  if not @going

      ++@ticks

  return GameWorld