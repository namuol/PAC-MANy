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
  'Timer'
  'combo/text/TextString'
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
  Timer
  TextString
) ->

  class ScoreText extends TextString
    init: ->
      super
      @alpha = 0
      t1 = @tween
        values:
          alpha: 1
          y: @y-24
        easeFunc: Tween.Quadratic.Out
        duration: 250
      t2 = @tween
        values:
          y: @y-16
        easeFunc: Tween.Bounce.Out
        duration: 250
      t3 = @tween
        values:
          y: @y-45
          alpha: 0
        delay: 500
        duration: 250
        easeFunc: Tween.Quadratic.Out
      t1.onComplete.add => t2.start()
      t2.onComplete.add => t3.start()
      t3.onComplete.add => @visible = false
      t1.start()

  class SpawnPoint extends SpriteActor

  class Dot extends SpriteActor
    constructor: ->
      super
      @anims ?= {}
      if @power
        @anims.idle = cg.app.sheet.anim [22]
        @anims.eaten = cg.app.sheet.anim [23]
      else
        @anims.idle = cg.app.sheet.anim [20]
        @anims.eaten = cg.app.sheet.anim [21]
      @width = 13
      @height = 13
      @hitBox =
        x: 6
        y: 6
        width: 1
        height: 1
      @reset()
    reset: ->
      @eaten = false
      @anim = @anims.idle
    getEaten: ->
      @eaten = true
      @anim = @anims.eaten

  class GameWorld extends Scene
    layers: [
      'dots'
      'spawnPoints'
      'walls'
      'pacs'
      'offscreen'
      'scoreText'
      'timer'
    ]
    ticks: 0
    init: ->
      super

      @input.mapKey cg.K_R, 'reset'
      @input.mapKey cg.K_Q, 'pause'
      @input.mapKey cg.K_UP, 'up'
      @input.mapKey cg.K_LEFT, 'left'
      @input.mapKey cg.K_DOWN, 'down'
      @input.mapKey cg.K_RIGHT, 'right'
      @input.mapKey cg.K_SHIFT, 'speedUp'
      @actions.any = new MultiTrigger @input
      @actions.any.addTrigger @actions.up
      @actions.any.addTrigger @actions.left
      @actions.any.addTrigger @actions.down
      @actions.any.addTrigger @actions.right

      @actions.speedUp.onHit.add =>
        @speedUpTween = @tween
          values:
            timeScale: 4
          duration: 1000
          easeFunc: Tween.Linear
        cg.app.timeScale = 3

      @actions.speedUp.onRelease.add =>
        @speedUpTween.stop()
        cg.app.timeScale = 1

      @actions.reset.onHit.add =>
        @refreshMap()
        @resetLevel()

      @actions.pause.onHit.add =>
        @pause()
        cg.app.delay 0, =>
          cg.app.pauseScreen.show()

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
          when 'a'
            for row,i in @mapData
              left = row[0]
              @mapData[i] = row.substr(1) + left
            @refreshMap()
            @resetLevel()
          when 'd'
            for row,i in @mapData
              right = row[row.length - 1]
              @mapData[i] = right + row.substr(0, row.length - 1)
            @refreshMap()
            @resetLevel()
        return true

      @timer = @addChild new Timer, 'timer'
      @timer.onDrain.add => @nextPac()

      @map = BitwiseTileMap.create cg.app.gfx.tiles, 22,22, 16,16
      @addChild @map, 'walls'

      @offscreen = new SpriteActor
        texture: 'offscreen'
      @addChild @offscreen, 'offscreen'

      # @layers.pacs.x = @layers.pacs.y = @layers.walls.x = @layers.walls.y = -16
      @editing = false

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
      
      @tweenIn.onComplete.add =>
        cg.app.offscreen?.visible = false

      @tweenOut = @tween
        values:
          alpha: 0
        duration: 250
      
      @tweenOut.onComplete.add =>
        @visible = false
        return

    hide: (cb) ->
      cg.app.offscreen?.visible = true
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
      @layers.scoreText.clearChildren()

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
              powerPill = new Dot
                x: x * 16 + 1
                y: y * 16 + 1
                power: true
              @addChild powerPill, 'dots'
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
      @levelNumber = number
      @level = cg.app.levels[number]
      @mapData = cg.app.levels[number].map
      @refreshMap()
      if @level.center
        @offscreen.x = -8
        @offscreen.y = -8
        @x = @y = 8
      else
        @offscreen.x = 0
        @offscreen.y = 0
        @x = @y = 0
    pacCount: ->
      c = 0
      for pac in @layers.pacs.children
        ++c  unless pac.dead
    resetLevel: ->
      @currentSpawnPoint = 0
      @going = false
      @dotCount = 0
      for dot in @layers.dots.children
        ++@dotCount unless (dot.eaten and dot.power)
      @timer.stop()
      @timer.timeLeft = 10 * 1000
      @timer.resetBonus()
      @timeSplit = -1
      @nextPac()

    endGame: (forceFail=false) ->
      cg.app.timeScale = 1
      @pause()
      if forceFail
        @dotCount = 999
      cg.app.resultScreen.show()
    nextPac: ->
      spawnPoint = @spawnPoints[@currentSpawnPoint]
      if not spawnPoint?
        @endGame()
        return

      for pac in @layers.pacs.children
        pac.replay()
      @dotCount = 0
      for dot in @layers.dots.children
        if not (dot.power and dot.eaten)
          ++@dotCount
          dot.reset()
      @canGo = false
      @pac = new Pac
        x: spawnPoint.x + 8 - 0.5
        y: spawnPoint.y + 8 - 0.5
        number: @currentSpawnPoint

      @addChild @pac, 'pacs'

      @going = false
      ++@currentSpawnPoint
      @delay 500, => @canGo = true
    addTimerBonus: (amt) ->
      scoreText = new ScoreText cg.app.font, '' + amt,
        alignment: 'center'
      scoreText.x = @pac.x
      scoreText.y = @pac.y
      @addChild scoreText, 'scoreText'
      @timer.addBonus(amt)
      if @timeSplit >= 0
        @timeSplit += amt
    eatDot: -> 
      if --@dotCount <= 0
        if @currentSpawnPoint > @spawnPoints.length - 2
          @timeSplit = @timer.timeLeft
          scoreText = new ScoreText cg.app.font, @timer.timeString(),
            alignment: 'center'
          scoreText.x = @pac.x
          scoreText.y = @pac.y
          scoreText.scaleX = scoreText.scaleY = 2
          @addChild scoreText, 'scoreText'
          @split = @timer.timeString()
      @dotCount

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
        @timer.restart()

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