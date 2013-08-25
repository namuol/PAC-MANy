define 'MyApp', [
  'combo/cg'
  'combo/util'
  'combo/Actor'
  'combo/SpriteActor'
  'combo/modules/ui'
  'combo/TextureGrid'
  'Coffixi/primitives/Graphics'
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
  Tween
  BitwiseTileMap
  Pac
) ->
  SCR_W = 320
  SCR_H = 320
  
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

        @stage.setBackgroundColor 0x222222
        @sheet = TextureGrid.create 'gfx', 13,13

        @map = BitwiseTileMap.create @gfx.tiles, 20,20, 16,16
        for x in [0...20]
          for y in [0...20]
            if Math.random() > 0.8
              @map.setSolid x,y, true
        @addChild @map, 'walls'

        @addChild new Pac, 'pacs'

      update: ->
        super
        ++@ticks

    return _MyApp

  return MyApp