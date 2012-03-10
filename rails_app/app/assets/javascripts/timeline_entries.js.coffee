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

#data: data.title, data.create_at, data.image, data.description
loadPreview = (url, onload)->
	#$.ajax  url: '/api/article_parse', data: 'url='+encodeURIComponent(url), type: 'POST', dataType: 'json', success:
	#	(data)->
	#		onload(data)

createView = (model)->
	template = "<div class='tm-entry-view'>
			<div class='tm-entry-numlike'>공감 #{model.get('like')}</div>
			<div class='tm-entry-numreply'>댓글0</div>
			<div class='clear'></div>
			<div class='tm-entry-content'>
			<span>#{model.escape('title')}</span>
			<!--<p>링크: #{model.escape('url')}</p>-->
			<!--<p>날짜: #{formatDate(new Date(model.escape('posted_at')))}</p>-->
			<!--<p>코멘트: #{model.escape('comment')}<p>-->
			<p>#{model.escape('tag_text')}</p>
			#{if TimelineController.displayEdit then "<p><a href='/timeline_entries/show?politician_id=#{model.escape('politician_id')}'>Edit</a></p>" else ""}
			</div>
		</div>"
	element = $(template)
	element.find('a').click (evt)->
		url = "/timeline_entries/" + model.id + "/edit"
		$.colorbox {href:url,width:'800px', height:'640px',onComplete: ()->
			activateTimelineEntryForm()
			$('.tm-entry-form').submit ()->
				submitTimelineEntryForm(this, model.id)
				element.html(createView(model))
				$.colorbox.close()
				return false
		}

		return false

	#loadPreview model.get('url'), (data)->
	if model.get('aux_url')
		image = $("<img class='preview-img'/>").attr 'src', model.get('aux_url').load ()=>
			image.prependTo($(element).find(".tm-entry-content"))
			
	return element

			

###
	timeout = 0

	url_input = $(element).find("input[name='url']")
	
	load = ()->
		$.ajax  url: '/api/article_parse', data: 'url='+encodeURIComponent($(url_input).val()), type: 'POST', dataType: 'json', success:
			(data)->
				$(element).find("input[name='title']").val(data.title)
				#$(element).find("input[name='posted_at']").val(new Date(data.created_at)) if new Date(data.created_at)
				#$(element).find("#preview-img").empty().append(data.image ? "<img src='" + data.image + "'/>" : "[이미지없음]" )
				$(element).find("textarea[name='comment']").val(data.description)

	url_input.keydown ()->
		if timeout
			clearTimeout(timeout)

		timeout = setTimeout( ()->
			timeout = null
			load($(url_input).val())
		,1000)

	.focusout ()->
			load($(url_input).val())

		
	# The model is saved on clicking the submit button.
	$(element).find('input[type="submit"]').click (evt)=>
		attrs = {}
		$(element).find('[name!="_method"]').each (index, el)=>
			name = $(el).attr('name')
			if name == 'posted_at'
				attrs[name] = new Date($(el).val()).toISOString()
			else
				attrs[name] = $(el).val()
		# If the save was successful, the tangled element emits a *save* event for others to get notified.
		model.save(attrs, {success: ()->
			$(element).trigger("save", [model])
		,error: ()->
			console.log("error while saving model")
		})
		# Returning false is required to avoid actually opening a page.
		return false

	return element

