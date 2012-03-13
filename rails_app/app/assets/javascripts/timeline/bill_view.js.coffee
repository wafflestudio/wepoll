class BillView extends Backbone.View
	initialize: ()->
		@model = if @options.model then @options.model else new Law()
		@render()
	
	render: ()->
		el = $("<div class='tm-bill-view'>#{@model.get('title')}</div>")
		@setElement(el)

	appendTo: ($target)->
		@$el.appendTo($target)
	
modules.BillView = BillView
