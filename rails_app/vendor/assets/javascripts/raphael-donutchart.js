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
	var angle = 0,
	total = 0,
	rects = [],
	texts = [],
	start = 0,
	hue = index == 0 ? 134/360.0 : 358/360.0,
	process = function (j) {
		var value = values[j],
		angleplus = 360 * value / total,
		popangle = angle + (angleplus / 2),
		color = Raphael.hsb(hue, 0.4 + j*0.6/values.length, 1 - 0.3*j/values.length),
		ms = 200,
		delta = 30,
		bcolor =  Raphael.hsb(hue, 0.4 + j*0.6/values.length, 1 - 0.3*j/values.length),
		p = sector(cx, cy, r, angle, angle + angleplus, {fill: "90-" + bcolor + "-" + color, stroke: stroke, "stroke-width": 1});

		var txt_x = cx + (r - 10) * Math.cos(-popangle * rad);
		var txt_y = cy + (r) * Math.sin(-popangle * rad);
	
		var rect = paper.rect(txt_x - 30 - 3, txt_y-5 - 3,60 +6, 10+6).attr({"stroke":"#888", fill:"white", opacity:0.5, r:8});
		var txt = paper.text(txt_x, txt_y, labels[j])
		.attr({fill: "#000", stroke: "none", opacity:1, "font-size": 10});

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
		}).mouseout(function () {
			p.animate({transform: ""}, ms, ">");
			txt.animate({opacity: 0.5}, ms);
			rect.animate({opacity:0.5}, ms);
			rect.mouseover(f1);
			rect.unmouseout();
		});

		rect.mouseover(f1).mouseout(f2);

		angle += angleplus;
//		chart.push(txt);
//		chart.push(rect);
		chart.push(p);
		start += .1;
	};
	for (var i = 0, ii = values.length; i < ii; i++) {
		total += values[i];
	}
	for (i = 0; i < ii; i++) {
		process(i);
	}

	//z-index
	// for (i = 0; i < ii; i++) {
	//   if (rects[i].parentNode)
	//     rects[i].parentNode.appendChild(rects[i]);
	// }
	// for (i = 0; i < ii; i++) {
	//   if (texts[i].parentNode)
	//     texts[i].parentNode.appendChild(texts[i]);
	// }

	var totalcounttext = paper.text(cx,cy,total).attr({fill: color, stroke: "none", opacity: 1, "font-weight":"bold", "font-size": 35});
	return chart;
};