###

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
			
	
	initialize: ()->
		@model = if @options.model then @options.model else new TimelineEntry()
		@model.on "change", @onChange
		@model.on "remove", @onRemove
		@model.on("change:posted_at", @onDateChange)
		@render()
	
	render: ()->
		if !@hasEl
			view = createView(@model)
			element = $("<div class='tm-entry' data-id='" + @model.id+ "'/>").append(view)
			

			delete_link = $("<a class='tm-entry-delete' href='#'>삭제</a>").click ()=>
				@model.destroy() if confirm("정말로 삭제하시겠습니까?")

			#edit.append(delete_link)
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
		
	removeEntryView:(view)->
		view.off("dateChange", @onEntryDateChange)
		view.off("destroy", @onEntryDestroy)
		view.detach()
		@nav.setProperties({num:@$holder.children('.tm-entry').length})

		#@showPage(@$holder.find('.tm-entry').length)

	showPage: (page)=>
		@$holder.find('.tm-entry').each (index,el)=>
			if index == page then $(el).fadeIn(400).show() else $(el).fadeOut(400).hide()

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
		slider.css("top", 250) if vpos
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
		@$canvas = $("<div class='timeline-canvas'></div>").appendTo(@$el).css("left",-50)
		@$paper = Raphael(@$canvas.get(0), 3000,300)

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
		return parseInt(@$el.position().left)

	getLength:(pos)->
		return -1 if !@vgroups[pos]
		return @vgroups[pos].getLength()
	
	setSpan:(span)->
		if @span != span
			#@$el.animate({width: span*TimelineView.EntryWidth},{queue:false})
			@$el.css({width: span*TimelineView.EntryWidth})
			@$paper.clear()

			@$paper.path("M#{0},200L#{span*TimelineView.EntryWidth+100},200").attr({stroke:'#000',fill:'#fff',"stroke-dasharray":". "})
			@$paper.path("M50,200L#{span*TimelineView.EntryWidth+50},200").attr({stroke:'#555',fill:'#fff'})
			
		@span = span

		# DEBUG
		#@$el.attr('title',"Pos:#{@pos}, Epoch:#{@epoch}, Span:#{@span}")
	
	prepareVGroup:(pos)->
		if !@vgroups[pos]
			console.log('prepareVGroup:', "@vgroups[#{pos}] doesn't exist, creating")
			@vgroups[pos] = new VerticalGroup(pos,{legendText:@legendText, legendHref:@legendHref})
			@vgroups[pos].on "destroy", @onVGroupDestroy
			@vgroups[pos].appendTo(@$holder)
		else
			console.log('prepareVGroup:', "@vgroups[#{pos}] exists")

		return @vgroups[pos]

	addSlider:(slider,pos, vpos)->
		vgroup = @prepareVGroup(pos)
		vgroup.addSlider(slider,vpos)
		vgroup.css("left","#{(slider.pos-@epoch)*TimelineView.EntryWidth}px")

		@setSpan(@$holder.children('.tm-vgroup').length)
	
	appendBulk:(vgroups, shift)->
		console.log('appendBulk', "appending #{vgroups.length} vgroups to hgroup[#{@pos}] (shift:#{shift})")
		for element in vgroups
			vgroup = $(element).data("vgroup")
			if @vgroups[vgroup.pos]
				thrown "shouldn't happen"

			console.log('appendBulk', "added vgroup at #{vgroup.pos}")
			@vgroups[vgroup.pos] = vgroup

			$(element).css("left", parseInt(element.css("left"))+shift*TimelineView.EntryWidth)
			vgroup.on "destroy", @onVGroupDestroy
			element.appendTo(@$holder)

		@setSpan(@$holder.children('.tm-vgroup').length)

	collapse:(startpos)->
		
		console.log('collapse', "collapsing hgroup[#{@pos}] #{if startpos? then "from #{startpos}" else ""}")
		vgroups = []
		@$holder.children('.tm-vgroup').each (index,element)=>
			return if startpos? and $(element).data("vgroup").pos < startpos
			$(element).data("vgroup").off "destroy", @onVGroupDestroy
			$(element).detach()
			vgroups.push($(element))

		@setSpan(@$holder.children('.tm-vgroup').length)

		return vgroups
	
	onVGroupDestroy:(vgroup)=>
		delete @vgroups[vgroup.pos]
		console.log('event',"vgroup at #{vgroup.pos} destroyed")
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
		# if @collection is already loaded somehow
		@collection.each (entry)=>
			@drawEntry(entry)	
		
	
	getWidth:()->
		if !@$el.parent()
			console.log('no parent',@$el.width())
			return @$el.width()
		else if @$el.parent().width()
			console.log('parent',@$el.parent().width())
			return @$el.parent().width()
		else
			console.log('parent but no width',688)
			return 688


	
	fetch:(options)->
		@collection.fetch(options)

	appendTo:($target)->
		@$el.appendTo($target) if $target

	show:()->
		@$el.show()

	hide:()->
		@$el.hide()

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
			@$el.append(group.$el)
	
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
			oldRight.destroy()
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
			@groups[pos].destroy()

		delete @groups[pos]
	
	getVpos: (entry)->
		pid = entry.get("politician_id")
		if pid == @collection.pol1._id
			return 0
		else if pid == @collection.pol2._id
			return 1
		return 2
		
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
			@setX(lcap-left)
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
		if animate
			@moving = true
			
			@$el.animate({left:x},{complete:()=>
				@moving = false
			,queue:false})
		else
			@$el.css("left",x)

	getLeft:()->
		return -parseInt(@$el.css("left"))

	setLeft:(left, animate=false)->
		console.log('setLeft',left)
		if animate
			@moving = true
			
			@$el.animate({left:-left},{complete:()=>
				@moving = false
			,queue:false})
		else
			@$el.css("left",-left)


	getRight:()->
		return @getWidth()-parseInt(@$el.css("left"))

	setRight:(right,animate=false)->
		console.log('setRight',right)
		if animate
			@moving = true
			
			@$el.animate({left:-right+@getWidth()},{complete:()=>
				@moving = false
			,queue:false})
		else
			@$el.css("left",-right+@getWidth())


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
		return [lbound,center,rbound]

	
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
			#console.log('more',rbound-lbound,width)
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

	setStart:(pos, animate = true)->
		#console.log("setStart #{pos}T")
		super(pos, animate)



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
		
	setStart:(pos, animate = true)->
		#console.log("setStart #{pos}Y")
		super(pos, animate)


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
	
	setStart: (pos,animate=true)->
		#console.log("setStart #{pos}Q")
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
	
	setStart: (pos, animate=true)->
		#console.log("setStart #{pos}M")
		if typeof pos == 'object'
			pos = pos.year *12 + pos.month
		super(pos, animate)

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
		#console.log("setStart #{pos}w")
		if typeof pos == 'object'
			week = parseInt(getDayOfYear(@getDefaultDate(pos.year,pos.month))/7)
			pos = parseInt(pos.year)*53 + week
			
		#console.log("epoch",@epoch(),pos)
		super(pos, animate)


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
	
	setStart: (pos, animate=true)->
		#console.log("setStart #{pos}")
		if typeof pos == 'object'
			d = new Date(pos.year,pos.month-1, pos.day, 0,0,0)
			dayofyear = getDayOfYear(d)
			pos = pos.year *366 + dayofyear
		super(pos, animate)



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
	
		
		@views = {}
		# Default scale view (year) is created on object creation
		allView = new Views["year"](@collection)
		@currentScale = @views["year"] = allView
	
		console.log("initial scale is all")

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
		oldScale = @currentScale

		console.log("Scale change to #{scaleName}")
		
		if @views[scaleName]
			@currentScale = @views[scaleName]
		else
			@currentScale = @views[scaleName] = new Views[scaleName](@collection)
			
			@currentScale.appendTo(@$el)

		# Transition between oldScale and currentScale (may simple be a `show()` and a `hide()`)
		if oldScale != @currentScale
			oldScale.stopAutoUpdate() if @autoUpdate
			oldScale.hide()

		@currentScale.setStart((if start? then start else 100000), false)
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
			
		@currentScale.setStart(100000000,false)

		$("<div class='timeline-navigator'></div>").css({left:0,top:165,zIndex:2}).addClass('tm-nav-left').appendTo(@$el).click ()=>
			@currentScale.goLeft()
		$("<div class='timeline-navigator'></div>").css({right:0,top:165,zIndex:2}).addClass('tm-nav-right').appendTo(@$el).click ()=>
			@currentScale.goRight()

		$("<div id='timeline-msg-noentry'>항목이 없습니다.</div>").appendTo(@$el)
		$("#timeline-msg-noentry").hide() if @collection.length > 0


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

	
	

# And finally, make sure it is available outside the file.
modules.TimelineController = TimelineController
$ ->
	$('#link-cancel').live 'click', ->
		$.colorbox.close()
		false
	return
