

createLegend = (value, text, href)->
	$("<div class='tm-legend'> #{if href then "<a href='#{href}'>#{text}</a>" else text }</div>")


class VerticalGroup
	constructor:(pos,legendfuncs) ->
		_.extend(this, Backbone.Events)
		@pos = pos
		@$el = $("<div class='tm-vgroup'></div>").data("vgroup",this)
		@num = 0
		@legendfuncs = legendfuncs
		@legend = createLegend(pos, legendfuncs.legendText(pos))
		@$el.append(@legend)
		
	appendTo:($target)->
		@$el.appendTo($target)

	getLength: ()->
		return @num

	addSlider:(slider, vpos)->
		slider.appendTo(@$el)
		slider.css("top", 250) if vpos
		slider.on "destroy", @onSliderDestroy
		slider.on "entryAdded", @onEntryAddedToSlider
		slider.on "entryRemoved", @onEntryRemovedFromSlider
		@num = @num + 1


	onEntryAddedToSlider: ()=>
		n = 0
		edge = false
		@$el.children('.tm-slider').each (i,el)=>
			entries = $(el).find('.tm-entry')
			if entries.length >= 2
				n = n + 1
				if entries.length == 2
					edge = true
	
		if n == 1 and edge
			@enableLink()
	
	onEntryRemovedFromSlider: (slider)=>
		n = 0
		edge = false
		@$el.children('.tm-slider').each (i,el)=>
			entries = $(el).find('.tm-entry')
			if entries.length <= 1
				n = n + 1
				if entries.length == 1
					edge = true
	
		if n == 2 and edge
			@disableLink()

	disableLink:()->
		@legend.remove()
		@legend = createLegend(@pos, @legendfuncs.legendText(@pos))
		@$el.append(@legend)

	enableLink:()->
		@legend.remove()
		@legend = createLegend(@pos, @legendfuncs.legendText(@pos),@legendfuncs.legendHref(@pos))
		@$el.append(@legend)


	onSliderDestroy:(slider)=>
		@num = @num - 1
		if @$el.children('.tm-slider').length
			slider.off "entryAdded", @onEntryAddedToSlider
			slider.off "entryRemoved", @onEntryRemovedFromSlider

			@destroy()
			return
	
	destroy:()->
		@$el.remove()
		@trigger('destroy',this)
	
	css:(obj, value)->
		if typeof obj == 'string'
			if value?
				@$el.css(obj, value)
			else
				return @$el.css(obj)
		else if obj
			@$el.css(obj)

modules.TimelineVerticalGroup = VerticalGroup
