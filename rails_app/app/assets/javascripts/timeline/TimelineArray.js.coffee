class TimelineArray
  constructor: (@array = [], @options = {})->

    _.extend Backbone.Events
    @compare = @options.compare if @options.compare

  add: (num)->
    @array

  remove: (num)->

  getValue: (num)->

  getNum: (value)->

  sortDesc: ()->

  sortAsc: ()->

  sortBy: ()->

