#coding: utf-8
# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
# =require jquery.path

$ ->
  # initialize 
  $reply_box=$('#reply_box')
  $reply_box.hide()

  # tweet box click handler
  $('.tweet_item').click ->
    $.get($(this).attr("data-href"))
    return
  # report btn 
  $('.reply_item p.links a.report_link').live 'click', ->
    obj = this
    $.getJSON this.href, (data) ->
      if data.status == "error"
        alert "이미 신고하셨습니다"
    false

  # tweet recommend btn 
  $('.tweet_item a.tweet_recommend_btn').live 'click', ->
    obj = $(this).parent().parent().parent().children('.count')
    $.getJSON this.href, (data) ->
      if data.status == "error"
        alert "이미 공감하셨습니다"
      else
        $(obj).text data.count
    false

  # reply recommend btn
  $('.reply_item p.links a.recommend_link').live 'click', ->
    obj = this
    $.getJSON this.href, (data) ->
      if data.status == "error"
        alert "이미 공감하셨습니다"
      else
        $(obj).text "공감"+data.count
    false

  # reply btn (in tweet box)
  $('.reply_btn').click (e) ->
    $reply_box.css 'top', e.clientY-60
    $reply_box.show()
    $('#reply_box form').eq(0).attr 'action',this.href
    $('#in_reply_to_status_id').val $(this).attr('data-status_id')
    false

  # reply submit btn 
  $('#reply_submit_btn').live 'click', ->
    $form = $('#reply_box form')
    $.post $form[0].action, $form.serialize(), (data) ->
      console.log data
      if data.status == "error"
        alert data.message
      reset_box()
      return
    false

  $('#reply_close').click ->
    $reply_box.hide()
    return

  # function
  reset_box = ->
    $('#reply_close').click()
    $('#reply_text_box').val("")
  return
