Raphael.fn.donutChart = function (cx, cy, r, r2, values, labels, stroke, strokeWidth, index, color) {
	var paper = this,
	rad = Math.PI / 180,
	chart = this.set();
	function sector(cx, cy, r, startAngle, endAngle, params) {
		var x1 = cx + r * Math.cos(-startAngle * rad),
		x2 = cx + r * Math.cos(-endAngle * rad),
		y1 = cy + r * Math.sin(-startAngle * rad),
		y2 = cy + r * Math.sin(-endAngle * rad);

		var x4 = cx + r2 * Math.cos(-startAngle * rad),
		x3 = cx + r2 * Math.cos(-endAngle * rad),
		y4 = cy + r2 * Math.sin(-startAngle * rad),
		y3 = cy + r2 * Math.sin(-endAngle * rad);

		return paper.path(["M", x1, y1, "A", r, r, 0, +(endAngle - startAngle > 180), 0, x2, y2, "L", x3,y3,"A",r2,r2,0,+(endAngle-startAngle>180),1,x4,y4, "z"]).attr(params);
	}
	
	var txt_r = values.length < 8 ? r : r + 10;
	var angle = 0,
	total = 0,
	rects = [],
	texts = [],
	start = 0,
	hsbcolor=Raphael.rgb2hsb(Raphael.getRGB(color)),
	process = function (j) {
		var value = values[j],
		angleplus = 360 * value / total,
		popangle = angle + (angleplus / 2),
		color = Raphael.hsb(hsbcolor.h, hsbcolor.s, 0.5 + 0.5*j/values.length),
		ms = 200,
		delta = 30,
		bcolor =  color,
		p = sector(cx, cy, r, angle, angle + angleplus, {fill: "90-" + bcolor + "-" + color, stroke: stroke, "stroke-width": 1});

		var txt_x = cx + (txt_r - 10) * Math.cos(-popangle * rad);
		var txt_y = cy + (txt_r) * Math.sin(-popangle * rad);
	
		var txt = paper.text(txt_x, txt_y, labels[j])
		.attr({fill: "#000", stroke: "none", opacity:1, "font-size": 10});
		var bbox = txt.getBBox();
		var rect = paper.rect(txt_x - bbox.width/2 - 3, txt_y-bbox.height/2- 3, bbox.width +6, bbox.height+6).attr({"stroke":"#888", fill:"white", opacity:0.5, r:8});

		rects.push(rect);
		texts.push(txt);

		var f1 = function() {
			p.stop().animate({transform: "s1.1 1.1 " + cx + " " + cy}, ms, ">");
			txt.stop().animate({opacity: 1}, ms);
			rect.stop().animate({opacity:0.8}, ms)
		};

		var f2 = function () {
			p.stop().animate({transform: ""}, ms, ">");
			txt.stop().animate({opacity: 0.5}, ms);
			rect.stop().animate({opacity:0.5}, ms);
		};

		p.mouseover(function () {
			p.animate({transform: "s1.1 1.1 " + cx + " " + cy}, ms, ">");
			txt.animate({opacity: 1}, ms);
			rect.animate({opacity:0.8}, ms);
			rect.unmouseover();
			rect.mouseout(f2);

			rect.toFront();
			txt.toFront();
		}).mouseout(function () {
			p.animate({transform: ""}, ms, ">");
			txt.animate({opacity: 0.5}, ms);
			rect.animate({opacity:0.5}, ms);
			rect.mouseover(f1);
			rect.unmouseout();
		});

		rect.mouseover(f1).mouseout(f2);

		angle += angleplus;
		chart.push(p);
		chart.push(rect);
		chart.push(txt);
		start += .1;
	};
	for (var i = 0, ii = values.length; i < ii; i++) {
		total += values[i];
	}
	for (i = 0; i < ii; i++) {
		process(i);
	}

	for (i = 0; i < ii; i++) {
		rects[i].toFront();
	}
	for (i = 0; i < ii; i++) {
		texts[i].toFront();
	}

	var totalcounttext = paper.text(cx,cy,total).attr({fill: color, stroke: "none", opacity: 1, "font-weight":"bold", "font-size": 35});
	return chart;
};
