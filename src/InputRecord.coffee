define 'InputRecord', [
  'combo/input/Trigger'
], (
  Trigger
) ->

  class InputRecord extends Trigger
    constructor: (@child, @hits=[], @releases=[]) ->
      super
      # @_trigger = @child.trigger
      # @_release = @child.release
      @child.onHit.add =>
        if not @playing
          @trigger()
      @child.onRelease.add =>
        if not @playing
          @release()
      @recording = true
      @playing = false
      @ticks = 0
      # @__input = @input

    rewind: ->
      @ticks = 0
      @lastPressedTime = @child.lastPressedTime = -2
      @lastReleasedTime = @child.lastReleasedTime = -1
    record: ->
      # TODO HACK:
      # @input = @__input
      # @child.input = @__input

      @recording = true
      @playing = false
      @rewind()
      @hits = []
      @releases = []
    play: ->
      # TODO HACK:
      # @input = @child.input =
      #   paused: false

      @recording = false
      @playing = true
      @rewind()
      @hitIndex = 0
      @releaseIndex = 0
    trigger: ->
      # @_trigger.call @child
      super
      if @recording
        @hits.push @ticks
    release: ->
      # @_release.call @child
      super
      if @recording
        @releases.push @ticks
    update: ->
      if @playing
        while @ticks is @hits[@hitIndex]
          @trigger()
          ++@hitIndex
        while @ticks is @releases[@releaseIndex]
          @release()
          ++@releaseIndex
      ++@ticks

  return InputRecord