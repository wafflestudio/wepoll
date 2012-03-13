
TimelineEntry = modules.TimelineEntry


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
			date = Date.parse(model.get("updated_at"))
			latest = date if latest.getTime() < date.getTime()

		params ?= {}
		params.from = latest.toISOString()
		params.pol1 = @pol1._id if @pol1
		params.pol2 = @pol2._id if @pol2
		
		updated.fetch({ data: $.param(params), success: ()=>
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
					server_ts = Date.parse(entry.get("updated_at"))
					client_ts = Date.parse(entry.get("updated_at"))
					target.set(entry.attributes) if client_ts.getTime() < server_ts.getTime()

			})

modules.TimelineEntryCollection = TimelineEntryCollection
