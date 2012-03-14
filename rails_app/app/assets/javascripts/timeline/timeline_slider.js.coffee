TimelineEntryNav = modules.TimelineEntryNav


class TimelineEntrySlider extends Backbone.View
	initialize:(options)->
		@$el = $("<div class='tm-slider'></div>").data('slider', this)
		@$holder = $("<div class='tm-sl-holder'></div>").appendTo(@$el)
		@$el.corner()
		@nav = new TimelineEntryNav({current:0,num:0})
		@nav.appendTo(@$holder)
		@nav.on "changePage", @showPage
		@pos = options.pos
		@vpos = options.vpos
		
		if @vpos == 0
			@$el.addClass("tm-bubble#{parseInt(Math.random()*3)+1}")
		else if @vpos ==1
			@$el.addClass("tm-bubble#{parseInt(Math.random()*3)+4}")
				
	addEntryView:(view)=>
		view.appendTo(@$holder)
		view.on("dateChange", @onEntryDateChange)
		view.on("destroy", @onEntryDestroy)

		@nav.setProperties({num:@$holder.children('.tm-entry').length})
		@showPage(0)
		@trigger("entryAdded",this)
	
	# active removal
	removeEntryView:(view)->
		view.off("dateChange", @onEntryDateChange)
		view.off("destroy", @onEntryDestroy)
		view.detach()
		@nav.setProperties({num:@$holder.children('.tm-entry').length})
		@trigger("entryRemoved", this)

		#@showPage(@$holder.find('.tm-entry').length)

	showPage: (page)=>
		@$holder.find('.tm-entry').each (index,el)=>
			if index == page then $(el).fadeIn(400).show() else $(el).fadeOut(400).hide()

	appendTo:($target)->
		@$el.appendTo($target)
	
	onEntryDateChange:(view,model)=>
		@trigger("entryDateChange", this, view, model)
	
	# passive removal
	onEntryDestroy:(view,model)=>
		@nav.setProperties({num:@$holder.children('.tm-entry').length})
		@trigger("entryDestroy", this, view, model)
	
	isEmpty: ()->
		return @$holder.children(".tm-entry").length == 0
	
	numEntries: ()->
		return @$holder.children(".tm-entry").length

	destroy:()->
		@$el.remove()
		@trigger("destroy", this)
	
	css:(obj, value)->
		if typeof obj == 'string'
			if value?
				@$el.css(obj, value)
			else
				return @$el.css(obj)
		else if obj
			@$el.css(obj)

	getPos:()->
		return @pos

modules.TimelineEntrySlider = TimelineEntrySlider
