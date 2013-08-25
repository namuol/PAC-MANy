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
  'combo/input/MultiTrigger'
  'Pac'
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
  MultiTrigger
  Pac
) ->

  SCR_W = 352
  SCR_H = 352
  

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
      @input.mapKey cg.K_Q, 'back'
      @input.mapKey cg.K_UP, 'up'
      @input.mapKey cg.K_LEFT, 'left'
      @input.mapKey cg.K_DOWN, 'down'
      @input.mapKey cg.K_RIGHT, 'right'
      @actions.any = new MultiTrigger @input
      @actions.any.addTrigger @actions.up
      @actions.any.addTrigger @actions.left
      @actions.any.addTrigger @actions.down
      @actions.any.addTrigger @actions.right

      @actions.reset.onHit.add =>
        @refreshMap()
        @resetLevel()

      @actions.back.onHit.add =>
        @hide =>
          cg.app.levelSelectScreen.show()

      # Editor Keys
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

      @input.onKeyPress.add (charCode) =>
        return true  if not @editing
        switch String.fromCharCode charCode
          when 'w'
            top = @mapData[0]
            @mapData = @mapData.splice(1)
            @mapData.push top
            @refreshMap()
            @resetLevel()
          when 's'
            bottom = @mapData.pop()
            @mapData.splice(0,0,bottom)
            @refreshMap()
            @resetLevel()
        return true

      @map = BitwiseTileMap.create cg.app.gfx.tiles, 22,22, 16,16
      @addChild @map

      # @layers.pacs.x = @layers.pacs.y = @layers.walls.x = @layers.walls.y = -16
      @editing = true

      @onLevelChange = new Signal
      @onLevelChange.add =>
        document.getElementById('levelText').value = @mapData.join('\n')
      
      # @loadLevel 0
      # @resetLevel()

      @alpha = 0
      @tweenIn = @tween
        values:
          alpha: 1
        duration: 250
      
      @tweenIn.onStart.add =>
        @visible = true

      @tweenOut = @tween
        values:
          alpha: 0
        duration: 250
      
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
                texture: cg.app.sheet[30 + parseInt(tile)]
                alpha: 0.5
                number: parseInt(tile)
              @spawnPoints[parseInt(tile)] = @addChild spawnPoint, 'spawnPoints'
      @onLevelChange.dispatch null

    loadLevel: (number) ->
      @mapData = cg.app.levels[number].map
      @refreshMap()
    
    resetLevel: ->
      @nextPacDelay?.stop()
      @currentSpawnPoint = 0
      @going = false
      @nextPac()

    nextPac: ->
      for pac in @layers.pacs.children
        pac.replay()

      spawnPoint = @spawnPoints[@currentSpawnPoint]
      return  if not spawnPoint?

      @canGo = false
      @pac = new Pac
        x: spawnPoint.x + 8 - 0.5
        y: spawnPoint.y + 8 - 0.5
        number: @currentSpawnPoint

      @addChild @pac, 'pacs'

      @going = false
      ++@currentSpawnPoint
      @delay 500, => @canGo = true

    update: ->
      went = false
      if @canGo and (not @going)
        went = true
        if @actions.left.hit()
          @pac.wantToGo = 'LEFT'
        else if @actions.right.hit()
          @pac.wantToGo = 'RIGHT'
        else if @actions.up.hit()
          @pac.wantToGo = 'UP'
        else if @actions.down.hit()
          @pac.wantToGo = 'DOWN'
        else
          went = false
        
      if @canGo and (not @going) and went
        @ticks = 0
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