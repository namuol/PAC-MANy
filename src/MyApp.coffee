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
  'Pac'
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
  Pac
) ->

  SCR_W = 320
  SCR_H = 320
  
  levels = [
    [
      '     # #      # #     '
      ' ##### ######## ##### '
      ' #                  # '
      ' #0                 # '
      ' #                  # '
      '##     1            ##'
      '                      '
      '##    # # ###       ##'
      ' #    # #  #        # '
      ' #    ###  #   2    # '
      ' #    # #  #        # '
      ' #    # # ###       # '
      ' #                  # '
      ' #                  # '
      '##        3         ##'
      '                      '
      '##                  ##'
      ' #                  # '
      ' #                  # '
      ' #                  # '
      ' ##### ######## ##### '
      '     # #      # #     '
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
      allowSfxFailures: true
      layers: [
        'dots'
        'pacs'
        'spawnPoints'
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
        
        @actions.reset.onHit.add =>
          @newGame()

        @stage.setBackgroundColor 0x394f64
        @sheet = TextureGrid.create 'gfx', 13,13

        @map = BitwiseTileMap.create @gfx.tiles, 22,22, 16,16
        @addChild @map, 'walls'

        @layers.pacs.x = @layers.pacs.y = @layers.walls.x = @layers.walls.y = -16
        @loadLevel 0
        @nextPac()
        
      loadLevel: (number) ->
        @layers.pacs.clearChildren()
        @layers.spawnPoints.clearChildren()

        map = levels[number]
        @currentSpawnPoint = 0
        @spawnPoints = []
        for row,y in map
          continue if y >= @map.height
          for tile,x in row
            continue if x >= @map.height
            @map.setSolid x,y, tile is '#'
            switch tile
              when '.'
                1
                # DOT
              when 'o'
                2
                # POWER-PILL
              when '0','1','2','3','4','5','6','7','8','9'
                spawnPoint = new SpawnPoint
                  x: x * 16
                  y: y * 16
                  texture: @sheet[30 + parseInt(tile)]
                  alpha: 0.5
                @spawnPoints[parseInt(tile)] = @addChild spawnPoint

      nextPac: ->
        @pac = new Pac
          x: @spawnPoints[@currentSpawnPoint].x + 24
          y: @spawnPoints[@currentSpawnPoint].y + 24

        @addChild @pac, 'pacs'

        ++@currentSpawnPoint

      update: ->
        super
        ++@ticks

    return _MyApp

  return MyApp