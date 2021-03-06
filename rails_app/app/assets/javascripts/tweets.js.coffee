# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
#= require jquery.infinitescroll

$ ->
  # initialize 
  $('#tweets_wrapper').css 'max-height',(document.documentElement.clientHeight-$('#tweets_wrapper').offset().top-27)+"px"
  $('#replies_wrapper').css 'max-height',(document.documentElement.clientHeight-$('#tweets_wrapper').offset().top-27)+"px"
  	
  $reply_box=$('#reply_box')
  $reply_box.hide()
  $('#replies_paginator').hide()

  # tweet box click handler
  $('.tweet_item').live 'click', ->
    $.get $(this).attr("data-href")
    return
  # report btn 
  $('.reply_item p.links a.report_link').live 'click', ->
    obj = this
    $.get this.href, (data) ->
      if data.status == "ok"
        alert "신고하셨습니다"
      else
      	alert "이미 신고하셨습니다"
    false

  # tweet recommend btn 
  $('.tweet_item a.tweet_recommend_btn').live 'click', ->
    obj = $(this).parent().parent().parent().children('.count')
    $.get this.href, (data) ->
      if data.status == "error"
        alert data.message
      else
        $($('.count[data-status_id*="'+$(obj).attr('data-status_id')+'"]')).text data.count
    false

  # reply recommend btn
  $('.reply_item p.links a.recommend_link').live 'click', ->
    obj = this
    $.get this.href, (data) ->
      if data.status == "error"
        alert data.message
      else
        $(obj).text "공감"+data.count
    false

  # reply btn (in tweet box)
  $('.reply_btn.new').live 'click', (e) ->
    $reply_box.css 'top', e.clientY-60
    $reply_box.show()
    $('#reply_box form').eq(0).attr 'action',this.href
    $('#in_reply_to_status_id').val $(this).attr('data-status_id')
    false

  # reply submit btn 
  $('#reply_submit_btn').live 'click', ->
    $('#reply-loading-indicator').show()
    $form = $('#reply_box form')
    $.post $form[0].action, $form.serialize(), reset_box(), "script"
    false

  $('#reply_close').click ->
    $reply_box.hide()
    return
  $('#reply_text_box').placeholder()
  $('#tweets_paginator a').live 'click', ->
    $('.loading-indicator').show()
    return

  # function
  reset_box = ->
    $('#reply_close').click()
    $('#reply_text_box').val("")
    $('#reply-loading-indicator').hide()
  return
