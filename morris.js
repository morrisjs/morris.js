(function() {

  window.Morris = {};

  window.Morris.Line = (function() {

    function Line(id, options) {
      this.el = $(document.getElementById(id));
      this.options = $.extend(this.defaults, options);
      if (this.options.data === void 0 || this.options.data.length === 0) return;
      this.el.addClass('graph-initialised');
      this.precalc();
      this.redraw();
    }

    Line.prototype.defaults = {
      lineWidth: 3,
      pointSize: 4,
      lineColors: ['#0b62a4', '#7A92A3', '#4da74d', '#afd8f8', '#edc240', '#cb4b4b', '#9440ed'],
      marginTop: 25,
      marginRight: 25,
      marginBottom: 30,
      marginLeft: 25,
      numLines: 5,
      gridLineColor: '#aaa',
      gridTextColor: '#888',
      gridTextSize: 12,
      gridStrokeWidth: 0.5
    };

    Line.prototype.precalc = function() {
      var all_y_vals, ykey, _i, _len, _ref,
        _this = this;
      this.xlabels = $.map(this.options.data, function(d) {
        return d[_this.options.xkey];
      });
      this.ylabels = this.options.labels;
      this.series = [];
      _ref = this.options.ykeys;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        ykey = _ref[_i];
        this.series.push($.map(this.options.data, function(d) {
          return d[ykey];
        }));
      }
      this.xvals = $.map(this.xlabels, function(x) {
        return _this.parseYear(x);
      });
      this.xmin = Math.min.apply(null, this.xvals);
      this.xmax = Math.max.apply(null, this.xvals);
      if (this.xmin === this.xmax) {
        this.xmin -= 1;
        this.xmax += 1;
      }
      all_y_vals = $.map(this.series, function(x) {
        return Math.max.apply(null, x);
      });
      return this.ymax = Math.max(20, Math.max.apply(null, all_y_vals));
    };

    Line.prototype.redraw = function() {
      var c, circle, columns, coords, dx, dy, height, hoverMargins, i, label, labelBox, left, lineInterval, path, prevLabelMargin, s, seriesCoords, seriesPoints, transX, transY, v, width, x, xLabelMargin, y, _i, _j, _len, _len2, _ref, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7,
        _this = this;
      this.el.empty();
      this.r = new Raphael(this.el[0]);
      left = this.measureText(this.ymax, this.options.gridTextSize).width + this.options.marginLeft;
      width = this.el.width() - left - this.options.marginRight;
      height = this.el.height() - this.options.marginTop - this.options.marginBottom;
      dx = width / (this.xmax - this.xmin);
      dy = height / this.ymax;
      transX = function(x) {
        if (_this.xvals.length === 1) {
          return left + width / 2;
        } else {
          return left + (x - _this.xmin) * dx;
        }
      };
      transY = function(y) {
        return _this.options.marginTop + height - y * dy;
      };
      lineInterval = height / (this.options.numLines - 1);
      for (i = 0, _ref = this.options.numLines - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        y = this.options.marginTop + i * lineInterval;
        v = Math.round((this.options.numLines - 1 - i) * this.ymax / (this.options.numLines - 1));
        this.r.text(left - this.options.marginLeft / 2, y, v).attr('font-size', this.options.gridTextSize).attr('fill', this.options.gridTextColor).attr('text-anchor', 'end');
        this.r.path("M" + left + "," + y + 'H' + (left + width)).attr('stroke', this.options.gridLineColor).attr('stroke-width', this.options.gridStrokeWidth);
      }
      prevLabelMargin = null;
      xLabelMargin = 50;
      for (i = _ref2 = Math.ceil(this.xmin), _ref3 = Math.floor(this.xmax); _ref2 <= _ref3 ? i <= _ref3 : i >= _ref3; _ref2 <= _ref3 ? i++ : i--) {
        label = this.r.text(transX(i), this.options.marginTop + height + this.options.marginBottom / 2, i).attr('font-size', this.options.gridTextSize).attr('fill', this.options.gridTextColor);
        labelBox = label.getBBox();
        if (prevLabelMargin === null || prevLabelMargin <= labelBox.x) {
          prevLabelMargin = labelBox.x + labelBox.width + xLabelMargin;
        } else {
          label.remove();
        }
      }
      columns = (function() {
        var _i, _len, _ref4, _results;
        _ref4 = this.xvals;
        _results = [];
        for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
          x = _ref4[_i];
          _results.push(transX(x));
        }
        return _results;
      }).call(this);
      seriesCoords = [];
      _ref4 = this.series;
      for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
        s = _ref4[_i];
        seriesCoords.push($.map(s, function(y, i) {
          return {
            x: columns[i],
            y: transY(y)
          };
        }));
      }
      for (i = _ref5 = seriesCoords.length - 1; _ref5 <= 0 ? i <= 0 : i >= 0; _ref5 <= 0 ? i++ : i--) {
        coords = seriesCoords[i];
        if (coords.length > 1) {
          path = this.createPath(coords, this.options.marginTop, left, this.options.marginTop + height, left + width);
          this.r.path(path).attr('stroke', this.options.lineColors[i]).attr('stroke-width', this.options.lineWidth);
        }
      }
      seriesPoints = (function() {
        var _ref6, _results;
        _results = [];
        for (i = 0, _ref6 = seriesCoords.length - 1; 0 <= _ref6 ? i <= _ref6 : i >= _ref6; 0 <= _ref6 ? i++ : i--) {
          _results.push([]);
        }
        return _results;
      })();
      for (i = _ref6 = seriesCoords.length - 1; _ref6 <= 0 ? i <= 0 : i >= 0; _ref6 <= 0 ? i++ : i--) {
        _ref7 = seriesCoords[i];
        for (_j = 0, _len2 = _ref7.length; _j < _len2; _j++) {
          c = _ref7[_j];
          circle = this.r.circle(c.x, c.y, this.options.pointSize).attr('fill', this.options.lineColors[i]).attr('stroke-width', 1).attr('stroke', '#ffffff');
          seriesPoints[i].push(circle);
        }
      }
      return hoverMargins = $.map(columns.slice(1), function(x, i) {
        return (x + columns[i]) / 2;
      });
    };

    Line.prototype.createPath = function(coords, top, left, bottom, right) {
      var c, g, grads, i, ix, lc, lg, path, x1, x2, y1, y2, _ref;
      path = "";
      grads = this.gradients(coords);
      for (i = 0, _ref = coords.length - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        c = coords[i];
        if (i === 0) {
          path += "M" + c.x + "," + c.y;
        } else {
          g = grads[i];
          lc = coords[i - 1];
          lg = grads[i - 1];
          ix = (c.x - lc.x) / 4;
          x1 = lc.x + ix;
          y1 = Math.min(bottom, lc.y + ix * lg);
          x2 = c.x - ix;
          y2 = Math.min(bottom, c.y - ix * g);
          path += "C" + x1 + "," + y1 + "," + x2 + "," + y2 + "," + c.x + "," + c.y;
        }
      }
      return path;
    };

    Line.prototype.gradients = function(coords) {
      return $.map(coords, function(c, i) {
        if (i === 0) {
          return (coords[1].y - c.y) / (coords[1].x - c.x);
        } else if (i === (coords.length - 1)) {
          return (c.y - coords[i - 1].y) / (c.x - coords[i - 1].x);
        } else {
          return (coords[i + 1].y - coords[i - 1].y) / (coords[i + 1].x - coords[i - 1].x);
        }
      });
    };

    Line.prototype.measureText = function(text, fontSize) {
      var ret, tt;
      if (fontSize == null) fontSize = 12;
      tt = this.r.text(100, 100, text).attr('font-size', fontSize);
      ret = tt.getBBox();
      tt.remove();
      return ret;
    };

    Line.prototype.parseYear = function(year) {
      var m, n;
      m = year.toString().match(/(\d+) Q(\d)/);
      n = year.toString().match(/(\d+)\-(\d+)/);
      if (m) {
        return parseInt(m[1], 10) + (parseInt(m[2], 10) * 3 - 1) / 12;
      } else if (n) {
        return parseInt(n[1], 10) + (parseInt(n[2], 10) - 1) / 12;
      } else {
        return parseInt(year, 10);
      }
    };

    return Line;

  })();

}).call(this);
