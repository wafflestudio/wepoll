TimelineEntryView = modules.TimelineEntryView
TimelineEntrySlider = modules.TimelineEntrySlider
HorizontalGroup = modules.TimelineHorizontalGroup
BillView = modules.BillView
Bill = modules.Bill

class TimelineView
	@EntryWidth: 240

	constructor:(@collection,@billcollection)->

		_.extend(this, Backbone.Events)
		@sliders = [{},{}]
		@groups = {}
		@x = 0
		@bills = {}
		
		@collection.on("add", @onEntryAdd)
		@billcollection.on("reset", @onBillInit)

		@$el = $("<div class='timeline-view'></div>")
		# if @collection is already loaded somehow
		@collection.each (entry)=>
			@drawEntry(entry)
	
		@billcollection.fetch({politicians:[@collection.pol1._id,@collection.pol2._id]})

	getWidth:()->
		if !@$el.parent()
			#console.log('no parent',@$el.width())
			return @$el.width()
		else if @$el.parent().width()
			#console.log('parent',@$el.parent().width())
			return @$el.parent().width()
		else
			#console.log('parent but no width',688)
			return 688


	
	fetch:(options)->
		@collection.fetch(options)

	appendTo:($target)->
		@$el.appendTo($target) if $target

	show:()->
		@$el.show()

	hide:()->
		@$el.hide()

	drawBill: (bill)->
		pos = @calcPosition(bill.get("voted_at"))
		return if @bills[pos]
		billView = new BillView({model:bill})
		@addBillView(billView,pos)
		

	addBillView:(billView,pos)->
		group = @prepareGroup(pos,'bill')
		billView.pos = pos
		group.addBillView(billView, pos)
		console.warn('bill added')
		@bills[pos] = billView

	drawEntry: (entry)->
		pos = @calcPosition(entry.get("posted_at"))
		vpos = @getVpos(entry)
		slider = @sliders[vpos][pos]
		if !slider
			slider = new TimelineEntrySlider({pos:pos,vpos:vpos})
			console.log('TimelineView','drawEntry', "slider doesn't exist, adding slider at #{pos},#{vpos}")
			@addSlider(slider, pos, vpos)
		else
			console.log('TimelineView','drawEntry',"using existing slider at #{pos},#{vpos}")
		
		entryView = new TimelineEntryView({model:entry})
		slider.addEntryView(entryView)

	addSlider: (slider,pos,vpos)->
		group = @prepareGroup(pos,vpos)
		slider.pos = pos
		slider.vpos = vpos
		group.addSlider(slider,pos,vpos)

		slider.on("entryDateChange", @onEntryDateChange)
		slider.on("entryDestroy", @onEntryRemove)
		slider.on("destroy",@onSliderDestroy)
		@sliders[if vpos? then vpos else 0][pos] = slider

		

	removeSlider: (slider)->
		slider.off("entryDateChange", @onEntryDateChange)
		slider.off("entryDestroy", @onEntryRemove)
		delete @sliders[slider.vpos][slider.pos]
		slider.destroy()
		slider.off("destroy",@onSliderDestroy)


	# Group is added according to its position, not at the end of array
	addGroup:(group)->
		# search from $@el for proper position
		found = false
		@$el.children(".tm-hgroup").each (index, el)=>
			if $(el).data("pos") > group.pos
				$(el).before(group.$el) if !found
				found = true

		# if none found
		if !found
			group.appendTo(@$el)

		group.on("dimensionChange", @onChildDimensionChange,"add")
	
	removeGroup:(group)->
		group.off("dimensionChange", @onChildDimensionChange,"remove")
		group.destroy()

	onChildDimensionChange:(cause)=>
		return if cause != "remove"
		pos = @getCurrentCenterPos()
		@setStart(pos)

		# scroll to nearby?
		#if @timeout
		#	clearTimeout(@timeout)
		#@timeout = setTimeout ()=>
		#	@timeout = null
		#	@setStart(pos)
		#, 4000
	
	prepareGroup:(pos, vpos)->

		if @groups[pos]
			console.log('prepareGroup',"using existing hgroup (#{pos},#{vpos})")
		# [pos-1] [pos+1]: merge to both left and right
		else if @groups[pos-1] && @groups[pos+1]
			console.log('prepareGroup',"merging left-right (#{pos},#{vpos})")
			# move right elements to left
			@groups[pos-1].appendBulk(@groups[pos+1].collapse(), @groups[pos-1].span+1)
			# clear right side, as we won't need it any more
			oldRight = @groups[pos+1]
			@groups[pos] = @groups[pos-1]
			i = pos + 1
			while @groups[i] == oldRight
				@groups[i] = @groups[pos-1]
				i++
			@removeGroup(oldRight)
		else if @groups[pos-1] # [pos-1] [pos+2] merge to left
			console.log('prepareGroup',"merging left (#{pos},#{vpos})")
			@groups[pos] = @groups[pos-1]
			#@groups[pos].setSpan(@groups[pos].span+1)
		else if @groups[pos+1] # merge to right
			console.log('prepareGroup',"merging right (#{pos},#{vpos})")
			@groups[pos] = @groups[pos+1]
			@groups[pos].setPos(pos)
			#@groups[pos].setSpan(@groups[pos].span+1)

		else # none exists nearby
			console.log('prepareGroup',"none exists nearby (#{pos},#{vpos}), creating new hgroup")
			@groups[pos] = new HorizontalGroup(pos, {legendText:@legendText, legendHref:@legendHref})
			@addGroup(@groups[pos])

		return @groups[pos]
	
	
	# When a slider is removed, we can compress space between sliders in between. 
	onSliderDestroy:(slider)=>
		pos = slider.pos

		return if @groups[pos].getLength(pos)  > 0

		if !@groups[pos]
			throw "hgroup of pos(#{pos}) doesn't exist"
		else if @groups[pos-1] && @groups[pos+1] # split into two
			console.log('event', "slider is removed, splitting group")
			leftGroup = @groups[pos-1]
			# create new for right
			rightGroup = new HorizontalGroup(pos+1,{legendText:@legendText, legendHref:@legendHref})

			@addGroup(rightGroup)
			# move some from left to right [] [] x [] [] (span:5->pos-epoch) pos-1 
			rightGroup.appendBulk(leftGroup.collapse(pos+1), -(leftGroup.span+1))#pos+1-leftGroup.epoch)

		else if @groups[pos-1]
			# set span
			console.log('event', "slider is removed, right of group is removed")
			#@groups[pos-1].setSpan(@groups[pos-1].span-1)

		else if @groups[pos+1]
			console.log('event', "slider is removed, left of group is removed")
			@groups[pos+1].setPos(pos+1)
			#@groups[pos+1].setSpan(@groups[pos+1].span-1)
		else # actually remove 
			console.log('event', "slider is removed, removing group itself")
			@removeGroup(@groups[pos])

		delete @groups[pos]
	
	getVpos: (entry)->
		pid = entry.get("politician_id")
		if pid == @collection.pol1._id
			return 0
		else if pid == @collection.pol2._id
			return 1
		return 2

	onBillInit:()=>
		@billcollection.each (bill)=>
			@drawBill(bill)
	
		
	onEntryAdd:(entry)=>
		console.log('TimelineView','event',"entry added, drawing")
		@drawEntry(entry)

		
	onEntryRemove:(slider, entryView, entry)=>
		console.log('TimelineView','event',"entry removed")
		if slider.isEmpty()
			console.log("- slider is removed (no entry left)")
			@removeSlider(slider)
	
	onEntryDateChange:(slider, entryView, entry)=>
		vpos = @getVpos(entry)
		pos = @calcPosition(entry.get('posted_at'))
		newSlider = @sliders[vpos][pos] if @sliders[vpos]
		if newSlider != slider
			console.log('TimelineView','event','Entry pos changed from date change')
			slider.removeEntryView(entryView)
			if slider.isEmpty()
				console.log("- slider is removed (no entry left)")
				@removeSlider(slider)
			if !newSlider
				newSlider = new TimelineEntrySlider({pos:pos,vpos:vpos})
				@addSlider(newSlider, pos, vpos)
			newSlider.addEntryView(entryView)

	# You can let the view updated automatically.
	startAutoUpdate: ()->
		@update()
		@timer = setInterval ()=>
			@update()
		, 30000

	setStart:(pos, animate = true)->
		console.info('setStart', pos)
		newPos = null
		if !@groups[pos]
			for p,group of @groups
				if group.pos <= pos && pos < group.pos + group.span
					newPos = group.pos
					break
	
		if !@groups[pos] && !newPos? # pos not found
			found = false
			nearest = 0
			dist = null

			# get lbound and rbound
			for p, group of @groups
				nearest = p if Math.abs(pos-p) < dist or !dist?

			pos = nearest
		
		bounds = @getBounds()
		return if !bounds?
		[lbound,center,rbound] = bounds
		
		left = @groups[pos].getLeft()+100 # 100 for margin
		width = @getWidth()
		
		if rbound-lbound <= width
			lcap = width/2-(rbound-lbound)/2
			@setX(lcap-lbound)
		else
			if rbound - left <= width
				@setRight(rbound)
			else
				@setLeft(left)
		

	
		# @$el.css("left", -@groups[pos].getLeft())
	
	stopAutoUpdate: ()->
		clearTimeout(@timer)
	
	update: (params)->
		@collection.update(params)

	getX:()->
		return parseInt(@$el.css("left"))

	setX:(x, animate=false)->
		console.log('setX',x)
		oldX = @getX()
		if animate
			@moving = true
			
			@$el.animate({left:x},{complete:()=>
				@moving = false
			,queue:false})
		else
			@$el.css("left",x)

		if oldX != x
			@x = x
			@trigger("viewportChange")


	getLeft:()->
		return -parseInt(@$el.css("left"))

	setLeft:(left, animate=false)->
		console.log('setLeft',left)
		oldLeft = @getLeft()
		if animate
			@moving = true
			
			@$el.animate({left:-left},{complete:()=>
				@moving = false
			,queue:false})
		else
			@$el.css("left",-left)

		if oldLeft != left
			@x = -left
			@trigger("viewportChange")



	getRight:()->
		return @getWidth()-parseInt(@$el.css("left"))

	setRight:(right,animate=false)->
		console.log('setRight',right)
		oldRight = @getRight()
		width = @getWidth()
		if animate
			@moving = true
			
			@$el.animate({left:-right+width},{complete:()=>
				@moving = false
			,queue:false})
		else
			@$el.css("left",-right+width)
	
		if oldRight != right
			@x = -right+width
			@trigger("viewportChange")



	# get which one we are looking at
	getCurrentCenterPos:()->
		
		viewCenter = @getWidth()/2
		nearest = null
		dist = null
		for p, group of @groups
			lmost = group.getLeft()+100 # 100 for margin
			rmost = lmost +  group.span*TimelineView.EntryWidth
			
			if lmost <= viewCenter/2 && viewCenter/2 <= rmost
				return p

			ldist = Math.abs(lmost - viewCenter/2)
			rdist = Math.abs(rmost - viewCenter/2)
			d = if ldist > rdist then rdist else ldist
			if dist == null or d < dist
				dist = d
				nearest = p

		return nearest


	getBounds:()->
		lbound = null
		rbound = null
		#center = (lbound + rbound)/2
		
		found = false
		nearest = 0

		# get lbound and rbound
		for p, group of @groups
			lmost = group.getLeft()+100 # 100 for margin
			rmost = lmost +  group.span*TimelineView.EntryWidth

			lbound = lmost if !lbound? or lbound > lmost
			rbound = rmost if !rbound? or rbound < rmost
	
		if !lbound? || !rbound?
			console.log('getBounds returning null')
			return null

		center = (lbound + rbound)/2

		console.log('getBounds',lbound, center, rbound)
		@bounds = [lbound,center,rbound]
		return @bounds

	
	goLeft: ()->
		return if @moving
		bounds = @getBounds()
		return if !bounds?
		[lbound,center,rbound] = bounds
		
		left = @getLeft()
		width = @getWidth()

		if rbound-lbound <= width
			lcap = width/2-(rbound-lbound)/2 # 344-210=134  134-310=-176
			x = @getX()
			
			if (x+lbound)-TimelineView.EntryWidth <= lcap
				@setX(lcap-lbound,true)
			else
				@setX(x-TimelineView.EntryWidth,true)
		else
			if left-TimelineView.EntryWidth <= lbound
				console.log("go left to: bound #{lbound}")
				@setLeft(lbound,true)
			else
				console.log("go left to: #{left-TimelineView.EntryWidth}")
				@setLeft(left-TimelineView.EntryWidth,true)


	goRight: ()->
		return if @moving
		bounds = @getBounds()
		return if !bounds?
		[lbound,center,rbound] = bounds

		right = @getRight()
		width = @getWidth()

		if rbound-lbound <= width
			rcap = width/2+(rbound-lbound)/2
			x = @getX()
			
			if (x+rbound)+TimelineView.EntryWidth >= rcap
				@setX(rcap-rbound,true)
			else
				@setX(x+TimelineView.EntryWidth,true)
		else
			if right+TimelineView.EntryWidth >= rbound
				console.log("right to: bound #{rbound}")
				@setRight(rbound,true)
			else
				console.log("right to: #{right+TimelineView.EntryWidth}")
				@setRight(right+TimelineView.EntryWidth,true)
		
	reset: ()->
		console.warn 'reset called'
		bounds = @getBounds()
		return if !bounds?
		[lbound,center,rbound] = bounds

		width = @getWidth()

		if rbound-lbound <= width
			rcap = width/2+(rbound-lbound)/2
			@setX(rcap-rbound)
		else
			@setRight(rbound)


		

