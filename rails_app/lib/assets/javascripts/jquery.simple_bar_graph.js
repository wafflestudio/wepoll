(function($){
	$.fn.simpleBarGraph = function(prop) {
		var options=$.extend({
			height:10,
			width:200,
			color:"red",
			total:100,
			floating:"left",
			labelClass:"bar-label",
			label:function(x, fx) {
				return x+"";
			}
		}, prop);

		this.each(function() {
			var $this = $(this);
			var color = $this.attr('data-color') || options.color;
			var value = parseFloat($this.attr("data-value"));
			var total = parseFloat(($this.attr("data-total") || options.total));
			var width = parseInt(($this.attr('data-width') || options.width)) - options.labelWidth;
			var floating = $this.attr('data-float') || options.floating;

			var r = 0;
			if (total == -1) {
				var $ref = $($this.attr("data-ref"));
				var value2 = parseFloat($ref.attr("data-value"));

				r = value2>value ? (value/value2) : 1.0;
			}
			else {
				r = value/total;
			}

			var w = Math.round(r*width);

			//make bar
			var $bar = $("<div></div>");
			var $lbl = $("<div></div>");
			$lbl.attr('class', options.labelClass);

			$bar.css("height", options.height + "px");
			$bar.css("background-color", color);

			if (floating === 'left') {
				$bar.css("float","left");
				$lbl.css("float","left");
				
//				$bar.css("margin-left", 0);
			}
			else if (floating === 'right') {
				$bar.css("float","right");
				$lbl.css("float","right");
//				$bar.css("margin-left", (width - w) + "px" );
			}
			else if (floating === 'center') {
				$bar.css("margin-left", "auto");
				$bar.css("margin-right", "auto");
			}

			$this.css("width", width + options.labelWidth);
			$this.append($bar);
			$this.append($lbl);
			$this.addClass("clearfix");

			$bar.delay(500).animate({width:w}, {
				duration:3000,
				easing:"swing",
				step:function(now, fx) {
					$lbl.text(options.label(now/w*value), fx);
				}
			});
		});
		return this;
	}
})(jQuery);
