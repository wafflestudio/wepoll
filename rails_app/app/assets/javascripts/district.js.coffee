# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
# =require jquery.simple_bar_graph
# =require timeline
# =require raphael-piechart
# =require raphael-donutchart
# =require jcombox-1.0b.packed
# =require politicians
# =require waypoints
# =require timeline/jquery.corner

$ () ->
  $('.message_entry .message_remove_btn').hide()
  $('.politician-photo-wrapper.right .photo-frame').click ->
    $('.link-button.right').click()
    return
  $('.politician-photo-wrapper.left .photo-frame').click ->
    $('.link-button.left').click()
    return
  $('.politician-select').jcombox { theme: 'gray' }
  $(".bar-graph").simpleBarGraph {
    animate:true,
    labelPosition:'outside',
    width:167,
    labelWidth:48,
    labelClass:"link-label",
    label:(x,fx) ->
      return Math.round(x)+""
  }


  # 정치인 선택 콤보박스 만들기 
  $(".dropdown").each () ->
    $this = $ this
    $("dt a", $this).click () ->
      $(".dropdown dd ul").hide()
      $("dd ul", $this).toggle()
      return false

    $("dd ul li a", $this).click () ->
      polid2=""
      if ($this.attr("id") == "politician1")
        polid2 = $("#politician2 dt a span.value").text()
      else
        polid2 = $("#politician1 dt a span.value").text()

      polid = $(this).attr("data-id")
      if polid == polid2 || $("dt a span.value", $this).text() == polid
        return false

      if $this.attr("id") == "politician2"
        t = polid2
        polid2 = polid
        polid = t

      text = $(this).html()
      $("dt a", $this).html text
      $("dd ul", $this).hide()

      url = "/district/#{$this.attr("data-district")}/#{polid}/#{polid2}"
      $(location).attr 'href', url

      return false

    $(document).bind 'click', (e) ->
      $clicked = $ e.target
      if (! $clicked.parents().hasClass("dropdown"))
        $("dd ul", $this).hide()

  # message like, blame btn
  $('.message_entry .message_entry_btn.active').live 'click', ->
    obj = this
    $.get this.href, (data) ->
      if data.status == "error"
        alert data.message
      else
        if data.type == "like"
          $('.message-entry-'+data.id+' .like_count').text data.count
        else if data.type == "blame"
          $('.message-entry-'+data.id+' .blame_count').text data.count
        else
    false
  $('#message_body').placeholder()
  # message destroy btn
  $('.message_entry').hover () ->
    $(this).children('.message_remove_btn').show()
  , ()->
    $(this).children('.message_remove_btn').hide()
  # message form submit btn
  $('#new_message').submit ->
    $('#message-submit-btn').val '전송중...'
    $('#message-submit-btn').attr 'disabled','true'
    true