class TermView extends TimelineView
	@unit : "term"

	fetch: (startTerm, endTerm)->
		options =
			start: startTerm
			end:   endTerm
			unit:  'term'
		
		super(options)

	calcPosition: (date)->
		term = parseInt((Date.parse(date).getFullYear()-1936)/4)
	
	legendText: (pos)->
		year = parseInt(pos*4)+1936
		"#{year}년~#{year+3}년"
	
	legendHref: (pos)->
		year = parseInt(pos*4)+1936
		"#year/#{year}"

	epoch: ()->
		# TODO:일단 16대부터
		return 16

	setStart:(pos, animate = true)->
		super(pos, animate)



class YearView extends TimelineView
	@unit : "year"

	calcPosition: (date)->
		d = Date.parse(date)
		year = d.getFullYear()
		return year
	
	legendText: (pos)->
		return "#{pos}년"
	
	legendHref: (pos)->
		return "#quarter/#{pos}"
	
	epoch: ()->
		today = new Date()
		return today.getFullYear()-4
		
	setStart:(pos, animate = true)->
		super(pos, animate)


class QuarterView extends TimelineView
	@unit : "quarter"

	calcPosition: (date)->
		d = Date.parse(date)
		year = d.getFullYear()
		quarter = parseInt(d.getMonth()/3) # not 4!
		return year*4 + quarter
	
	legendText: (pos)->
		year = parseInt(pos/4)
		quarter = pos%4
		return "#{year}년 #{quarter+1}분기"
	
	legendHref: (pos)->
		return "#month/#{pos}"
	
	epoch: ()->
		today = new Date()
		return today.getFullYear()*4-4
	
	setStart: (pos,animate=true)->
		if typeof pos == 'object'
			pos = pos.year *4 + pos.quarter
		super(pos, animate)



