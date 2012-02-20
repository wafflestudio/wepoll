# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

TimelineEntry = Backbone.Model.extend(
	{
		defaults: {
			deleted:false}
		url: '/timeline_entries'
		initialize: ()->
			#this.on("change")
			this.on "error", (model,error)->

				
		validate: ( attrs )->
			

	}
)

Timeline = Backbone.Collection.extend(
	{
		model:TimelineEntry
		url: '/timeline_entries'
	}
)


TimelineEntryView = Backbone.View.extend(
	{
		initialize: ()->
			@model = if @options.model then @options.model else new TimelineEntry()
			self = this
			# update on change event
			@onChange = ()->
				self.clear()
				self.render()

			@model.on "change", @onChange
			# initial render
			@render()
		render: ()->
			console.log("model" + this.model.toJSON())
		clear: ()->
			@model.off "change", @onChange
	}
)

TimelineView = Backbone.View.extend(
	{
		initialize: ()->
			# optional collection param
			@collection = if @options.collection then @options.collection else new Timeline()
			@views = []
			# bind events
			self = this
			@collection.on "reset", ()->
				self.clear()
				self.render()
			# fetch initial collection
			@collection.fetch()
	
		render: ()->
			self = this
			@collection.each (model)->
				view = new TimelineEntryView({model:model})
				self.views.push(view)

		clear: ()->
			for view in @views
				view.clear()
			@views = []
			console.log('cleared')

		update: ()->
			latest = new Date("1800-01-01")
			@collection.each (model)->
				date = new Date(model.get("updated_at"))
				latest = date if latest.getTime() < date.getTime()
			@collection.fetch({data: $.param({from:latest.toISOString()}),add:true})

	}
)


modules.TimelineView = TimelineView
