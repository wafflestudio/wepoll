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



# TimelineEntryCollection
# =====================================================
# **TimelineEntryCollection** is the backbone collection for the model `TimelineEntry` refering to the resource `/timeline_entries`
class TimelineEntryCollection extends Backbone.Collection
	model:TimelineEntry
	url: '/timeline_entries'
	initialize:()->
		
	# Update to a collection can be made with extra parameters.
	update: (params)->
		latest = new Date("1000-01-01") # let's assume some time
		updated = new TimelineEntryCollection()

		this.each (model)->
			date = new Date(model.get("updated_at"))
			latest = date if latest.getTime() < date.getTime()

		params ?= {}
		params.from = latest.toISOString()
		
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
				<p>Date: #{model.escape('posted_at')}</p>
				<p><a href='#'>Edit</a></p>
			</div>"
		element = $(template)
		element.find('a').click (evt)=>
			$(element).trigger('changeMode')
			return false
		return element
		
	# The `createForm` class method definition is exposed for new/edit form creation.
	# `createForm` will return a jquery object carrying a DOM node filled with the form used to create/update a `TimelineEntry`.
	# the returned object exposes *save* event to listen to.
	@createForm: (model)->
		template = "<form method='post' action='/timeline_entries/#{if model then model.id else 'new'}' accept-charset='UTF-8'>
				<input type='hidden' name='_method' value='#{if model then 'put' else 'post'}'/>
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
			edit.css('display','none')

			view.on "changeMode", ()=>
				view.css('display','none')
				edit.css('display','')
			edit.on "save", ()=>
				edit.css('display','none')
				view.css('display', '')

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


createLegend = (value, text, href)->
	$("<div class='tm-legend'><a href='#{href}'>#{text}</a></div>")

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
		@$el = $("<div class='tm-slider'>Slider</div>")
		legend = createLegend(options.position, options.legend, options.href)
		@$el.append(legend)

	addEntry:(view)->
		view.appendTo(@$el)
		view.on("dateChange", @onEntryDateChange)
		view.on("destroy", @onEntryDestroy)
		
	removeEntry:(view)->
		view.off("dateChange", @onEntryDateChange)
		view.off("destroy", @onEntryDestroy)
		view.detach()

	appendTo:($target)->
		@$el.appendTo($target)
	
	onEntryDateChange:(view,model)=>
		@trigger("entryDateChange", this, view, model)
	
	onEntryDestroy:(view,model)=>
		@trigger("entryDestroy", this, view, model)
	
	isEmpty: ()->
		return @$el.children(".tm-entry").length == 0

	destroy:()->
		@$el.remove()
	
	css:(hash)->
		@$el.css(hash)
	
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
class TimelineView extends Backbone.Events
	constructor:(@collection)->
		@sliders = {}
		@collection.on("add", @onEntryAdd)
		@$el = $("<div class='timeline-view'></div>")
		@setStart(@epoch())
		# if @collection is already loaded somehow
		@collection.each (entry)=>
			@drawEntry(entry)
	
	fetch:(options)->
		@collection.fetch(options)

	appendTo:($target)->
		@$el.appendTo($target) if $target

	show:()->
		@$el.show()

	hide:()->
		@$el.hide()

	addSlider: (slider,pos)->
		slider.appendTo(@$el)
		slider.on("entryDateChange", @onEntryDateChange)
		slider.on("entryDestroy", @onEntryRemove)
		@sliders[pos] = slider

	removeSlider: (slider)->
		slider.off("entryDateChange", @onEntryDateChange)
		slider.off("entryDestroy", @onEntryRemove)
		slider.destroy()
		for pos,sl of @sliders
			delete @sliders[pos] if sl == slider
	
	drawEntry: (entry)->
		pos = @calcPosition(entry.get("posted_at"))
		slider = @sliders[pos]
		if !slider
			slider = new TimelineEntrySlider({pos:pos,legend:@legendText(pos),href:@legendHref(pos)})
			@addSlider(slider, pos)
			slider.css({"left":"#{(pos-@epoch())*210}px"})

		view = new TimelineEntryView({model:entry})
		slider.addEntry(view)

	onEntryAdd:(entry)=>
		@drawEntry(entry)
		
	onEntryRemove:(slider, entryView, entry)=>
		if slider.isEmpty()
			@removeSlider(slider)
	
	onEntryDateChange:(slider, entryView, entry)=>
		pos = @calcPosition(entry.get('posted_at'))
		newSlider = @sliders[pos]
		if newSlider != slider
			slider.removeEntry(entryView)
			if slider.isEmpty()
				@removeSlider(slider)
			if !newSlider
				newSlider = new TimelineEntrySlider({legend:pos})
				@addSlider(newSlider, pos)
				newSlider.css({"left":"#{(pos-@epoch())*210}px"})
			newSlider.addEntry(entryView)

	# You can let the view updated automatically.
	startAutoUpdate: ()->
		@update()
		@timer = setInterval ()=>
			@update()
		, 10000

	stopAutoUpdate: ()->
		clearTimeout(@timer)
	
	update: (params)->
		@collection.update(params)

	goLeft: ()->
		return if @moving
		left = @$el.css("left")
		left = if left == 'auto' then 0 else left
		@$el.animate({left:parseInt(left) - 210},{easing:'linear',complete:()=>
			@moving = false
		})
		@moving = true

	goRight: ()->
		return if @moving
		left = @$el.css("left")
		left = if left == 'auto' then 0 else left
		@$el.animate({left:parseInt(left) + 210},{easing:'linear',complete:()=>
			@moving = false
		})
		@moving = true

		

