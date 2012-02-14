(function($){
  $.fn.photoUpload = function(prop) {
    var options=$.extend({
      wrapperClass:"file_input_div",
      imgWidth:120,
      imgHeight:120,
      thumb_url_field:"thumb_url",
      error:function() {},
      success: function(e) {},
      optional_parameters:{},
			placeholder_img_src:"http://placehold.it/120x120",
      form_string:'<form action="' + prop.uploadAction +'" method="post" enctype="multipart/form-data"></form>',
			preview:true,
			zIndex:2147483583
    },prop);

    this.filter("input[type=file]").each(function() {
      var $wrapper = $('<div class="' + options.wrapperClass + '" />');
      $wrapper.css({position:'relative',width:options.imgWidth,height:options.imgHeight,overflow:'hidden'});
      $wrapper.hover(function(e) {$wrapper.css('cursor', 'pointer');}, function(e) {$wrapper.css('cursor','default');});
      $(this).css({position:'absolute',right:0,top:0,'font-size':'100pt',width:options.imgWidth,height:options.imgHeight, opacity:0, zIndex:options.zIndex});
//      $(this).focus(function() {$(this).blur();return false;});
      $wrapper.prepend('<img width="' + options.imgWidth + '" height="' + options.imgHeight+'" class="photo_thumb" src="' + options.placeholder_img_src + '" style="position:absolute;top:0" />');
        var $field = $(this);

        $(this).parent().append($wrapper);
        $(this).appendTo($wrapper);

        //hidden form

        $form = $(options.form_string);

        for (var prop in options.optional_parameters){
          $form.append('<input class="photo-upload" type="hidden" name="' + prop + '" value="' + unescape(options.optional_parameters[prop]) + '" />');
        }

        $form.appendTo($wrapper);
        $(this).change(function() {
          //insert file field to form
          o_name = $(this).attr('name');
          $(this).attr('name',options.field_name);
          $(this).appendTo($form);

          $form.ajaxSubmit({
            url:options.uploadAction,
            dataType:'text',
            complete:function() {
            },
            error:function(a,b,c) {
              options.error();
            },
            success:function(res, stat, xhr, elem) {
              res = jQuery.parseJSON(res);
							if (options.preview)
								$(".photo_thumb", $wrapper).attr("src", res[options.thumb_url_field]);
              //move it back
              $v = $("input[type=file]", $form);
              $v.appendTo($wrapper);
              $v.attr('name',o_name);
              options.success(res);
            }
          });
        });
    });
    return this;
  };
})(jQuery);
