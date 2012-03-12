
# EntryView,EntryNav -> Slider -> VGroup -> HGroup -> TimelineView
class TimelineEntryNav extends Backbone.View
	initialize:(options)->
		@$el = $("<div class='tm-sl-nav'><a href='#' class='tm-sl-nav-p'></a><span class='tm-sl-cntnt'></span>&nbsp;
		<a href='#' class='tm-sl-nav-n'></a></div>")
			
		@$pbutton = @$el.find('.tm-sl-nav-p').click @prev
		@$nbutton = @$el.find('.tm-sl-nav-n').click @next
		@$content = @$el.find('.tm-sl-cntnt')
		@setProperties(options)

	setProperties:(options)->
		@numPages = options.num if options.num?
		@currentPage = options.current if options.current?
		
		@currentPage = @numPages if @currentPage > @numPages

		#if @numPages > 1 then @$content.html("#{@currentPage+1}/#{@numPages}") else @$content.html(" ")

		if @currentPage+1 >= @numPages
			@$nbutton.css('visibility','hidden')
		else
			@$nbutton.css('visibility','')
		
		if @currentPage == 0
			@$pbutton.css('visibility','hidden')
		else
			@$pbutton.css('visibility','')
	
	appendTo:(target)->
		@$el.appendTo(target)
		
	prev:()=>
		return false if @currentPage <= 0
		@setProperties({current:@currentPage-1})
		@trigger('prev')
		@trigger('changePage', @currentPage)
		return false

	next:()=>
		return false if @currentPage+1 >= @numPages
		@setProperties({current:@currentPage+1})
		@trigger('prev')
		@trigger('changePage', @currentPage)
		return false




modules.TimelineEntryNav = TimelineEntryNav
