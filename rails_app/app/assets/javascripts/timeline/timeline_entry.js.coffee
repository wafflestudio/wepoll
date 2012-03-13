class TimelineEntry extends Backbone.Model
	defaults: {
		like_count:0
		blame_count:0
		# The **deleted** field is used to indicate delete synchronization between clients. Server will _hopefully_ destroy the mongodb document after some time.
		deleted:false
	}
	urlRoot: '/timeline_entries'
	# We need to make sure that **_id** is used (MongoDB's unique key)
	idAttribute:"_id"
	initialize: ()->
		this.on "error", (model,error)->
			console.log("Error on model (_id:#{model.id})")
	# (validation functionality is to be implemented)
	validate: (attrs)->
		return false

modules.TimelineEntry = TimelineEntry
