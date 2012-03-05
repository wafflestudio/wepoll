Raphael.fn.donutChart = function (cx, cy, r, r2, values, labels, stroke, strokeWidth, index) {
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
	start = 0,
	hue = index == 0 ? 134/360.0 : 358/360.0,
	process = function (j) {
		var value = values[j],
		angleplus = 360 * value / total,
		popangle = angle + (angleplus / 2),
		color = Raphael.hsb(hue, 0.4 + j*0.6/values.length, 1 - 0.3*j/values.length),
		ms = 500,
		delta = 30,
		bcolor =  Raphael.hsb(hue, 0.4 + j*0.6/values.length, 1 - 0.3*j/values.length),
		p = sector(cx, cy, r, angle, angle + angleplus, {fill: "90-" + bcolor + "-" + color, stroke: stroke, "stroke-width": 1});

		var txt_x = 0;
		if (popangle <90 && popangle>0 || popangle > 270 && popangle<360) {
			txt_x = 175;
		}
		else{
			txt_x = 10;
		}
		var txt_y = cy + (r) * Math.sin(-popangle * rad);
		var txt = paper.text(txt_x, txt_y, labels[j])
		.attr({"text-anchor":"start", fill: "#000", stroke: "none", opacity: 0, "font-size": 10});
		var lx = cx+(r*2+r2)/3*Math.cos(-popangle*rad),
		ly = cy+(r*2+r2)/3*Math.sin(-popangle*rad),
		lx2 = cx+r*Math.cos(-popangle*rad),
		ly2 = cy+r*Math.sin(-popangle*rad),
		lx3 = 0;
	
		if (popangle <90 && popangle>0 || popangle > 270 && popangle<360) {
			lx3 = txt_x - 5;
		}
		else{
			lx3 = txt_x + txt.getBBox().width + 5;
		}

		console.log("w:"+txt.getBBox().width);
		var line = paper.path(["M", lx, ly, "L", lx2, ly2, lx3, txt_y]).attr({stroke:"#000", "stroke-width":1, opacity:0});
		p.mouseover(function () {
			p.stop().animate({transform: "s1.1 1.1 " + cx + " " + cy}, ms, ">");
			txt.stop().animate({opacity: 1}, ms);
			line.stop().animate({opacity:1}, ms);
		}).mouseout(function () {
			p.stop().animate({transform: ""}, ms, ">");
			txt.stop().animate({opacity: 0}, ms);
			line.stop().animate({opacity:0}, ms);
		});
		angle += angleplus;
		chart.push(p);
		chart.push(txt);
		chart.push(line);
		start += .1;
	};
	for (var i = 0, ii = values.length; i < ii; i++) {
		total += values[i];
	}
	for (i = 0; i < ii; i++) {
		process(i);
	}
	return chart;
};
