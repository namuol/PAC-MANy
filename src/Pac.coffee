define 'Pac', [
  'combo/cg'
  'combo/util'
  'combo/Actor'
  'combo/SpriteActor'
  'combo/modules/ui'
  'combo/TextureGrid'
  'Coffixi/primitives/Graphics'
  'combo/Tween'
  'combo/tile/Hotspot'
  'InputRecord'
  'combo/text/TextString'
], (
  cg
  util
  Actor
  SpriteActor
  ui
  TextureGrid
  Graphics
  Tween
  Hotspot
  InputRecord
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
      t1.onComplete.add => t2.start()
      t1.start()

  DEFAULT_SPEED = 90
  POWERFUL_SPEED = 90

  class Pac extends SpriteActor
    anchor:
      x: 0.5
      y: 0.5
    constructor: ->
      super
      @speed = DEFAULT_SPEED
      @anims ?= {}
      @anims.normal = cg.app.sheet.anim [0,1,2,3,4,5,4,3,2,1], 17
      @anims.blink = cg.app.sheet.anim [50,51,52,53,54,55,54,53,52,51], 17, false

      @anims.evil = cg.app.sheet.anim [10,11,12,13,14,15,14,13,12,11], 17
      @anims.edible = cg.app.sheet.anim [40,41,42,43,44,45,44,43,42,41], 17
      @anims.powerful = cg.app.sheet.anim [60,61,62,63,64,65,64,63,62,61], 17

      @anim = @anims.normal
      @behaviors.push cg.HasPhysics
      @behaviors.push Hotspot.HasHotspots
      @startX = @x
      @startY = @y

      @width = 13
      @height = 13
      @bounce = 0

      @hitBox =
        x: -2.5
        y: -2.5
        width: 5
        height: 5
    init: ->
      super

      @reset()

      @collisionMaps = [cg.app.world.map]

      LEFT = @width * 0.1
      RIGHT = @width * 0.9
      TOP = @height * 0.1
      BOTTOM = @height * 0.9
      PADDING = 2

      @hotspots.UP = new Hotspot.Top @, {x:LEFT,y:0}
      @hotspots.UP2 = new Hotspot.Top @, {x:RIGHT,y:0}
      @hotspots.UP_DETECT = new Hotspot.Top @, {x:LEFT,y:-PADDING}, false
      @hotspots.UP_DETECT2 = new Hotspot.Top @, {x:RIGHT,y:-PADDING}, false
      
      @hotspots.DOWN = new Hotspot.Bottom @, {x:LEFT,y:@height}
      @hotspots.DOWN2 = new Hotspot.Bottom @, {x:RIGHT,y:@height}
      @hotspots.DOWN_DETECT = new Hotspot.Bottom @, {x:LEFT,y:@height+PADDING}, false
      @hotspots.DOWN_DETECT2 = new Hotspot.Bottom @, {x:RIGHT,y:@height+PADDING}, false
      
      @hotspots.LEFT = new Hotspot.Left @, {y:TOP,x:0}
      @hotspots.LEFT2 = new Hotspot.Left @, {y:BOTTOM,x:0}
      @hotspots.LEFT_DETECT = new Hotspot.Left @, {y:TOP,x:-PADDING}, false
      @hotspots.LEFT_DETECT2 = new Hotspot.Left @, {y:BOTTOM,x:-PADDING}, false

      @hotspots.RIGHT = new Hotspot.Right @, {y:TOP,x:@width}
      @hotspots.RIGHT2 = new Hotspot.Right @, {y:BOTTOM,x:@width}
      @hotspots.RIGHT_DETECT = new Hotspot.Right @, {y:TOP,x:@width+PADDING}, false
      @hotspots.RIGHT_DETECT2 = new Hotspot.Right @, {y:BOTTOM,x:@width+PADDING}, false

      blink = =>
        return  if @evil or @powerful
        @anim = @anims.normal
        @delay util.range(1000, 4000), =>
          return  if @evil or @powerful
          @anim = @anims.blink
          @anim.rewind()
      @anims.blink.onComplete.add blink
      blink()

    reset: ->
      @going = 'RIGHT'
      @wantToGo = @startWantToGo
      @x = @startX
      @y = @startY
      @v.x = 0
      @v.y = 0
      @dead = false
      @alpha = 1
      @visible = true
      @powerful = false
      @speed = DEFAULT_SPEED

    play: ->
      @startWantToGo = @wantToGo
      @actions = {}
      @actions.left = new InputRecord cg.app.world.actions.left
      @actions.right = new InputRecord cg.app.world.actions.right
      @actions.up = new InputRecord cg.app.world.actions.up
      @actions.down = new InputRecord cg.app.world.actions.down
      for own k,a of @actions
        a.record()

    replay: ->
      @anim = @anims.evil
      @texture = @anim.getFrame(0)
      @reset()
      @evil = true
      for own k,a of @actions
        a.play()

    canGo: (direction) ->
      return false  if not direction?

      if @going in ['LEFT','RIGHT']
        diff = Math.round(Math.floor(@x/16)*16 + 8) - 0.5 - @x
      else
        diff = Math.round(Math.floor(@y/16)*16 + 8) - 0.5 - @y
      (Math.abs(diff) <= 3) and (not (@hotspots[direction+'_DETECT'].didCollide or @hotspots[direction+'_DETECT2'].didCollide))
    nom: (scale=1.5, duration=500) ->
      @scaleX = @scaleY = scale
      t = @tween
        duration: duration
        values:
          scaleX: 1
          scaleY: 1
        easeFunc: Tween.Elastic.Out
      t.start()
    
    makePowerful: ->
      if not @evil
        scoreText = new ScoreText cg.app.font, '1.0',
          alignment: 'center'
        scoreText.x = @x
        scoreText.y = @y
        cg.app.world.addChild scoreText, 'scoreText'
        cg.app.world.timer.addBonus(1000)
        @anim = @anims.powerful
      @powerful = true

    canEat: (other) ->
      if @powerful
        if other.powerful
          return @number < other.number
        else
          return true
      else
        if other.powerful
          return false
        else
          return @number > other.number

    update: ->
      return  unless cg.app.world.going
      return  if @dead

      super

      map = cg.app.world.map
      if @x < 0
        @x = map.mapWidth*map.tileWidth
      else if @x > map.mapWidth*map.tileWidth
        @x = 0

      if @y < 0
        @y = map.mapHeight*map.tileHeight
      else if @y > map.mapHeight*map.tileHeight
        @y = 0
      
      for own k,a of @actions
        a.update()

      if @actions.left.hit()
        @wantToGo = 'LEFT'
      if @actions.right.hit()
        @wantToGo = 'RIGHT'
      if @actions.up.hit()
        @wantToGo = 'UP'
      if @actions.down.hit()
        @wantToGo = 'DOWN'

      if @wantToGo isnt @going
        if @canGo @wantToGo
          @going = @wantToGo
          @wantToGo = null

      @v.x = @v.y = 0
      switch @going
        when 'LEFT'
          @v.x = -@speed
          @rotation = -Math.PI
        when 'RIGHT'
          @v.x = @speed
          @rotation = 0
        when 'UP'
          @v.y = -@speed
          @rotation = -Math.PI/2
        when 'DOWN'
          @v.y = @speed
          @rotation = Math.PI/2

      if true in (@hotspots[name].didCollide for name in [@going+'_DETECT', @going+'_DETECT2'])
        if @going in ['LEFT','RIGHT']
          @v.x = 0
        else
          @v.y = 0

      if (@v.x isnt 0) or (@v.y isnt 0)
        @anim.resume()
      else
        @anim.pause()

      if @going in ['LEFT','RIGHT']
        # Align to grid horizontally:
        ty = Math.ceil(Math.floor(@y/16)*16 + 8) - 0.5
        @y += (ty - @y) * 0.3
        # @v.x *= 1 + 0.5*Math.sin(cg.app.world.ticks * 0.6)
      else
        # Align to grid vertically:
        tx = Math.ceil(Math.floor(@x/16)*16 + 8) - 0.5
        @x += (tx - @x) * 0.3
        # @v.y *= 1 + 0.5*Math.sin(cg.app.world.ticks * 0.6)

      for pac in cg.app.world.layers.pacs.children
        continue  if pac is @
        continue  if pac.dead

        if @canEat(pac) and @touches(pac)
          @nom 3, 700
          pac.visible = false
          pac.dead = true

      for dot in cg.app.world.layers.dots.children
        continue  if dot.eaten

        if dot.touches @
          dot.getEaten()
          if --cg.app.world.dotCount <= 0
            scoreText = new ScoreText cg.app.font, cg.app.world.timer.timeString(),
              alignment: 'center'
            scoreText.x = @x
            scoreText.y = @y
            cg.app.world.addChild scoreText, 'scoreText'
            cg.app.world.split = cg.app.world.timer.timeString()
            @nom 4, 900
          else
            @nom()

          if dot.power
            @makePowerful()

  return Pac