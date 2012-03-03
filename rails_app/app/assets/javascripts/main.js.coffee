#coding: utf-8
# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
# =require jquery.path

$ ->
  $reply_box=$('#reply_box')
  $reply_box.hide()
  $('.tweet_item').click ->
    $.get(this.id)
    return
  $('.reply_item p.links a.report_link').live 'click', ->
    obj = this
    $.getJSON this.href, (data) ->
      if data.status == "error"
        alert "이미 신고하셨습니다"
    false
  $('.reply_item p.links a.recommend_link').live 'click', ->
    obj = this
    $.getJSON this.href, (data) ->
      if data.status == "error"
        alert "이미 공감하셨습니다"
      else
        $(obj).text "공감"+data.count
    false
  $('.reply_btn').click (e) ->
    $reply_box.css 'top', $(e.currentTarget).position().top+180
    $reply_box.show()
    $('#reply_box form').eq(0).attr 'action','/tweets/'+this.id+'/tweet_replies'
    return
  $('#reply_close').click ->
    $reply_box.hide()
    return
  return
