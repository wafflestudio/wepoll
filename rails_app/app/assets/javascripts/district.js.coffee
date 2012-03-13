# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
# =require jquery.simple_bar_graph
# =require raphael-min
# =require raphael-piechart
# =require raphael-donutchart
# =require jcombox-1.0b.packed
$ () ->
  #  $('.politician-select').jcombox { theme: 'gray' }
  $(".bar-graph").simpleBarGraph {
    animate:true,
    labelPosition:'outside',
    width:167,
    labelWidth:48,
    labelClass:"link-label",
    label:(x,fx) ->
      return Math.round(x)+""
  }

  $(".tab").click () ->
    loadTab $(this)
  $(".selected").click()

loadTab = ($obj) ->
  $(".tab").removeClass "selected"
  $obj.addClass "selected"
  id = $obj.attr 'data-id'
  if (!id)
    return false
  $(".tab-section").hide()
  $tab_section = $("#"+id)
  if ($tab_section.length > 0)
    $tab_section.show()
    return false

  $tab_section = $ '<div class="alpha omega tab-section"></div>'
  $tab_section.attr 'id', id

  $tab_section.load $obj.attr('href')

  $("#tab-sections-container").append $tab_section

  return false

