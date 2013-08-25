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

  SCR_W = 352
  SCR_H = 352
  
  levels = [
    [
      '     # #      # #     '
      ' ##### ######## ##### '
      ' #0    #      #    1# '
      ' # #####      ##### # '
      ' # #              # # '
      '## #              # ##'
      '   #              #   '
      '####              ####'
      ' #                  # '
      ' #                  # '
      ' #                  # '
      ' #                  # '
      ' #                  # '
      ' #                  # '
      '####              ####'
      '   #              #   '
      '## #              # ##'
      ' # #              # # '
      ' # #####      ##### # '
      ' #3    #      #    2# '
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

        @stage.setBackgroundColor 0x394f64
        @sheet = TextureGrid.create 'gfx', 13,13

        @map = BitwiseTileMap.create @gfx.tiles, 22,22, 16,16
        @addChild @map, 'walls'

        # @layers.pacs.x = @layers.pacs.y = @layers.walls.x = @layers.walls.y = -16

        @onLevelChange = new Signal
        @onLevelChange.add =>
          $('textarea').html @mapData.join('\n')

        @loadLevel 0
        @nextPac()
        @editing = true
      
      refreshMap: ->
        @layers.pacs.clearChildren()
        @layers.spawnPoints.clearChildren()

        @currentSpawnPoint = 0
        @spawnPoints = []
        for row,y in @mapData
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
                  number: parseInt(tile)
                @spawnPoints[parseInt(tile)] = @addChild spawnPoint, 'spawnPoints'
        @onLevelChange.dispatch null

      loadLevel: (number) ->
        @mapData = levels[number]

        @refreshMap()

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
        @delay 3000, => @canGo = true

      update: ->
        if @canGo and (not @going) and @actions.any.hit()
          @ticks = 0
          @pac.play()
          @going = true
          @delay 10000, =>
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
            cg.log "prev (#{x},#{y}) : '#{current}'"
            cg.log "now  (#{x},#{y}) : '#{ch}'"
            @mapData[y] = @mapData[y].substr(0,x) + ch + @mapData[y].substr(x+1)
            cg.log @mapData.join('\n')
            @refreshMap()

        super


        return  if not @going

        ++@ticks

    return _MyApp

  return MyApp