getFirstDayOfYear = (date)->
	year = if typeof date == 'number' then date else new Date(date).getFullYear()
	return new Date(year,0,1,0,0,0) # y m d h m s

normalizeDate = (date)->
	month = date.getMonth()+1
	day = date.getDate()
	return new Date(date.getFullYear(),month-1,day, 0, 0, 0)

getDayOfYear = (date)->
	d = normalizeDate(new Date(date))
	epoch = getFirstDayOfYear(d)
	return (d.getTime()-epoch.getTime())/1000/60/60/24




class MonthView extends TimelineView
	@unit : "month"

	calcPosition: (date)->
		d = Date.parse(date)
		year = d.getFullYear()
		month = d.getMonth()
		return year*12+month
	
	legendText: (pos)->
		year = parseInt(pos/12)
		month = pos % 12+1
		return "#{year}년 #{month}월"
	
	legendHref: (pos)->
		year = parseInt(pos/12)
		month = pos % 12+1
		return "#week/#{year}/#{month}"
	
	epoch: ()->
		today = new Date()
		return today.getFullYear()*12 + today.getMonth()-4
	
	setStart: (pos, animate=true)->
		if typeof pos == 'object'
			pos = pos.year *12 + pos.month
		super(pos, animate)

class WeekView extends TimelineView
	@unit : "week"

	calcPosition: (date)->
		d = Date.parse(date)
		year = d.getFullYear()
		week = parseInt(getDayOfYear(d)/7)
		return year*53+week
	
	legendText: (pos)->
		year = parseInt(pos/53)
		week = (pos % 53)
		#console.log(year,week)
		date = new Date(getFirstDayOfYear(year).getTime()+week*7*24*60*60*1000)
		endDate = new Date(getFirstDayOfYear(year).getTime()+(week*7+6)*24*60*60*1000)
		
		return "#{date.getFullYear()}.#{date.getMonth()+1}.#{date.getDate()}~#{endDate.getFullYear()}.#{endDate.getMonth()+1}.#{endDate.getDate()}"
	
	legendHref: (pos)->
		#console.log('href'+pos)
		year = parseInt(pos/53)
		week = (pos % 53)
		date = new Date(getFirstDayOfYear(year).getTime()+week*7*24*60*60*1000)

		return "#day/#{year}/#{date.getMonth()+1}/#{date.getDate()}"
	
	epoch: ()->
		today = new Date()
		week = parseInt(getDayOfYear(@getDefaultDate(today.getFullYear(),today.getMonth()+1))/7)
		return today.getFullYear()*53 + week-4

	getDefaultDate: (year,month)->
		d = new Date(0)
		d.setFullYear(parseInt(year))
		d.setMonth(parseInt(month)-1) if month?
		return d
	
	setStart: (pos, animate=true)->
		if typeof pos == 'object'
			week = parseInt(getDayOfYear(@getDefaultDate(pos.year,pos.month))/7)
			pos = parseInt(pos.year)*53 + week
			
		super(pos, animate)


