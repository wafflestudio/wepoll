class Bill extends Backbone.Model
	defaults: {

	}
	urlRoot: '/bills'
	# We need to make sure that **_id** is used (MongoDB's unique key)
	idAttribute:"_id"
	initialize: ()->
		this.on "error", (model,error)->
			console.log("Error on bill model (_id:#{model.id})")
	# (validation functionality is to be implemented)
	validate: (attrs)->
		return false

modules.Bill = Bill
