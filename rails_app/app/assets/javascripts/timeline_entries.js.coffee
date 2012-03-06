# This backbone-enabled coffeescript library creates a horizontal timeline that:
#	
# *	can be switched into various scales (years, months, weeks, etc.)
#
# * takes updates from server periodically and displays any changes
#
# * supports multiple rows 
#
#
#	### Usage
#
#			timeline = new TimelineController()
#			timeline.startAutoUpdate()         # optional
#			timeline.appendTo("#timeline")     # activate view
#
#
# ###  Anatomy
#
# * The [`TimelineController`](#section-TimelineController) instance maintains a `TimelineEntryCollection` stored in @collection.
#
# *	A `TimelineController` manages layers of [`TimelineView`](#section-TimelineView).
#
#		* It will create new `TimelineView` instance for a requested scale, on-demand.
#			
#		* It initially creates a default `TimelineView`, thus triggering first fetch of @collection.
#	
#		* It keeps @currentView referencing the active `TimelineView`, and an array of created `TimelineView` instances.
#
#	
#
# * A `TimelineView` has multiple [`TimelineEntrySlider`](#section-TimelineEntrySlider) instances on its axis.
#
# * A `TimelineEntrySlider` has multiple [`TimelineEntry`](#section-TimelineEntry) instances as its slides.
#
#
# ### Initial Setup and Event Propagations
#
# * The [`TimelineController`](#section-TimelineController) creates a default [`TimelineView`](#section-TimelineView).
# 
# * A`TimelineView`, upon creation, fetches @collection for itself according to its requirements and scope.
# 
# 	* Upon a successful fetch, the @collection is filled and *add* event is triggered for each of newly fetched entries in the collection (entries already there is ignored by `TimelineView`'s update algorithm). 
#
#		* Upon addition of an entry, a [`TimelineEntryView`](#section-TimelineEntryView) refering to the entry is created and attached to a newly created/already exsting [`TimelineEntrySlider`](#section-TimelineEntrySlider), according to the entry's temporal position. 
#	
#	
# ### Periodic Updates and Event Propagations
#	
#	* The active `TimelineView` periodically fetches updates.
#
# * Note: As the @collection itself is updated by a periodic fetch, any `TimelineEntryView` listening to its model events (add/change/remove) will also be updated regardless of active state of enclosing `TimelineView`.




