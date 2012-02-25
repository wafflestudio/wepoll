# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

TimelineEntry = Backbone.Model.extend(
	{
		defaults: {
			deleted:false}
		url: '/timeline_entries'
		idAttribute:"_id"
		initialize: ()->
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
			@model.view = this
			self = this
			# update on change event
			@onChange = ()->
				console.log("changed")
				self.render()

			@model.on "change", @onChange
			# initial render
			@render()
		render: ()->
			if @hasEl
				@setElement($("<div></div>").replaceAll(@el))
			else
				@setElement($("<div></div>").appendTo("#timeline"))
				@hasEl = true
			@$el.load("/timeline_entries/#{@model.id}/edit")
			
			
		clear: ()->
			@model.off "change", @onChange
			delete @model.view
			@$el.remove() if @hasEl
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
				console.log("resetted")
			@collection.on "change", ()->
				console.log("changed")
			@collection.on "add", (entry)->
				view = new TimelineEntryView({model:entry})
				self.views.push(view)
				console.log("added")
			@collection.on "remove", (entry)->
				entry.view.clear() if entry.view
				console.log("removed")
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

		startAutoUpdate: ()->
			self = this
			@timer = setInterval ()->
				self.update()
			, 10000

		stopAutoUpdate: ()->
			clearTimeout(@timer)

		update: ()->
			self = this
			latest = new Date("1800-01-01") # let's assume some time
			updated = new @collection.constructor()

			@collection.each (model)->
				date = new Date(model.get("updated_at"))
				latest = date if latest.getTime() < date.getTime()
			
			updated.fetch({data: $.param({from:latest.toISOString()}), success: ()->
				updated.forEach (entry)->
					target = self.collection.get(entry.id)
					# insertion
					if !target && !entry.get("deleted")
						self.collection.add entry
					# deletion
					else if target && entry.get("deleted")
						self.collection.remove entry
					# update
					else if target
						target.set(entry.attributes)
				})
			

	}
)


modules.TimelineView = TimelineView
