show_join_form = () ->
  $.colorbox {href:"<%= new_user_registration_path%>"}

$ () ->
  $(".popup-auth").click () ->
    $this = $ this
    href = $this.attr "href"
    return show_auth_dialog(href)
