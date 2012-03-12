
TimelineEntry = modules.TimelineEntry
TimelineEntryCollection = modules.TimelineEntryCollection
TimelineView = modules.TimelineView
TermView = modules.TimelineTermView
YearView = modules.TimelineYearView
QuarterView = modules.TimelineQuarterView
MonthView = modules.TimelineMonthView
WeekView = modules.TimelineWeekView
DayView = modules.TimelineDayView

Views =
	all:     TermView
	year:    YearView
	quarter: QuarterView
	month:   MonthView
	week:    WeekView
	day:     DayView



class TimelineController
	@displayEdit : false

	constructor: (options)->
		
		TimelineController.displayEdit = options.edit if options && options.edit
		@pol1 = options.pol1 if options.pol1
		@pol2 = options.pol2 if options.pol2

		# We need to keep @collection and @views
		@collection = new TimelineEntryCollection()
		@collection.pol1 = @pol1 if @pol1
		@collection.pol2 = @pol2 if @pol2
		
		@views = {}
		# Default scale view (year) is created on object creation
		@changeScale('year')
		console.log("initial scale is year")

		# bootstrap initial data
		if options.entries
			for entry in options.entries
				@collection.add(entry)
		
		# Growl
		@collection.on "add", (model)->
			$("#timeline-msg-noentry").hide()
			console.log('Entry added to collection')
			$.gritter.add({title:'추가',text:"항목(#{model.get('title')})이 추가되었습니다."})
		@collection.on "remove", (model)->
			if @collection.length == 0
				$("#timeline-msg-noentry").show()
			console.log('Entry removed from collection')
			$.gritter.add({title:'삭제',text:"항목(#{model.get('title')})이 삭제되었습니다."})

		@collection.on "change", (model)->
			console.log('Entry changed in collection')
			$.gritter.add({title:'수정',text:"항목(#{model.get('title')})이 수정되었습니다."})


	
	# `changeScale` takes name string of the new scale value (*year*, *month*, ...)
	changeScale: (scaleName, start)->
		console.warn('changeScale', scaleName)
		oldScale = @currentScale
	
		if !@views[scaleName]
			@views[scaleName] = new Views[scaleName](@collection)	
			@views[scaleName].appendTo(@$el)

		@currentScale = @views[scaleName]

		# Transition between oldScale and currentScale (may simple be a `show()` and a `hide()`)
		if oldScale? && oldScale != @currentScale
			console.log("Scale change to #{scaleName}")
			oldScale.stopAutoUpdate() if @autoUpdate
			oldScale.hide()
			oldScale.off('viewportChange', @onViewportChange)
	
		@currentScale.show()
		@currentScale.on('viewportChange', @onViewportChange)
		@currentScale.setStart((if start? then start else 100000), false)
		@currentScale.startAutoUpdate() if @autoUpdate
	
	# The timeline will be visible after appending it to an html element (argument is preferably a referencing jquery object).
	appendTo: ($el)->
		@$el = $el

		for key,view of @views
			view.appendTo(@$el)
		$(@$el).mousewheel (e, delta, deltax,deltay)=>
			e.preventDefault()
			if delta > -0.5 && delta < 0
				@currentScale.goRight()
			else if delta < 0.5  && delta >0
				@currentScale.goLeft()
			return false
			

		@navp = $("<div class='timeline-navigator'></div>").css({left:0,top:165,zIndex:2}).addClass('tm-nav-left').appendTo(@$el).mousedown ()=>
			@currentScale.goLeft()
		@navn = $("<div class='timeline-navigator'></div>").css({right:0,top:165,zIndex:2}).addClass('tm-nav-right').appendTo(@$el).mousedown ()=>
			@currentScale.goRight()

		@currentScale.trigger('viewportChange')

		$("<div id='timeline-msg-noentry'>항목이 없습니다.</div>").appendTo(@$el)
		$("#timeline-msg-noentry").hide() if @collection.length > 0

	onViewportChange:()=>
		bounds = @currentScale.bounds
		return if !@navp? || !@navn?
		
		if !bounds?
			@navp.hide()
			@navn.hide()
			return

		[lbound,center,rbound] = bounds
		
		x = @currentScale.x
		width = @currentScale.getWidth()
		console.warn 'changeScale', x,width
		if rbound-lbound <= width
			@navp.hide()
			@navn.hide()
			return

		console.log(x+lbound,x+rbound-width)
		if x + lbound >= 0
			@navp.hide()
		else
			@navp.show()

		if x + rbound <= width
			@navn.hide()
		else
			@navn.show()
		
	# You can let the timeline updated automatically.
	startAutoUpdate: ()->
		@autoUpdate = true
		@currentScale.startAutoUpdate()

	stopAutoUpdate: ()->
		@autoUpdate = false
		@currentScale.stopAutoUpdate()
	
	addEntry: (model)->
		@collection.add(model)
	
	createEntry: (attrs, options)->
		entry = new TimelineEntry()
		options.silent = true
		entry.save(attrs, options) # shouldn't dispatch as update
		@collection.add(entry)

	updateEntry: (id, attrs, options)->
		entry = @collection.get(id)
		entry.save(attrs, options)

	# force refresh
	reset:()->
		@currentScale.reset()

	
	

# And finally, make sure it is available outside the file.
modules.TimelineController = TimelineController
$ ->
	$('#link-cancel').live 'click', ->
		$.colorbox.close()
		false
	return