# TimelineEntry
# =====================================================
# **TimelineEntry** is the backbone model for a single object refering to `/timeline_entries/(_id)`
#	
class TimelineEntry extends Backbone.Model
	defaults: {
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



# TimelineEntryCollection
# =====================================================
# **TimelineEntryCollection** is the backbone collection for the model `TimelineEntry` refering to the resource `/timeline_entries`
class TimelineEntryCollection extends Backbone.Collection
	model:TimelineEntry
	url: '/timeline_entries'
	initialize:()->
		
	# Update to a collection can be made with extra parameters.
	update: (params)->
		latest = new Date(1000,0,1) # let's assume some time
		updated = new TimelineEntryCollection()
		updated.pol1 = @pol1
		updated.pol2 = @pol2

		this.each (model)->
			date = new Date(model.get("updated_at"))
			latest = date if latest.getTime() < date.getTime()

		params ?= {}
		params.from = latest.toISOString()
		params.pol1 = @pol1._id if @pol1
		params.pol2 = @pol2._id if @pol2
		
		updated.fetch({ data: $.param(params), success: ()=>
			# Once update is fetched, the client-side collection is updated according to insertion/update/deletion actions per model.
			updated.forEach (entry)=>
				target = this.get(entry.id)
				# * Insertion
				if !target && !entry.get("deleted")
					this.add entry
				# * Deletion
				else if target && entry.get("deleted")
					this.remove entry
				# * Update
				else if target
					# (unchanged entry will not be updated)
					server_ts = new Date(entry.get("updated_at"))
					client_ts = new Date(entry.get("updated_at"))
					target.set(entry.attributes) if client_ts.getTime() < server_ts.getTime()

			})


formatDate = (d)->
	"#{d.getFullYear()}.#{d.getMonth()+1}.#{d.getDate()}"



# TimelineEntryView
# =====================================================
# **TimelineEntryView** is the backbone view for [`TimelineEntry`](#section-TimelineEntry)
#	
#	Holds a `<div>` that contains the editable content of the entry
# 
# * A `TimelineEntryView` listens to the entry's change/remove events
#	
# 	* Upon *change* event, the view updates its content displayed. On a change in `posted_at` attribute where the calculated position in the enclosing `TimelineView` changes, the timeline view should be notified and reposition the entry. As calculating the position of the enclosing timeline view is unknown to the entry, it just emits a `dateChange` event on every `posted_at` change.
#				
#		* Upon *remove* event, the view is discarded, and emits own *remove* event.
#	
#	* A `TimelineEntryView` is normally held in a [`TimelineEntrySlider`](#section-TimelineEntrySlider).
#
class TimelineEntryView extends Backbone.View
	@createView: (model)->
		template = "<div class='tm-entry-view'>
				<p>Comment: #{model.escape('comment')}<p>
				<p>Link: #{model.escape('url')}</p>
				<p>Date: #{formatDate(new Date(model.escape('posted_at')))}</p>
				#{if TimelineController.displayEdit then "<p><a href='#'>Edit</a></p>" else ""}
			</div>"
		element = $(template)
		element.find('a').click (evt)=>
			$(element).trigger('changeMode')
			return false
		return element
		
	# The `createForm` class method definition is exposed for new/edit form creation.
	# `createForm` will return a jquery object carrying a DOM node filled with the form used to create/update a `TimelineEntry`.
	# the returned object exposes *save* event to listen to.
	@createForm: (model,pol)->
		template = "<form method='post' action='/timeline_entries/#{if model then model.id else 'new'}' accept-charset='UTF-8'>
				<input type='hidden' name='_method' value='#{if model then 'put' else 'post'}'/>
				<input type='hidden' name='politician_id' value='#{if model then model.escape('politician_id') else pol}'/>
				<p>Comment:</p>
				<p><textarea name='comment' rows='2' cols='16'>#{if model then model.escape('comment') else ''}</textarea></p>
				<p>Link:<input type='text' name='url' value='#{if model then model.escape('url') else ''}'/></input><p>
					
				<p>Date:<input type='text' name='posted_at' value='#{if model then model.escape('posted_at') else ''}'/></p>
				<p><input type='submit' value='Done'/></p>
			</form>"
		# Create a new model with default values if not supplied in the argument.
		model = new TimelineEntry({comment:"",url:"",posted_at:new Date().toISOString()}) if !model
		element = $(template)
		# A datepicker is supplied.
		$(element).find('input[name="posted_at"]').datepicker()

		# The model is saved on clicking the submit button.
		$(element).find('input[type="submit"]').click (evt)=>
			$(element).find('[name!="_method"]').each (index, el)=>
				name = $(el).attr('name')
				if name == 'posted_at'
					model.set(name, new Date($(el).val()).toISOString())
				else
					model.set(name,$(el).val())
			# If the save was successful, the tangled element emits a *save* event for others to get notified.
			model.save(null, {success: ()->
				$(element).trigger("save", [model])
			,error: ()->
				console.log("error")
			})
			# Returning false is required to avoid actually opening a page.
			return false

		return element


	initialize: ()->
		@model = if @options.model then @options.model else new TimelineEntry()
		@model.on "change", @onChange
		@model.on "remove", @onRemove
		@model.on("change:posted_at", @onDateChange)
		@render()
	
	render: ()->
		if !@hasEl
			edit = TimelineEntryView.createForm(@model)
			view = TimelineEntryView.createView(@model)
			element = $("<div class='tm-entry'/>").append(edit).append(view)
			edit.hide()

			view.on "changeMode", ()=>
				view.hide()
				edit.show()
			edit.on "save", ()=>
				view.remove()
				view = TimelineEntryView.createView(@model)
				element.append(view)
				view.on "changeMode", () =>
					view.hide()
					edit.show()
				edit.hide()
				view.show()


			delete_link = $("<a class='tm-entry-delete' href='#'>삭제</a>").click ()=>
				@model.destroy() if confirm("정말로 삭제하시겠습니까?")

			edit.append(delete_link)
			@setElement(element)
		@hasEl = true
	
	appendTo: ($target)->
		$(@$el).appendTo($target)

	detach: ()->
		$(@$el).detach()

	onChange: ()=>
		@render()

	onRemove: ()=>
		@destroy()
		@trigger("destroy", this, @model)

	onDateChange: ()=>
		@trigger("dateChange", this, @model)

	save: ()->
		
	destroy: ()->
		@model.off "change", @onChange
		@model.off "remove", @onRemove
		@model.off "change:posted_at", @onDateChange
		@$el.remove() if @hasEl

# EntryView,EntryNav -> Slider -> VGroup -> HGroup -> TimelineView
class TimelineEntryNav extends Backbone.View
	initialize:(options)->
		@$el = $("<div class='tm-sl-nav'><a href='#' class='tm-sl-nav-p'>P</a><span class='tm-sl-cntnt'></span>
		<a href='#' class='tm-sl-nav-n'>N</a></div>")
			
		@$pbutton = @$el.find('.tm-sl-nav-p').click @prev
		@$nbutton = @$el.find('.tm-sl-nav-n').click @next
		@$content = @$el.find('.tm-sl-cntnt')
		@setProperties(options)

	setProperties:(options)->
		@numPages = options.num if options.num?
		@currentPage = options.current if options.current?
		
		@currentPage = @numPages if @currentPage > @numPages

		if @numPages > 1 then @$content.html("#{@currentPage+1}/#{@numPages}") else @$content.html(" ")

		if @currentPage+1 >= @numPages
			@$nbutton.hide()
		else
			@$nbutton.show()
		
		if @currentPage == 0
			@$pbutton.hide()
		else
			@$pbutton.show()
	
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

createLegend = (value, text, href)->
	$("<div class='tm-legend'> #{if href then "<a href='#{href}'>#{text}</a>" else text }</div>")

# TimelineEntrySlider
# =====================================================
# A **TimelineEntrySlider** is placed on the time axis of a timeline view (a [`TimelineView`](#section-TimelineView) instance).
# 
# It holds one or more [`TimelineEntryView`](#section-TimelineEntryView).
#
# * Upon change of temporal position of a timeline view (which is triggered from a `change` event of the listened model), the slider may dispatch a *"entryDateChange"* event
#
class TimelineEntrySlider extends Backbone.View
	initialize:(options)->
		@$el = $("<div class='tm-slider'></div>").data('slider', this)
		@$holder = $("<div class='tm-sl-holder'></div>").appendTo(@$el)

		@nav = new TimelineEntryNav({current:0,num:0})
		@nav.appendTo(@$holder)
		@nav.on "changePage", @showPage
		@pos = options.pos
		@vpos = options.vpos
		

	
		
	addEntry:(view)=>
		view.appendTo(@$holder)
		view.on("dateChange", @onEntryDateChange)
		view.on("destroy", @onEntryDestroy)

		@nav.setProperties({num:@$holder.children('.tm-entry').length})
		@showPage(0)
		
	removeEntry:(view)->
		view.off("dateChange", @onEntryDateChange)
		view.off("destroy", @onEntryDestroy)
		view.detach()
		@nav.setProperties({num:@$holder.children('.tm-entry').length})

		#@showPage(@$holder.find('.tm-entry').length)

	showPage: (page)=>
		@$holder.find('.tm-entry').each (index,el)=>
			if index == page then $(el).show() else $(el).hide()

	appendTo:($target)->
		@$el.appendTo($target)
	
	onEntryDateChange:(view,model)=>
		@trigger("entryDateChange", this, view, model)
	
	onEntryDestroy:(view,model)=>
		@nav.setProperties({num:@$holder.children('.tm-entry').length})
		@trigger("entryDestroy", this, view, model)
	
	isEmpty: ()->
		return @$holder.children(".tm-entry").length == 0

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



class VerticalGroup
	constructor:(pos,legendfuncs) ->
		_.extend(this, Backbone.Events)
		@pos = pos
		@$el = $("<div class='tm-vgroup'></div>").data("vgroup",this)
		@num = 0
		legend = createLegend(pos, legendfuncs.legendText(pos), legendfuncs.legendHref(pos))
		@$el.append(legend)


	appendTo:($target)->
		@$el.appendTo($target)

	getLength: ()->
		return @num

	addSlider:(slider, vpos)->
		slider.appendTo(@$el)
		slider.css("top", 220) if vpos
		slider.on "destroy", @onSliderDestroy
		@num = @num + 1



	onSliderDestroy:(slider)=>
		@num = @num - 1
		if @$el.children('.tm-slider').length == 0
			@destroy()

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



class HorizontalGroup
	constructor: (pos,legendfuncs)->
		_.extend(this, Backbone.Events)
		@vgroups = {}
		@$el = $("<div class='tm-hgroup'/>").data("pos", pos)
		# holder is to make shift possible
		@$holder = $("<div class='tm-hg-holder'/>").appendTo(@$el)
		@pos = pos
		@epoch = pos
		@setSpan(0)
		[@legendText,@legendHref] = [legendfuncs.legendText,legendfuncs.legendHref]
		
		# DEBUG
		#@$el.attr('title',"Pos:#{@pos}, Epoch:#{@epoch}, Span:#{@span}")
	
	appendTo:($target)->
		@$el.appendTo($target)

	setPos:(pos)->
		@pos = pos
		@$el.data("pos",pos)
		# DEBUG
		#@$el.attr('title',"Pos:#{@pos}, Epoch:#{@epoch}, Span:#{@span}")
		@$holder.animate({left: (@epoch - @pos)*TimelineView.EntryWidth},{queue:false})

	getLeft:()->
		return parseInt(@$el.position().left)+parseInt(@$holder.css("left"))

	getLength:(pos)->
		return -1 if !@vgroups[pos]
		return @vgroups[pos].getLength()
	
	setSpan:(span)->
		if @span != span
			@$el.animate({width: span*TimelineView.EntryWidth},{queue:false})
		@span = span
		# DEBUG
		#@$el.attr('title',"Pos:#{@pos}, Epoch:#{@epoch}, Span:#{@span}")
	
	prepareVGroup:(pos)->
		if !@vgroups[pos]
			@vgroups[pos] = new VerticalGroup(pos,{legendText:@legendText, legendHref:@legendHref})
			@vgroups[pos].on "destroy", @onVGroupDestroy
			@vgroups[pos].appendTo(@$holder)
			@setSpan(@span + 1)

		return @vgroups[pos]

	addSlider:(slider,pos, vpos)->
		vgroup = @prepareVGroup(pos)
		vgroup.addSlider(slider,vpos)
		vgroup.css("left","#{(slider.pos-@epoch)*TimelineView.EntryWidth}px")
	
	appendBulk:(elements, shift)->
		console.log("shift:#{shift}")
		for element in elements
			@$holder.append(element)
			$(element).css("left", parseInt(element.css("left"))+shift*TimelineView.EntryWidth)
			$(element).data("vgroup").on "destroy", @onVGroupDestroy

		@setSpan(@span + elements.length)

	collapse:(startpos)->
		
		elements = []
		@$holder.children('.tm-vgroup').each (index,element)=>
			return if startpos? and $(element).data("vgroup").pos < startpos
			$(element).data("vgroup").off "destroy", @onVGroupDestroy
			$(element).detach()
			elements.push($(element))

		@setSpan(@$holder.children('.tm-vgroup').length)

		return elements
	
	onVGroupDestroy:(vgroup)=>
		delete @vgroups[vgroup.pos]
		@setSpan(@$holder.children('.tm-vgroup').length)
	
	destroy:()->
		@$el.remove()
		



# TimelineView
# =====================================================
# A **TimelineView** represents an overlapping page regarding a specific time scale.
#
# Normally, A [`TimelineController`](#section-TimelineController) holds layers of `TimelineView`s on a designated block on the document.
#
#	* Initially, a `TimelineView` takes a collection reference and fetches its desired set of entries from the server and fills them. 
#
# * Upon an *entryDateChange* event from a [`TimelineEntrySlider`](section-#TimelineEntrySlider), the view tries to re-position the invalidated `TimelineEntryView` into a matching `TimelineEntrySlider` if available. 
# 
# 	If none of the existing `TimelineEntrySlider` held in the view matches the position, create new slider and attch the entry view on it.
#
class TimelineView
	@EntryWidth: 210

	constructor:(@collection)->

		_.extend(this, Backbone.Events)
		@sliders = [{},{}]
		@groups = {}
		@collection.on("add", @onEntryAdd)
		@$el = $("<div class='timeline-view'></div>")
		@setStart(@epoch())
		# if @collection is already loaded somehow
		@collection.each (entry)=>
			@drawEntry(entry)
	
	getWidth:()->
		return if @$el.parent() then @$el.parent().width() else @$el.width()

	
	fetch:(options)->
		@collection.fetch(options)

	appendTo:($target)->
		@$el.appendTo($target) if $target

	show:()->
		@$el.show()

	hide:()->
		@$el.hide()
	
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
			@$el.append(group.$el)
	
	prepareGroup:(pos, vpos)->

		if @groups[pos]
			console.log('do nothing')
			#throw "pos already occupied, which shouldn't happen"
		# [pos-1] [pos+1]: merge to both left and right
		else if @groups[pos-1] && @groups[pos+1]
			console.log("merged to left-right")
			# move right elements to left
			@groups[pos-1].appendBulk(@groups[pos+1].collapse(), @groups[pos-1].span+1)
			# clear right side, as we won't need it any more
			oldRight = @groups[pos+1]
			@groups[pos] = @groups[pos-1]
			i = pos + 1
			while @groups[i] == oldRight
				@groups[i] = @groups[pos-1]
				i++
			oldRight.destroy()
		else if @groups[pos-1] # [pos-1] [pos+2] merge to left
			console.log("merged to left")
			@groups[pos] = @groups[pos-1]
			#@groups[pos].setSpan(@groups[pos].span+1)
		else if @groups[pos+1] # merge to right
			console.log("merged to right")
			@groups[pos] = @groups[pos+1]
			@groups[pos].setPos(pos)
			console.log(vpos)
			#@groups[pos].setSpan(@groups[pos].span+1)

		else # none exists nearby
			@groups[pos] = new HorizontalGroup(pos, {legendText:@legendText, legendHref:@legendHref})
			@addGroup(@groups[pos])

		return @groups[pos]
	
	
	# When a slider is removed, we can compress space between sliders in between. 
	onSliderDestroy:(slider)=>
		pos = slider.pos

		return if @groups[pos].getLength(pos)  > 0

		if !@groups[pos]
			throw "group of pos(#{pos}) doesn't exist ()"
		else if @groups[pos-1] && @groups[pos+1] # split into two
			console.log('split')
			leftGroup = @groups[pos-1]
			# create new for right
			rightGroup = new HorizontalGroup(pos+1,{legendText:@legendText, legendHref:@legendHref})

			@addGroup(rightGroup)
			# move some from left to right [] [] x [] [] (span:5->pos-epoch) pos-1 
			rightGroup.appendBulk(leftGroup.collapse(pos+1), -(leftGroup.span+1))#pos+1-leftGroup.epoch)

		else if @groups[pos-1]
			# set span
			console.log('right removal')
			#@groups[pos-1].setSpan(@groups[pos-1].span-1)

		else if @groups[pos+1]
			console.log('left removal')
			@groups[pos+1].setPos(pos+1)
			#@groups[pos+1].setSpan(@groups[pos+1].span-1)
		else # actually remove 
			console.log('self removal')
			@groups[pos].destroy()

		delete @groups[pos]


	addSlider: (slider,pos,vpos)->
		group = @prepareGroup(pos,vpos)
		console.log("slider added at #{pos},#{vpos}")
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

	getVpos: (entry)->
		pid = entry.get("politician_id")
		if pid == @collection.pol1._id
			return 0
		else if pid == @collection.pol2._id
			return 1
		return 2
	
	drawEntry: (entry)->
		pos = @calcPosition(entry.get("posted_at"))
		vpos = @getVpos(entry)
		slider = @sliders[vpos][pos]
		if !slider
			slider = new TimelineEntrySlider({pos:pos,vpos:vpos})
			@addSlider(slider, pos, vpos)

		view = new TimelineEntryView({model:entry})
		slider.addEntry(view)

	onEntryAdd:(entry)=>
		@drawEntry(entry)
		@setStart(@epoch()) if !@startSet
		
	onEntryRemove:(slider, entryView, entry)=>
		if slider.isEmpty()
			@removeSlider(slider)
	
	onEntryDateChange:(slider, entryView, entry)=>
		vpos = @getVpos(entry)
		pos = @calcPosition(entry.get('posted_at'))
		newSlider = @sliders[vpos][pos] if @sliders[vpos]
		if newSlider != slider
			slider.removeEntry(entryView)
			if slider.isEmpty()
				@removeSlider(slider)
			if !newSlider
				newSlider = new TimelineEntrySlider({pos:pos,vpos:vpos})
				@addSlider(newSlider, pos, vpos)
			newSlider.addEntry(entryView)

	# You can let the view updated automatically.
	startAutoUpdate: ()->
		@update()
		@timer = setInterval ()=>
			@update()
		, 10000

	setStart:(pos)->
		newPos = null
		if !@groups[pos]
			for p,group of @groups
				if group.pos <= pos && pos < group.pos + group.span
					newPos = group.pos
					break
		
		return if !@groups[pos] && !newPos? # bad case
		@startSet = true
		@$el.css("left", -@groups[pos].getLeft())#+@getWidth()/2)

	setCenterAt:(entry)->
		console.log('')

	stopAutoUpdate: ()->
		clearTimeout(@timer)
	
	update: (params)->
		@collection.update(params)

	getLeft:()->
		return -parseInt(@$el.css("left"))

	setLeft:(left)->
		@moving = true
		@$el.animate({left:-left},{complete:()=>
			@moving = false
		,queue:false})

	getRight:()->
		return @getWidth()-parseInt(@$el.css("left"))

	setRight:(right)->
		@moving = true
		@$el.animate({left:-right+@getWidth()},{complete:()=>
			@moving = false
		,queue:false})

	getCenter:()->
		return -parseInt(@$el.css("left"))+@getWidth()/2

	setCenter:(center)->
		@moving = true
		@$el.animate({left:-center+@getWidth()/2},{complete:()=>
			@moving = false
		,queue:false})


	getPrev:()->
		curPos = @getCenter()
		
		found = false
		nearest = 0

		for p, group of @groups
			lmost = group.getLeft() + TimelineView.EntryWidth/2
			rmost = lmost + (group.span-1)*TimelineView.EntryWidth
			console.log("prev",lmost,curPos, rmost)
			if lmost >= curPos # x []
				continue

			# lmost < curPos
			if  curPos <= rmost  #  100 (150 200 250 300) 300
				left = lmost + (Math.ceil((curPos-lmost)/TimelineView.EntryWidth)-1)*TimelineView.EntryWidth
				console.log('prev','in:' + left)
				return left# - @getWidth()/2
			else    # ] x
				if nearest < rmost || !found
					nearest = rmost
					found = true

		if found
			console.log('prev','near:' + (nearest))# - @getWidth()/2))
			return nearest# - @getWidth()/2
		
		console.log('prev','not found')
		return null

	
	getNext:()->
		curPos = @getCenter()
		
		found = false
		nearest = 0

		for p, group of @groups
			lmost = group.getLeft() + TimelineView.EntryWidth/2
			rmost = lmost +  (group.span-1)*TimelineView.EntryWidth

			console.log("next",lmost,curPos,rmost)
			if rmost <= curPos #  [] x
				continue

			# rmost > curPos   [x] or  x []
			if  curPos >= lmost  #  [x]
				left = lmost+(Math.ceil((curPos-lmost)/TimelineView.EntryWidth)+1)*TimelineView.EntryWidth
				console.log('next','in:' + left)
				return left
			else   #  x [
				if nearest > lmost || !found
					nearest = lmost
					found = true
		if found
			console.log('next','near:' + (nearest))# - @getWidth()/2))
			return nearest# - @getWidth()/2
		
		console.log('next','not found')
		return null
	
	
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
			console.log(null)
			return null

		center = (lbound + rbound)/2

		console.log(lbound, center, rbound)
		return [lbound,center,rbound]

	
	goLeft: ()->
		return if @moving
		lbound = @getBounds()[0]
		
		left = @getLeft()

		if left-TimelineView.EntryWidth <= lbound
			console.log("left to: bound #{lbound}")
			@setLeft(lbound)
		else
			console.log("left to: #{left-TimelineView.EntryWidth}")
			@setLeft(left-TimelineView.EntryWidth)


		#newPos =  @getPrev()
		#return if !newPos?
		#@setCenter(newPos)
		
	goRight: ()->
		return if @moving
		rbound = @getBounds()[2]
		right = @getRight()
		if right+TimelineView.EntryWidth >= rbound
			console.log("right to: bound #{rbound}")
			@setRight(rbound)
		else
			console.log("right to: #{right+TimelineView.EntryWidth}")
			@setRight(right+TimelineView.EntryWidth)

		

class TermView extends TimelineView
	@unit : "term"

	constructor: (@collection)->
		super(@collection)
		
	fetch: (startTerm, endTerm)->
		options =
			start: startTerm
			end:   endTerm
			unit:  'term'
		
		super(options)

	calcPosition: (date)->
		#year = new Date(date).getFullYear()
		term = parseInt((new Date(date).getFullYear()-1936)/4)
	
	legendText: (pos)->
		year = parseInt(pos*4)+1936
		"#{year}년~#{year+3}년"
	
	legendHref: (pos)->
		year = parseInt(pos*4)+1936
		"#year/#{year}"

	epoch: ()->
		# TODO:일단 16대부터
		return 16


	setStart:(pos)->
		console.log("setStart #{pos}T")
		super(pos)



class YearView extends TimelineView
	@unit : "year"

	calcPosition: (date)->
		d = new Date(date)
		year = d.getFullYear()
		return year
	
	legendText: (pos)->
		return "#{pos}년"
	
	legendHref: (pos)->
		return "#quarter/#{pos}"
	
	epoch: ()->
		today = new Date()
		return today.getFullYear()-4

	setStart:(pos)->
		console.log("setStart #{pos}Y")
		super(pos)


class QuarterView extends TimelineView
	@unit : "quarter"

	calcPosition: (date)->
		d = new Date(date)
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
	
	setStart: (pos)->
		console.log("setStart #{pos}Q")
		if typeof pos == 'object'
			pos = pos.year *4 + pos.quarter
		super(pos)



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
		d = new Date(date)
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
	
	setStart: (pos)->
		console.log("setStart #{pos}M")
		if typeof pos == 'object'
			pos = pos.year *12 + pos.month
		super(pos)

class WeekView extends TimelineView
	@unit : "week"

	calcPosition: (date)->
		d = new Date(date)
		year = d.getFullYear()
		week = parseInt(getDayOfYear(d)/7)
		return year*53+week
	
	legendText: (pos)->
		year = parseInt(pos/53)
		week = (pos % 53)
		console.log(year,week)
		date = new Date(getFirstDayOfYear(year).getTime()+week*7*24*60*60*1000)
		endDate = new Date(getFirstDayOfYear(year).getTime()+(week*7+6)*24*60*60*1000)
		
		return "#{date.getFullYear()}.#{date.getMonth()+1}.#{date.getDate()}~#{endDate.getFullYear()}.#{endDate.getMonth()+1}.#{endDate.getDate()}"
	
	legendHref: (pos)->
		console.log('href'+pos)
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
	
	setStart: (pos)->
		console.log("setStart #{pos}w")
		if typeof pos == 'object'
			week = parseInt(getDayOfYear(@getDefaultDate(pos.year,pos.month))/7)
			pos = parseInt(pos.year)*53 + week
			
		console.log("epoch",@epoch(),pos)
		super(pos)


class DayView extends TimelineView
	@unit : "day"

	calcPosition: (date)->
		d = new Date(date)
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
	
	setStart: (pos)->
		console.log("setStart #{pos}")
		if typeof pos == 'object'
			d = new Date(pos.year,pos.month-1, pos.day, 0,0,0)
			dayofyear = getDayOfYear(d)
			pos = pos.year *366 + dayofyear
		super(pos)



Views =
	all:     TermView
	year:    YearView
	quarter: QuarterView
	month:   MonthView
	week:    WeekView
	day:     DayView


# TimelineController
# =====================================================
# The **TimelineController** keeps all the timeline collection used in its sub-components.
#
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
	
		

		# Growl
		@collection.on "add", (model)->
			console.log('added')
			$.gritter.add({title:'추가',text:"항목(#{model.id})이 추가되었습니다."})
		@collection.on "remove", (model)->
			console.log('removed')
			$.gritter.add({title:'삭제',text:"항목(#{model.id})이 삭제되었습니다."})
		@collection.on "change", (model)->
			console.log('changed')
			$.gritter.add({title:'수정',text:"항목(#{model.id})이 수정되었습니다."})

		@views = {}
		# Default scale view (year) is created on object creation
		allView = new Views["all"](@collection )
		@currentScale = @views["all"] = allView
		
		# bootstrap initial data
		if options.entries
			for entry in options.entries
				@collection.add(entry)


	
	# `changeScale` takes name string of the new scale value (*year*, *month*, ...)
	changeScale: (scaleName, start)->
		oldScale = @currentScale
		if @views[scaleName]
			@currentScale = @views[scaleName]
		else
			@currentScale = @views[scaleName] = new Views[scaleName](@collection)
			
			@currentScale.appendTo(@$el)

		# Transition between oldScale and currentScale (may simple be a `show()` and a `hide()`)
		if oldScale != @currentScale
			oldScale.stopAutoUpdate() if @autoUpdate
			oldScale.hide()

		@currentScale.setStart(start) if start?
		@currentScale.show()
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

	# You can let the timeline updated automatically.
	startAutoUpdate: ()->
		@autoUpdate = true
		@currentScale.startAutoUpdate()

	stopAutoUpdate: ()->
		@autoUpdate = false
		@currentScale.stopAutoUpdate()
	
	addEntry: (model)->
		@collection.add(model)
	
	@getForm: (pol)->
		return TimelineEntryView.createForm(null,pol)
	

# And finally, make sure it is available outside the file.
modules.TimelineController = TimelineController
