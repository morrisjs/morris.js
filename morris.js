
/*global jQuery: false, Raphael: false */

function parse_year(year) {
  var m = year.toString().match(/(\d+) Q(\d)/);
  var n = year.toString().match(/(\d+)\-(\d+)/);
  if (m) {
    return parseInt(m[1], 10) + (parseInt(m[2], 10) * 3 - 1) / 12;
  }
  else if (n) {
    return parseInt(n[1], 10) + (parseInt(n[2], 10) - 1) / 12;
  }
  else {
    return parseInt(year, 10);
  }
}

function setup_graph(config) {
  /*jshint loopfunc: true */
  var data = config.data;
  if (data.length === 0) {
    return;
  }
  this.addClass('graph-initialised');
  var xlabels = $.map(data, function (d) { return d[config.xkey]; });
  var series = config.ykeys;
  var labels = config.labels;
  if (!data || !data.length) {
    return;
  }
  for (var i = 0; i < series.length; i++) {
    series[i] = $.map(data, function (d) { return d[series[i]]; });
  }
  var xvals = $.map(xlabels, function (x) { return parse_year(x); });

  var xmin = Math.min.apply(null, xvals);
  var xmax = Math.max.apply(null, xvals);
  if (xmin === xmax) {
    xmin -= 1;
    xmax += 1;
  }
  var ymax = Math.max(20, Math.max.apply(null,
    $.map(series, function (s) { return Math.max.apply(null, s); })));
  var r = new Raphael(this[0]);
  var margin_top = 25, margin_bottom = 30, margin_right = 25;
  var tt = r.text(100, 100, ymax).attr('font-size', 12);
  var margin_left = 25 + tt.getBBox().width;
  tt.remove();
  var h = this.height() - margin_top - margin_bottom;
  var w = this.width() - margin_left - margin_right;
  var dx = w / (xmax - xmin);
  var dy = h / ymax;

  function trans_x(x) {
    if (xvals.length === 1) {
      return margin_left + w / 2;
    }
    else {
      return margin_left + (x - xmin) * dx;
    }
  }
  function trans_y(y) {
    return margin_top + h - y * dy;
  }
    
  // draw horizontal lines
  var num_lines = 5;
  var line_interval = h / (num_lines - 1);
  for (i = 0; i < num_lines; i++) {
    var y = margin_top + i * line_interval;
    r.text(margin_left - 12, y, Math.floor((num_lines - 1 - i) * ymax / (num_lines - 1)))
      .attr('font-size', 12)
      .attr('fill', '#888')
      .attr('text-anchor', 'end');
    r.path("M" + (margin_left) + "," + y + "L" + (margin_left + w) + "," + y)
      .attr('stroke', '#aaa')
      .attr('stroke-width', 0.5);
  }

  // calculate the columns
  var cols = $.map(xvals, trans_x);
  var hover_margins = $.map(cols.slice(1),
      function (x, i) { return (x + cols[i]) / 2; });

  var last_label = null;
  var ylabel_margin = 50;
  for (i = Math.ceil(xmin); i <= Math.floor(xmax); i++) {
    var label = r.text(trans_x(i), margin_top + h + margin_bottom / 2, i)
        .attr('font-size', 12)
        .attr('fill', '#888');
    if (last_label !== null) {
      var bb1 = last_label.getBBox();
      var bb2 = label.getBBox();
      if (bb1.x + bb1.width + ylabel_margin > bb2.x) {
        label.remove();
      }
      else {
        last_label = label;
      }
    }
    else {
      last_label = label;
    }
  }

  // draw the series
  var series_points = [];
  for (var s = (series.length - 1); s >= 0; s--) {
    var path = '';
    var lc = null;
    var lg = null;
    // translate the coordinates into screen positions
    var coords = $.map(series[s],
      function (v, idx) { return {x: cols[idx], y: trans_y(v)}; });
    if (coords.length > 1) {
      // calculate the gradients
      var grads = $.map(coords, function (c, i) {
        if (i === 0) {
          return (coords[1].y - c.y) / (coords[1].x - c.x);
        }
        else if (i === xvals.length - 1) {
          return (c.y - coords[i - 1].y) / (c.x - coords[i - 1].x);
        }
        else {
          return (coords[i + 1].y - coords[i - 1].y) / (coords[i + 1].x - coords[i - 1].x);
        }
      });
      for (i = 0; i < coords.length; i++) {
        var c = coords[i];
        var g = grads[i];
        if (i === 0) {
          path += "M" + ([c.x, c.y].join(','));
        }
        else {
          var ix = (c.x - lc.x) / 4;
          path += "C" + ([lc.x + ix,
                          Math.min(margin_top + h, lc.y + ix * lg),
                          c.x - ix,
                          Math.min(margin_top + h, c.y - ix * g),
                          c.x, c.y].join(','));
        }
        lc = c;
        lg = g;
      }
      r.path(path)
        .attr('stroke', config.line_colors[s])
        .attr('stroke-width', config.line_width);
      // draw the points
    }
    series_points.push([]);
    for (i = 0; i < series[s].length; i++) {
      var c1 = {x: cols[i], y: trans_y(series[s][i])};
      var circle = r.circle(c1.x, c1.y, config.point_size)
        .attr('fill', config.line_colors[s])
        .attr('stroke-width', 1)
        .attr('stroke', '#ffffff');
      series_points[series_points.length - 1].push(circle);
    }
  }
    
  // hover labels
  var label_height = 12;
  var label_padding_x = 10;
  var label_padding_y = 5;
  var label_margin = 10;
  var yvar_labels = [];
  var label_float_height = (label_height * 1.5) * (series.length + 1);
  var label_float = r.rect(-10, -label_float_height / 2 - label_padding_y, 20, label_float_height + label_padding_y * 2, 10)
        .attr('fill', '#fff')
        .attr('stroke', '#ccc')
        .attr('stroke-width', 2)
        .attr('opacity', 0.95);
  var xvar_label = r.text(0, (label_height * 0.75) - (label_float_height / 2), '')
    .attr('fill', '#444')
    .attr('font-weight', 'bold')
    .attr('font-size', label_height);
  var label_set = r.set();
  label_set.push(label_float);
  label_set.push(xvar_label);
  for (i = 0; i < series.length; i++) {
    var yl = r.text(0, (label_height * 1.5 * (i + 1.5)) - (label_float_height / 2), '')
      .attr('fill', config.line_colors[i])
      .attr('font-size', label_height);
    yvar_labels.push(yl);
    label_set.push(yl);
  }
  function commas(v) {
    v = v.toString();
    var r = "";
    while (v.length > 3) {
      r = "," + v.substr(v.length - 3) + r;
      v = v.substr(0, v.length - 3);
    }
    r = v + r;
    return r;
  }
  function update_float(index) {
    label_set.show();
    xvar_label.attr('text', xlabels[index]);
    for (var i = 0; i < series.length; i++) {
      yvar_labels[i].attr('text', labels[i] + ': ' + commas(series[i][index]));
    }
    // calculate bbox width
    var bbw = Math.max(xvar_label.getBBox().width,
      Math.max.apply(null, $.map(yvar_labels, function (l) { return l.getBBox().width; })));
    label_float.attr('width', bbw + label_padding_x * 2);
    label_float.attr('x', -label_padding_x - bbw / 2);
    // determine y-pos
    var yloc = Math.min.apply(null, $.map(series, function (s) { return trans_y(s[index]); }));
    if (yloc > label_float_height + label_padding_y * 2 + label_margin + margin_top) {
      yloc = yloc - label_float_height / 2 - label_padding_y - label_margin;
    }
    else {
      yloc = yloc + label_float_height / 2 + label_padding_y + label_margin;
    }
    yloc = Math.max(margin_top + label_float_height / 2 + label_padding_y, yloc);
    yloc = Math.min(margin_top + h - label_float_height / 2 - label_padding_y, yloc);
    var xloc = Math.min(margin_left + w - bbw / 2 - label_padding_y, cols[index]);
    xloc = Math.max(margin_left + bbw / 2 + label_padding_x, xloc);
    label_set.attr('transform', 't' + xloc + ',' + yloc);
  }
  function hide_float() {
    label_set.hide();
  }
    
  // column hilighting
  var self = this;
  var prev_hilight = null;
  var point_grow = Raphael.animation({r: config.point_size + 3}, 25, "linear");
  var point_shrink = Raphael.animation({r: config.point_size}, 25, "linear");
  function highlight(index) {
    var j;
    if (prev_hilight !== null && prev_hilight !== index) {
      for (j = 0; j < series_points.length; j++) {
        series_points[j][prev_hilight].animate(point_shrink);
      }
    }
    if (index !== null && prev_hilight !== index) {
      for (j = 0; j < series_points.length; j++) {
        series_points[j][index].animate(point_grow);
      }
      update_float(index);
    }
    prev_hilight = index;
    if (index === null) {
      hide_float();
    }
  }
  function update_hilight(x_coord) {
    var x = x_coord - self.offset().left;
    for (var i = hover_margins.length; i > 0; i--) {
      if (hover_margins[i - 1] > x) {
        break;
      }
    }
    highlight(i);
  }
  this.mousemove(function (evt) {
    update_hilight(evt.pageX);
  });
  function touchhandler(evt) {
    var touch = evt.originalEvent.touches[0] ||
                evt.originalEvent.changedTouches[0];
    update_hilight(touch.pageX);
    return touch;
  }
  this.bind('touchstart', touchhandler);
  this.bind('touchmove', touchhandler);
  this.bind('touchend', touchhandler);
  highlight(0);
}

$.fn.hml = function (options) {
  var config = {
    line_width: 3,
    point_size: 4,
    line_colors: [
      '#0b62a4',
      '#7A92A3',
      '#4da74d',
      '#afd8f8',
      '#edc240',
      '#cb4b4b',
      '#9440ed'
    ]
  };
  if (options) {
    $.extend(config, options);
  }
  return this.each(function () {
    setup_graph.call($(this), config);
  });
};
