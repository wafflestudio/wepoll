(function($) {
	$.fn.simpleBarGraph = function(prop) {
		var options=$.extend({
			height:10,
			width:200,
			color:"red",
			total:100,
			floating:"left",
			labelClass:"bar-label",
			labelPosition:"outside",
			backgroundColor:"transparent",
			animate:true,
			labelWidth:0,
			minWidth:0,
			label:function(x, fx) {
				return x+"";
			}
		}, prop);

		this.each(function() {
			var $this = $(this);
			var color = $this.attr('data-color') || options.color;
			var colors, heights;
			if (color.indexOf(",") >= 0) {
				var colors = color.split(",");
			}
			var value = parseFloat($this.attr("data-value"));
			var total = parseFloat(($this.attr("data-total") || options.total));
			var width = parseInt(($this.attr('data-width') || options.width));
			var floating = $this.attr('data-float') || options.floating;

			if (options.labelPosition === "outside")
				width -= options.labelWidth;


			var r = 0;
			if (total == -1) {
				var $ref = $($this.attr("data-ref"));
				var value2 = parseFloat($ref.attr("data-value"));
				var larger = value2 > value ? value2:value;

				if (larger == 0)
					r = 0;
				else
					r = value/larger;
			}
			else {
				r = total == 0 ? 0 : value/total;
			}

			var w;
			if (r == 0) w = options.minWidth;
			else w = Math.round(r*width);

			console.log("bar width = " + w);

			//make bar
			var $bar = $("<div></div>");

			if (colors) {
				var $subbar1 = $("<div></div>");
				var $subbar2 = $("<div></div>");

				$subbar1.css("width","100%");
				$subbar2.css("width","100%");
				$bar.append($subbar1).append($subbar2);

				$subbar1.css("background-color", colors[0]);
				$subbar2.css("background-color", colors[1]);

				if ($this.attr('data-height')) {
					heights = $this.attr('data-height').split(',');
					if (heights) {
						$subbar1.css("height",heights[0]);
						$subbar2.css("height",heights[1]);
					}
				}
			}

			var $lbl = $("<div></div>");
			$lbl.attr('class', options.labelClass);

			$bar.css("height", options.height + "px");
			if (heights) {
				$bar.css("height",(parseInt(heights[0]) + parseInt(heights[1])) +"px");
			}
			if (!colors) {
				$bar.css("background-color", color);
			}

			if (floating == 'left' || floating == "right") {
				$bar.css("float", floating);
				$lbl.css("float", floating);
			}
			else if (floating === 'center') {
				$bar.css("margin-left", "auto");
				$bar.css("margin-right", "auto");
			}



			$this.css("width", width + (options.labelPosition === 'outside' ? options.labelWidth : 0) + "px");
			$this.css("background-color", options.backgroundColor);
			$this.append($bar);
			$this.append($lbl);
			$this.addClass("clearfix");
			if (heights) {
				console.log("multibar");
				$this.css("height", (parseInt(heights[0]) + parseInt(heights[1]))+"px");
			}
			else {
				$this.css("height", options.height+"px");
			}

			if (options.labelPosition === "outside") {
			}
			else if (options.labelPosition === "inside") {
				$bar.append($lbl);
				if (floating === "left") {
					$lbl.css("margin-right", 3);
					$lbl.css("float","right");
				}
				else if (floating === "right") {
					$lbl.css("margin-left", 3);
					$lbl.css("float","left");
				}

			}
			else if (options.labelPosition === "center1") {
			}
			else if (options.labelPosition === "center2") {
			}

			$bar.css("width", options.minWidth);
			if (options.animate) {
				$bar.delay(500).animate({width:w}, {
					duration:3000,
					easing:"swing",
					step:function(now, fx) {
						$lbl.text(options.label(now/w*value), fx);
					}
				});
			}
			else {
				$bar.css("width",w);
				$lbl.text(options.label(value));
			}
		});
		return this;
	}
})(jQuery);
