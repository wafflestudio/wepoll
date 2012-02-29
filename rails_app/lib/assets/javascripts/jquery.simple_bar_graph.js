(function($){
	$.fn.simpleBarGraph = function(prop) {
		var options=$.extend({
			height:10,
			width:200,
			color:"red",
			total:100,
			floating:"left"
		}, prop);

		this.each(function() {
			var $this = $(this);
			var color = $this.attr('data-color') || options.color;
			var value = parseFloat($this.attr("data-value"));
			var total = parseFloat(($this.attr("data-total") || options.total));
			var width = parseInt(($this.attr('data-width') || options.width));
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

			var w = r*width;

			//make bar
			var $bar = $("<div></div>");
			$bar.css("width", Math.round(w)+"px");
			$bar.css("height", options.height + "px");
			$bar.css("background-color", color);
			$bar.css("float", floating);

			//XXX: 임시방편으로 clearfix사용
			$this.addClass("clearfix");

			$this.append($bar);
		});

		return this;
	}
})(jQuery);
