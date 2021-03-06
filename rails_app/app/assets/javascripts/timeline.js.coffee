#= require timeline/underscore
#= require timeline/json2
#= require timeline/module
#= require raphael-min
#= require timeline/date-ko-KR
#= require timeline/backbone 
#= require timeline/bill
#= require timeline/bill_collection
#= require timeline/bill_view
#= require timeline/timeline_entry
#= require timeline/timeline_entry_collection
#= require timeline/timeline_entry_navigator
#= require timeline/timeline_entry_view
#= require timeline/timeline_slider
#= require timeline/timeline_vgroup
#= require timeline/timeline_hgroup
#= require timeline/timeline_views
#
#
#= require timeline/jquery-ui-1.8.18.custom.min
#XXX : jquery corner 씀? A: 안씀ㅋ
#= require timeline/jquery.corner
#= require timeline/jquery.easing.1.3
#= require timeline/jquery.mousewheel.min
#= require timeline/jquery.tagsinput
# =require timeline/jqModal

TimelineEntry = modules.TimelineEntry
TimelineEntryCollection = modules.TimelineEntryCollection
TimelineView = modules.TimelineView
TermView = modules.TimelineTermView
YearView = modules.TimelineYearView
QuarterView = modules.TimelineQuarterView
MonthView = modules.TimelineMonthView
WeekView = modules.TimelineWeekView
DayView = modules.TimelineDayView
BillCollection = modules.BillCollection


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
		_.extend(this, Backbone.Events)
		TimelineController.displayEdit = options.edit if options && options.edit
		@pol1 = options.pol1 if options.pol1
		@pol2 = options.pol2 if options.pol2

		# We need to keep @collection and @views
		@collection = new TimelineEntryCollection()
		@billcollection = new BillCollection()
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
		@collection.on "add", (model)=>
			$("#timeline-msg-noentry1").hide() if model.get('politician_id') == @pol1._id
			$("#timeline-msg-noentry2").hide() if model.get('politician_id') == @pol2._id
			console.log('Entry added to collection')
			$.gritter.add({title:'타임라인 추가',text:"제목: '#{model.get('title')}'이 추가되었습니다."})
			@trigger("addEntry", model)
		@collection.on "remove", (model)=>
			p1_num = 0
			p2_num = 0
			@collection.each (entry)=>
				p1_num = p1_num + 1 if entry.get('politician_id') == @pol1._id
				p2_num = p2_num + 1 if entry.get('politician_id') == @pol2._id
			
			$("#timeline-msg-noentry1").show() if p1_num == 0
			$("#timeline-msg-noentry2").show() if p2_num == 0

			console.log('Entry removed from collection')
			$.gritter.add({title:'타임라인 삭제',text:"제목: '#{model.get('title')}'이 삭제되었습니다."})

			@trigger("removeEntry", model)

		@collection.on "change", (model)->
			console.log('Entry changed in collection')
			$.gritter.add({title:'타임라인 수정',text:"제목: '#{model.get('title')}'이 수정되었습니다."})
			@trigger("changeEntry", model)
	
	
	# `changeScale` takes name string of the new scale value (*year*, *month*, ...)
	changeScale: (scaleName, start)->
		console.warn('changeScale', scaleName)
		oldScale = @currentScale
	
		if !@views[scaleName]
			@views[scaleName] = new Views[scaleName](@collection,@billcollection)
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
		@currentScale.setStart(start, false) if start
		@currentScale.startAutoUpdate() if @autoUpdate
	
	# The timeline will be visible after appending it to an html element (argument is preferably a referencing jquery object).
	appendTo: ($el)->
		@$el = $el

		for key,view of @views
			view.appendTo(@$el)
		$(@$el).mousewheel (e, delta, deltax,deltay)=>
			e.preventDefault()
			console.warn('wheel', delta)
			if delta < 0
				@currentScale.goRight()
			else if delta >0
				@currentScale.goLeft()
			return false
			

		@navp = $("<div class='timeline-navigator'></div>").css({left:0,top:165,zIndex:2}).addClass('tm-nav-left').appendTo(@$el).mousedown ()=>
			@currentScale.goLeft()
		@navn = $("<div class='timeline-navigator'></div>").css({right:0,top:165,zIndex:2}).addClass('tm-nav-right').appendTo(@$el).mousedown ()=>
			@currentScale.goRight()

		@currentScale.trigger('viewportChange')

		$("<div id='timeline-msg-noentry1'>항목이 없습니다.</div>").appendTo(@$el)
		$("<div id='timeline-msg-noentry2'>항목이 없습니다.</div>").appendTo(@$el)
		@collection.each (entry)=>
			$("#timeline-msg-noentry1").hide() if entry.get('politician_id') == @pol1._id
			$("#timeline-msg-noentry2").hide() if entry.get('politician_id') == @pol2._id

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
		
	createEntry: (attrs, options)->
		entry = new TimelineEntry()
		options.silent = true
		options.success = (model)=>
			@collection.add(model)
		entry.save(attrs, options)

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
