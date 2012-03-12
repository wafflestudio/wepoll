
formatDate = (d)->
	"#{d.getFullYear()}.#{d.getMonth()+1}.#{d.getDate()}"

createView = (model)->
	template = "<div class='tm-entry-view'>
			<div class='tm-entry-numlike'>공감 #{if model.get('like_count')? then model.get('like_count') else 0}</div>
			<div class='tm-entry-numreply'>댓글0</div>
			<div class='clear'></div>
			<div class='tm-entry-content'>
			<span>#{model.escape('title')}</span>
			<!--<p>링크: #{model.escape('url')}</p>-->
			<!--<p>날짜: #{formatDate(Date.parse(model.get('posted_at')))}</p>-->
			<!--<p>코멘트: #{model.escape('comment')}<p>-->
			<div class='tm-entry-tags'>#{model.escape('tags')}</div>
			#{if modules.TimelineController.displayEdit then "<p><a href='/timeline_entries/show?politician_id=#{model.escape('politician_id')}'>Edit</a></p>" else ""}
			</div>
		</div>"
	element = $(template)
	element.find('a').click (evt)->
		url = "/timeline_entries/" + model.id + "/edit"
		$.colorbox {href:url,width:'800px', height:'660px',onComplete: ()->
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

modules.TimelineEntryView = TimelineEntryView
