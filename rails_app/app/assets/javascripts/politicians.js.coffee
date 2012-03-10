# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  $('#bills_all').live 'click', ->
    $.getScript all_url
    return
  $('#bills_accepted').live 'click', ->
    $.getScript accepted_url
    return