class AllView extends TimelineView
	@scale : "all"
	@unit : "year"

	constructor: (@collection)->
		super(@collection)
		
	fetch: (startYear, endYear)->
		options =
			scope: 'all'
			start: startYear
			end:   endYear
			unit:  'year'
		
		super(options)

	calcPosition: (date)->
		year = new Date(date).getFullYear()
	
	legendText: (pos)->
		pos + "년"
	
	legendHref: (pos)->
		"#year/#{pos}"

	epoch: ()->
		# TODO: 4 is selected as the number of entries can be shown on screen
		return new Date().getFullYear()-4
	
	setStart: (year)->
		@$el.css("left", (year-@epoch())*210)



class YearView extends TimelineView
	@scale : "year"
	@unit : "quarter"

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
		return "#month/#{year}/#{month}"
	
	epoch: ()->
		today = new Date()
		return today.getFullYear()*12 + today.getMonth()-4

	setStart: (pos)->
		year = parseInt(pos/12)
		month = pos %12
		console.log("left:" + -(year*12+month-@epoch())*210)
		@$el.css("left", -(year*12+month-@epoch())*210)

class QuarterView extends TimelineView

class MonthView extends TimelineView

class WeekView extends TimelineView

class DayView extends TimelineView


Views =
	all:     AllView
	year:    YearView
	quarter: QuarterView
	month:   MonthView
	week:    WeekView



# TimelineController
# =====================================================
# The **TimelineController** keeps all the timeline collection used in its sub-components.
#
class TimelineController
	constructor: ()->
		# We need to keep @collection and @views
		@collection = new TimelineEntryCollection()
		@collection.on "add", (model)->
			$.gritter.add({title:'추가',text:"항목(#{model.id})이 추가되었습니다."})
		@collection.on "remove", (model)->
			$.gritter.add({title:'삭제',text:"항목(#{model.id})이 삭제되었습니다."})
		
		@collection.on "change", (model)->
			$.gritter.add({title:'수정',text:"항목(#{model.id})이 수정되었습니다."})

		@views = {}
		# Default scale view (year) is created on object creation
		allView = new Views["all"](@collection)
		@currentScale = @views["all"] = allView
	
	# `changeScale` takes name string of the new scale value (*year*, *month*, ...)
	changeScale: (scaleName, start)->
		oldScale = @currentScale
		if @views[scaleName]
			@currentScale = @views[scaleName]
		else
			@currentScale = new Views[scaleName](@collection)
			@currentScale.appendTo(@$el)

		# Transition between oldScale and currentScale (may simple be a `show()` and a `hide()`)
		if oldScale
			oldScale.stopAutoUpdate() if @autoUpdate
			oldScale.hide()

		@currentScale.setStart(start) if typeof start != 'undefined'
		@currentScale.show()
		@currentScale.startAutoUpdate() if @autoUpdate
	
	# The timeline will be visible after appending it to an html element (argument is preferably a referencing jquery object).
	appendTo: ($el)->
		
		@$el = $el
		for key,view of @views
			view.appendTo(@$el)
		$(@$el).mousewheel (e, delta)=>
			e.preventDefault()
			if delta < -0.4
				@currentScale.goLeft()
			else if delta > 0.4
				@currentScale.goRight()

	# You can let the timeline updated automatically.
	startAutoUpdate: ()->
		@autoUpdate = true
		@currentScale.startAutoUpdate()

	stopAutoUpdate: ()->
		@autoUpdate = false
		@currentScale.stopAutoUpdate()
	
	addEntry: (model)->
		@collection.add(model)
	
	@getForm: ()->
		return TimelineEntryView.createForm()
	

# And finally, make sure it is available outside the file.
modules.TimelineController = TimelineController
