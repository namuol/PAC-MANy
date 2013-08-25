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
) ->

  class Pac extends SpriteActor
    speed: 90
    anchor:
      x: 0.5
      y: 0.5
    constructor: ->
      super
      @anim = cg.app.sheet.anim [0,1,2,3,4,5,4,3,2,1], 17
      @behaviors.push cg.HasPhysics
      @behaviors.push Hotspot.HasHotspots

    init: ->
      @reset()
      super
      @width = 13
      @height = 13
      @bounce = 0

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
      
      @directionQueue = []

    reset: ->
      @going = 'RIGHT'
      @ticks = 0
    canGo: (direction) ->
      return false  if not direction?

      if @going in ['LEFT','RIGHT']
        diff = Math.round(Math.floor(@x/16)*16 + 8) - 0.5 - @x
      else
        diff = Math.round(Math.floor(@y/16)*16 + 8) - 0.5 - @y
      (Math.abs(diff) <= 3) and (not (@hotspots[direction+'_DETECT'].didCollide or @hotspots[direction+'_DETECT2'].didCollide))
    update: ->
      super
      if @x < -8
        @x = cg.app.width + 8
      else if @x > cg.app.width + 8
        @x = -8

      if @y < -8
        @y = cg.app.height + 8
      else if @y > cg.app.height + 8
        @y = -8
      actions = cg.app.actions

      if actions.left.hit()
        @directionQueue.push 'LEFT'
      if actions.right.hit()
        @directionQueue.push 'RIGHT'
      if actions.up.hit()
        @directionQueue.push 'UP'
      if actions.down.hit()
        @directionQueue.push 'DOWN'

      if @wantToGo isnt @going
        if @canGo @wantToGo
          @going = @wantToGo
          @wantToGo = null

      if (not @wantToGo? or (@v.x is 0 and @v.y is 0)) and @directionQueue.length > 0
        [@wantToGo] = @directionQueue.splice 0,1

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
        @v.x *= 1 + 0.5*Math.sin(cg.app.ticks * 0.6)
      else
        # Align to grid vertically:
        tx = Math.ceil(Math.floor(@x/16)*16 + 8) - 0.5
        @x += (tx - @x) * 0.3
        @v.y *= 1 + 0.5*Math.sin(cg.app.ticks * 0.6)



  return Pac