class DayView extends TimelineView
	@unit : "day"

	calcPosition: (date)->
		d = Date.parse(date)
		year = d.getFullYear()
		dayofyear = getDayOfYear(d)
		return year*366+dayofyear
	
	legendText: (pos)->
		year = parseInt(pos/366)
		dayofyear = pos%366

		date = new Date(year,0,1,0,0)
		date = new Date(getFirstDayOfYear(date).getTime()+dayofyear*24*60*60*1000)

		return "#{date.getFullYear()}.#{date.getMonth()+1}.#{date.getDate()}"
	
	legendHref: (pos)->
		return null
	
	epoch: ()->
		today = new Date()
		return today.getFullYear()*12 + today.getMonth()-4
	
	setStart: (pos, animate=true)->
		#console.log("setStart #{pos}")
		if typeof pos == 'object'
			d = new Date(pos.year,pos.month-1, pos.day, 0,0,0)
			dayofyear = getDayOfYear(d)
			pos = pos.year *366 + dayofyear
		super(pos, animate)

modules.TimelineView = TimelineView
modules.TimelineTermView = TermView
modules.TimelineYearView = YearView
modules.TimelineQuarterView = QuarterView
modules.TimelineMonthView = MonthView
modules.TimelineWeekView = WeekView
modules.TimelineDayView = DayView
