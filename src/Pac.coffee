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
) ->

  class Pac extends SpriteActor
    speed: 90
    anchor:
      x: 0.5
      y: 0.5
    constructor: ->
      super
      @anims ?= {}
      @anims.normal = cg.app.sheet.anim [0,1,2,3,4,5,4,3,2,1], 17
      @anims.evil = cg.app.sheet.anim [10,11,12,13,14,15,14,13,12,11], 17
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

      @collisionMaps = [cg.app.map]

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


    reset: ->
      @going = 'RIGHT'
      @wantToGo = @startWantToGo
      @x = @startX
      @y = @startY
      @v.x = 0
      @v.y = 0
      @dead = false
      @alpha = 1

    play: ->
      @startWantToGo = @wantToGo
      @actions = {}
      @actions.left = new InputRecord cg.app.actions.left
      @actions.right = new InputRecord cg.app.actions.right
      @actions.up = new InputRecord cg.app.actions.up
      @actions.down = new InputRecord cg.app.actions.down
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
    nom: ->
      @scaleX = @scaleY = 1.5
      t = @tween
        duration: 500
        values:
          scaleX: 1
          scaleY: 1
        easeFunc: Tween.Elastic.Out
      t.start()
    update: ->
      return  unless cg.app.going
      return  if @dead

      super

      map = cg.app.map
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
        # @v.x *= 1 + 0.5*Math.sin(cg.app.ticks * 0.6)
      else
        # Align to grid vertically:
        tx = Math.ceil(Math.floor(@x/16)*16 + 8) - 0.5
        @x += (tx - @x) * 0.3
        # @v.y *= 1 + 0.5*Math.sin(cg.app.ticks * 0.6)

      for pac in cg.app.layers.pacs.children
        continue  if pac is @
        continue  if pac.dead

        if (pac.number < @number) and pac.touches @
          @alpha = 0
          @dead = true
          pac.nom()

      return  if @evil

      for dot in cg.app.layers.dots.children
        continue  if dot.eaten

        if dot.touches @
          dot.getEaten()
          @nom()

  return Pac