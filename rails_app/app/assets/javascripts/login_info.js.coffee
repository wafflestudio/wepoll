show_join_form = () ->
  $.colorbox {href:"<%= new_user_registration_path%>"}


$ () ->
  $(".popup-auth").click () ->
    $this = $ this
    href = $this.attr "href"
    window.open href, "authWindow", "width=600,height=400,menubar=0,location=0,toolbar=0,modal=yes,alwaysRaised=yes"
    return false
