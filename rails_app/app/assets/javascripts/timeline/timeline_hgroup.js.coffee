VerticalGroup = modules.TimelineVerticalGroup

class HorizontalGroup
	constructor: (pos,legendfuncs)->
		_.extend(this, Backbone.Events)
		@vgroups = {}
		@$el = $("<div class='tm-hgroup'/>").data("pos", pos)#.css({left:'0px','background-color':'red'}).fadeTo(0,0.5)
		# holder is to make shift possible
		@$holder = $("<div class='tm-hg-holder'/>").appendTo(@$el)#.css('background-color','blue').fadeTo(0,0.5)
		@$canvas = $("<div class='timeline-canvas'></div>").appendTo(@$el).css("left",-50)
		@$paper = Raphael(@$canvas.get(0), 3000,300)

		@epoch = pos
		@setPos(pos)
		@setSpan(0)
		[@legendText,@legendHref] = [legendfuncs.legendText,legendfuncs.legendHref]
		
		# DEBUG
		#@$el.attr('title',"Pos:#{@pos}, Epoch:#{@epoch}, Span:#{@span}")
		@$el.click ()=>
			@getLeft()

	appendTo:($target)->
		@$el.appendTo($target)
		@trigger("dimensionChange")

	setPos:(pos)->
		return if @pos == pos
		@$holder.animate({left: (@epoch - pos)*modules.TimelineView.EntryWidth},{queue:false})
		@pos = pos
		@$el.data("pos",pos)


	getLeft:()->
		if @$el.parent()
			return @$el.offset().left - @$el.parent().offset().left - 100 #-100 for margin	
		else
			console.warn('no parent')
			return 0

	getLength:(pos)->
		return -1 if !@vgroups[pos]
		return @vgroups[pos].getLength()
	
	setSpan:(span)->
		return if @span == span
		
		#@$el.animate({width: span*TimelineView.EntryWidth},{queue:false})
		@$el.css({width: span*modules.TimelineView.EntryWidth})
		@$paper.clear()

		@$paper.path("M#{0},200L#{span*modules.TimelineView.EntryWidth+100},200").attr({stroke:'#000',fill:'#fff',"stroke-dasharray":". "})
		@$paper.path("M50,200L#{span*modules.TimelineView.EntryWidth+50},200").attr({stroke:'#555',fill:'#fff'})
		@span = span
		@trigger("dimensionChange")
			
		# DEBUG
		#@$el.attr('title',"Pos:#{@pos}, Epoch:#{@epoch}, Span:#{@span}")
	
	prepareVGroup:(pos)->
		if !@vgroups[pos]
			console.log('prepareVGroup:', "@vgroups[#{pos}] date:#{@legendText(@pos)} doesn't exist, creating")
			@vgroups[pos] = new VerticalGroup(pos,{legendText:@legendText, legendHref:@legendHref})
			@vgroups[pos].on "destroy", @onVGroupDestroy
			@vgroups[pos].appendTo(@$holder)
			@vgroups[pos].css("left","#{(pos-@epoch)*modules.TimelineView.EntryWidth}px")
		else
			console.log('prepareVGroup:', "@vgroups[#{pos}] exists")

		return @vgroups[pos]

	addBillView:(billView,pos)->
		vgroup = @prepareVGroup(pos)
		vgroup.addBillView(billView)
		# set proper positon for vgroup
		@setSpan(@$holder.children('.tm-vgroup').length)

	addSlider:(slider,pos, vpos)->
		vgroup = @prepareVGroup(pos)
		vgroup.addSlider(slider,vpos)
		@setSpan(@$holder.children('.tm-vgroup').length)
	
	appendBulk:(vgroups, shift)->
		console.log('appendBulk', "appending #{vgroups.length} vgroups to hgroup[#{@pos}] (date:#{@legendText(@pos)} shift:#{shift})")
		for element in vgroups
			vgroup = $(element).data("vgroup")
			if @vgroups[vgroup.pos]
				thrown "shouldn't happen"

			console.log('appendBulk', "added vgroup at #{vgroup.pos}")
			@vgroups[vgroup.pos] = vgroup

			$(element).css("left", parseInt(element.css("left"))+shift*modules.TimelineView.EntryWidth)
			vgroup.on "destroy", @onVGroupDestroy
			element.appendTo(@$holder)

		@setSpan(@$holder.children('.tm-vgroup').length)

	collapse:(startpos)->
		
		console.log('collapse', "collapsing hgroup[#{@pos}] date:#{@legendText(@pos)} #{if startpos? then "from #{startpos}" else ""}")
		vgroups = []
		@$holder.children('.tm-vgroup').each (index,element)=>
			return if startpos? and $(element).data("vgroup").pos < startpos
			$(element).data("vgroup").off "destroy", @onVGroupDestroy
			$(element).css("left", "#{parseInt($(element).css("left"))+(@epoch-@pos)*modules.TimelineView.EntryWidth}px")
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

modules.TimelineHorizontalGroup = HorizontalGroup
