Bill = modules.Bill


class BillCollection extends Backbone.Collection
	model:Bill
	url: '/bills'
	fetch:(options)->
		options = if options then options else {}
		options.complete = true
		options.for_timeline = true
		super({data:$.param(options)})

modules.BillCollection = BillCollection
