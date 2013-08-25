define 'MenuItem', [
  'combo/cg'
  'combo/Actor'
  'combo/util/Signal'
], (
  cg
  Actor
  Signal
) ->

  class MenuItem extends Actor
    constructor: ->
      super

      @focused ?= false
      @onFocus = new Signal
      @onBlur = new Signal
      @onSelect = new Signal

    focus: ->
      @onFocus.dispatch @
      @focused = true

    blur: ->
      @onBlur.dispatch @
      @focused = false

    select: ->
      @onSelect.dispatch @
