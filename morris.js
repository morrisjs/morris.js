(function() {
  var $, Morris, minutesSpecHelper, secondsSpecHelper,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $ = jQuery;

  Morris = {};

  Morris.Line = (function() {

    function Line(options) {
      this.updateHilight = __bind(this.updateHilight, this);
      this.hilight = __bind(this.hilight, this);
      this.updateHover = __bind(this.updateHover, this);
      this.transY = __bind(this.transY, this);
      this.transX = __bind(this.transX, this);      if (!(this instanceof Morris.Line)) return new Morris.Line(options);
      if (typeof options.element === 'string') {
        this.el = $(document.getElementById(options.element));
      } else {
        this.el = $(options.element);
      }
      this.options = $.extend({}, this.defaults, options);
      if (this.options.data === void 0 || this.options.data.length === 0) return;
      this.el.addClass('graph-initialised');
      this.precalc();
      this.redraw();
    }

    Line.prototype.defaults = {
      lineWidth: 3,
      pointSize: 4,
      lineColors: ['#0b62a4', '#7A92A3', '#4da74d', '#afd8f8', '#edc240', '#cb4b4b', '#9440ed'],
      ymax: 'auto',
      ymin: 'auto 0',
      marginTop: 25,
      marginRight: 25,
      marginBottom: 30,
      marginLeft: 25,
      numLines: 5,
      gridLineColor: '#aaa',
      gridTextColor: '#888',
      gridTextSize: 12,
      gridStrokeWidth: 0.5,
      hoverPaddingX: 10,
      hoverPaddingY: 5,
      hoverMargin: 10,
      hoverFillColor: '#fff',
      hoverBorderColor: '#ccc',
      hoverBorderWidth: 2,
      hoverOpacity: 0.95,
      hoverLabelColor: '#444',
      hoverFontSize: 12,
      smooth: true,
      hideHover: false,
      parseTime: true,
      units: '',
      dateFormat: function(x) {
        return new Date(x).toString();
      },
      xLabels: 'auto',
      xLabelsFormat: null
    };

    Line.prototype.precalc = function() {
      var d, series_data, touchHandler, ykey, ymax, ymin, _i, _j, _k, _len, _len2, _ref, _ref2, _ref3, _results,
        _this = this;
      this.options.data.sort(function(a, b) {
        return (a[_this.options.xkey] < b[_this.options.xkey]) - (b[_this.options.xkey] < a[_this.options.xkey]);
      });
      this.columnLabels = $.map(this.options.data, function(d) {
        return d[_this.options.xkey];
      });
      this.seriesLabels = this.options.labels;
      this.series = [];
      _ref = this.options.ykeys;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        ykey = _ref[_i];
        series_data = [];
        _ref2 = this.options.data;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          d = _ref2[_j];
          series_data.push(d[ykey]);
        }
        this.series.push(series_data);
      }
      if (this.options.parseTime) {
        this.xvals = $.map(this.columnLabels, function(x) {
          return Morris.parseDate(x);
        });
      } else {
        this.xvals = (function() {
          _results = [];
          for (var _k = _ref3 = this.columnLabels.length - 1; _ref3 <= 0 ? _k <= 0 : _k >= 0; _ref3 <= 0 ? _k++ : _k--){ _results.push(_k); }
          return _results;
        }).apply(this);
      }
      if (this.options.parseTime) {
        this.columnLabels = $.map(this.columnLabels, function(d) {
          if (typeof d === 'number') {
            return _this.options.dateFormat(d);
          } else {
            return d;
          }
        });
      }
      this.xmin = Math.min.apply(null, this.xvals);
      this.xmax = Math.max.apply(null, this.xvals);
      if (this.xmin === this.xmax) {
        this.xmin -= 1;
        this.xmax += 1;
      }
      if (typeof this.options.ymax === 'string' && this.options.ymax.slice(0, 4) === 'auto') {
        ymax = Math.max.apply(null, Array.prototype.concat.apply([], this.series));
        if (this.options.ymax.length > 5) {
          this.options.ymax = Math.max(parseInt(this.options.ymax.slice(5), 10), ymax);
        } else {
          this.options.ymax = ymax;
        }
      }
      if (typeof this.options.ymin === 'string' && this.options.ymin.slice(0, 4) === 'auto') {
        ymin = Math.min.apply(null, Array.prototype.concat.apply([], this.series));
        if (this.options.ymin.length > 5) {
          this.options.ymin = Math.min(parseInt(this.options.ymin.slice(5), 10), ymin);
        } else {
          this.options.ymin = ymin;
        }
      }
      this.pointGrow = Raphael.animation({
        r: this.options.pointSize + 3
      }, 25, 'linear');
      this.pointShrink = Raphael.animation({
        r: this.options.pointSize
      }, 25, 'linear');
      this.elementWidth = null;
      this.elementHeight = null;
      this.prevHilight = null;
      this.el.mousemove(function(evt) {
        return _this.updateHilight(evt.pageX);
      });
      if (this.options.hideHover) {
        this.el.mouseout(function(evt) {
          return _this.hilight(null);
        });
      }
      touchHandler = function(evt) {
        var touch;
        touch = evt.originalEvent.touches[0] || evt.originalEvent.changedTouches[0];
        _this.updateHilight(touch.pageX);
        return touch;
      };
      this.el.bind('touchstart', touchHandler);
      this.el.bind('touchmove', touchHandler);
      return this.el.bind('touchend', touchHandler);
    };

    Line.prototype.calc = function() {
      var h, s, scoords, w, x, _i, _len, _ref,
        _this = this;
      w = this.el.width();
      h = this.el.height();
      if (this.elementWidth !== w || this.elementHeight !== h) {
        this.maxYLabelWidth = Math.max(this.measureText(this.options.ymin + this.options.units, this.options.gridTextSize).width, this.measureText(this.options.ymax + this.options.units, this.options.gridTextSize).width);
        this.left = this.maxYLabelWidth + this.options.marginLeft;
        this.width = this.el.width() - this.left - this.options.marginRight;
        this.height = this.el.height() - this.options.marginTop - this.options.marginBottom;
        this.dx = this.width / (this.xmax - this.xmin);
        this.dy = this.height / (this.options.ymax - this.options.ymin);
        this.columns = (function() {
          var _i, _len, _ref, _results;
          _ref = this.xvals;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            x = _ref[_i];
            _results.push(this.transX(x));
          }
          return _results;
        }).call(this);
        this.seriesCoords = [];
        _ref = this.series;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          s = _ref[_i];
          scoords = [];
          $.each(s, function(i, y) {
            if (y === null) {
              return scoords.push(null);
            } else {
              return scoords.push({
                x: _this.columns[i],
                y: _this.transY(y)
              });
            }
          });
          this.seriesCoords.push(scoords);
        }
        return this.hoverMargins = $.map(this.columns.slice(1), function(x, i) {
          return (x + _this.columns[i]) / 2;
        });
      }
    };

    Line.prototype.transX = function(x) {
      if (this.xvals.length === 1) {
        return this.left + this.width / 2;
      } else {
        return this.left + (x - this.xmin) * this.dx;
      }
    };

    Line.prototype.transY = function(y) {
      return this.options.marginTop + this.height - (y - this.options.ymin) * this.dy;
    };

    Line.prototype.redraw = function() {
      this.el.empty();
      this.r = new Raphael(this.el[0]);
      this.calc();
      this.drawGrid();
      this.drawSeries();
      this.drawHover();
      return this.hilight(this.options.hideHover ? null : 0);
    };

    Line.prototype.drawGrid = function() {
      var drawLabel, firstY, i, l, labelText, lastY, lineY, prevLabelMargin, v, xLabelMargin, y, yInterval, ypos, _i, _len, _ref, _ref2, _results, _results2,
        _this = this;
      yInterval = (this.options.ymax - this.options.ymin) / (this.options.numLines - 1);
      firstY = Math.ceil(this.options.ymin / yInterval) * yInterval;
      lastY = Math.floor(this.options.ymax / yInterval) * yInterval;
      for (lineY = firstY; firstY <= lastY ? lineY <= lastY : lineY >= lastY; lineY += yInterval) {
        v = Math.floor(lineY);
        y = this.transY(v);
        this.r.text(this.left - this.options.marginLeft / 2, y, Morris.commas(v) + this.options.units).attr('font-size', this.options.gridTextSize).attr('fill', this.options.gridTextColor).attr('text-anchor', 'end');
        this.r.path("M" + this.left + "," + y + "H" + (this.left + this.width)).attr('stroke', this.options.gridLineColor).attr('stroke-width', this.options.gridStrokeWidth);
      }
      ypos = this.options.marginTop + this.height + this.options.marginBottom / 2;
      xLabelMargin = 50;
      prevLabelMargin = null;
      drawLabel = function(labelText, xpos) {
        var label, labelBox;
        label = _this.r.text(_this.transX(xpos), ypos, labelText).attr('font-size', _this.options.gridTextSize).attr('fill', _this.options.gridTextColor);
        labelBox = label.getBBox();
        if (prevLabelMargin === null || prevLabelMargin <= labelBox.x) {
          return prevLabelMargin = labelBox.x + labelBox.width + xLabelMargin;
        } else {
          return label.remove();
        }
      };
      if (this.options.parseTime) {
        if (this.columnLabels.length === 1 && this.options.xLabels === 'auto') {
          return drawLabel(this.columnLabels[0], this.xvals[0]);
        } else {
          _ref = Morris.labelSeries(this.xmin, this.xmax, this.width, this.options.xLabels, this.options.xLabelsFormat);
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            l = _ref[_i];
            _results.push(drawLabel(l[0], l[1]));
          }
          return _results;
        }
      } else {
        _results2 = [];
        for (i = 0, _ref2 = this.columnLabels.length; 0 <= _ref2 ? i <= _ref2 : i >= _ref2; 0 <= _ref2 ? i++ : i--) {
          labelText = this.columnLabels[this.columnLabels.length - i - 1];
          _results2.push(drawLabel(labelText, i));
        }
        return _results2;
      }
    };

    Line.prototype.drawSeries = function() {
      var c, circle, coords, i, path, _ref, _ref2, _results;
      for (i = _ref = this.seriesCoords.length - 1; _ref <= 0 ? i <= 0 : i >= 0; _ref <= 0 ? i++ : i--) {
        coords = this.seriesCoords[i];
        if (coords.length > 1) {
          path = this.createPath(coords, this.options.marginTop, this.left, this.options.marginTop + this.height, this.left + this.width);
          this.r.path(path).attr('stroke', this.options.lineColors[i]).attr('stroke-width', this.options.lineWidth);
        }
      }
      this.seriesPoints = (function() {
        var _ref2, _results;
        _results = [];
        for (i = 0, _ref2 = this.seriesCoords.length - 1; 0 <= _ref2 ? i <= _ref2 : i >= _ref2; 0 <= _ref2 ? i++ : i--) {
          _results.push([]);
        }
        return _results;
      }).call(this);
      _results = [];
      for (i = _ref2 = this.seriesCoords.length - 1; _ref2 <= 0 ? i <= 0 : i >= 0; _ref2 <= 0 ? i++ : i--) {
        _results.push((function() {
          var _i, _len, _ref3, _results2;
          _ref3 = this.seriesCoords[i];
          _results2 = [];
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            c = _ref3[_i];
            if (c === null) {
              circle = null;
            } else {
              circle = this.r.circle(c.x, c.y, this.options.pointSize).attr('fill', this.options.lineColors[i]).attr('stroke-width', 1).attr('stroke', '#ffffff');
            }
            _results2.push(this.seriesPoints[i].push(circle));
          }
          return _results2;
        }).call(this));
      }
      return _results;
    };

    Line.prototype.createPath = function(all_coords, top, left, bottom, right) {
      var c, coords, g, grads, i, ix, lc, lg, path, x1, x2, y1, y2, _ref;
      path = "";
      coords = $.map(all_coords, function(c) {
        return c;
      });
      if (this.options.smooth) {
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
      } else {
        path = "M" + $.map(coords, function(c) {
          return "" + c.x + "," + c.y;
        }).join("L");
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

    Line.prototype.drawHover = function() {
      var i, yLabel, _ref, _results;
      this.hoverHeight = this.options.hoverFontSize * 1.5 * (this.series.length + 1);
      this.hover = this.r.rect(-10, -this.hoverHeight / 2 - this.options.hoverPaddingY, 20, this.hoverHeight + this.options.hoverPaddingY * 2, 10).attr('fill', this.options.hoverFillColor).attr('stroke', this.options.hoverBorderColor).attr('stroke-width', this.options.hoverBorderWidth).attr('opacity', this.options.hoverOpacity);
      this.xLabel = this.r.text(0, (this.options.hoverFontSize * 0.75) - this.hoverHeight / 2, '').attr('fill', this.options.hoverLabelColor).attr('font-weight', 'bold').attr('font-size', this.options.hoverFontSize);
      this.hoverSet = this.r.set();
      this.hoverSet.push(this.hover);
      this.hoverSet.push(this.xLabel);
      this.yLabels = [];
      _results = [];
      for (i = 0, _ref = this.series.length - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        yLabel = this.r.text(0, this.options.hoverFontSize * 1.5 * (i + 1.5) - this.hoverHeight / 2, '').attr('fill', this.options.lineColors[i]).attr('font-size', this.options.hoverFontSize);
        this.yLabels.push(yLabel);
        _results.push(this.hoverSet.push(yLabel));
      }
      return _results;
    };

    Line.prototype.updateHover = function(index) {
      var i, maxLabelWidth, xloc, yloc, _ref,
        _this = this;
      this.hoverSet.show();
      this.xLabel.attr('text', this.columnLabels[index]);
      for (i = 0, _ref = this.series.length - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        this.yLabels[i].attr('text', "" + this.seriesLabels[i] + ": " + (Morris.commas(this.series[i][index])) + this.options.units);
      }
      maxLabelWidth = Math.max.apply(null, $.map(this.yLabels, function(l) {
        return l.getBBox().width;
      }));
      maxLabelWidth = Math.max(maxLabelWidth, this.xLabel.getBBox().width);
      this.hover.attr('width', maxLabelWidth + this.options.hoverPaddingX * 2);
      this.hover.attr('x', -this.options.hoverPaddingX - maxLabelWidth / 2);
      yloc = Math.min.apply(null, $.map(this.series, function(s) {
        return _this.transY(s[index]);
      }));
      if (yloc > this.hoverHeight + this.options.hoverPaddingY * 2 + this.options.hoverMargin + this.options.marginTop) {
        yloc = yloc - this.hoverHeight / 2 - this.options.hoverPaddingY - this.options.hoverMargin;
      } else {
        yloc = yloc + this.hoverHeight / 2 + this.options.hoverPaddingY + this.options.hoverMargin;
      }
      yloc = Math.max(this.options.marginTop + this.hoverHeight / 2 + this.options.hoverPaddingY, yloc);
      yloc = Math.min(this.options.marginTop + this.height - this.hoverHeight / 2 - this.options.hoverPaddingY, yloc);
      xloc = Math.min(this.left + this.width - maxLabelWidth / 2 - this.options.hoverPaddingX, this.columns[index]);
      xloc = Math.max(this.left + maxLabelWidth / 2 + this.options.hoverPaddingX, xloc);
      return this.hoverSet.attr('transform', "t" + xloc + "," + yloc);
    };

    Line.prototype.hideHover = function() {
      return this.hoverSet.hide();
    };

    Line.prototype.hilight = function(index) {
      var i, _ref, _ref2;
      if (this.prevHilight !== null && this.prevHilight !== index) {
        for (i = 0, _ref = this.seriesPoints.length - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
          if (this.seriesPoints[i][this.prevHilight]) {
            this.seriesPoints[i][this.prevHilight].animate(this.pointShrink);
          }
        }
      }
      if (index !== null && this.prevHilight !== index) {
        for (i = 0, _ref2 = this.seriesPoints.length - 1; 0 <= _ref2 ? i <= _ref2 : i >= _ref2; 0 <= _ref2 ? i++ : i--) {
          if (this.seriesPoints[i][index]) {
            this.seriesPoints[i][index].animate(this.pointGrow);
          }
        }
        this.updateHover(index);
      }
      this.prevHilight = index;
      if (index === null) return this.hideHover();
    };

    Line.prototype.updateHilight = function(x) {
      var hoverIndex, _ref, _results;
      x -= this.el.offset().left;
      _results = [];
      for (hoverIndex = _ref = this.hoverMargins.length; _ref <= 0 ? hoverIndex <= 0 : hoverIndex >= 0; _ref <= 0 ? hoverIndex++ : hoverIndex--) {
        if (hoverIndex === 0 || this.hoverMargins[hoverIndex - 1] > x) {
          this.hilight(hoverIndex);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Line.prototype.measureText = function(text, fontSize) {
      var ret, tt;
      if (fontSize == null) fontSize = 12;
      tt = this.r.text(100, 100, text).attr('font-size', fontSize);
      ret = tt.getBBox();
      tt.remove();
      return ret;
    };

    return Line;

  })();

  Morris.parseDate = function(date) {
    var isecs, m, msecs, n, o, p, q, r, ret, secs;
    if (typeof date === 'number') return date;
    m = date.match(/^(\d+) Q(\d)$/);
    n = date.match(/^(\d+)-(\d+)$/);
    o = date.match(/^(\d+)-(\d+)-(\d+)$/);
    p = date.match(/^(\d+) W(\d+)$/);
    q = date.match(/^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+)Z?$/);
    r = date.match(/^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+):(\d+(\.\d+)?)Z?$/);
    if (m) {
      return new Date(parseInt(m[1], 10), parseInt(m[2], 10) * 3 - 1, 1).getTime();
    } else if (n) {
      return new Date(parseInt(n[1], 10), parseInt(n[2], 10) - 1, 1).getTime();
    } else if (o) {
      return new Date(parseInt(o[1], 10), parseInt(o[2], 10) - 1, parseInt(o[3], 10)).getTime();
    } else if (p) {
      ret = new Date(parseInt(p[1], 10), 0, 1);
      if (ret.getDay() !== 4) ret.setMonth(0, 1 + ((4 - ret.getDay()) + 7) % 7);
      return ret.getTime() + parseInt(p[2], 10) * 604800000;
    } else if (q) {
      return new Date(parseInt(q[1], 10), parseInt(q[2], 10) - 1, parseInt(q[3], 10), parseInt(q[4], 10), parseInt(q[5], 10)).getTime();
    } else if (r) {
      secs = parseFloat(r[6]);
      isecs = Math.floor(secs);
      msecs = Math.round((secs - isecs) * 1000);
      return new Date(parseInt(r[1], 10), parseInt(r[2], 10) - 1, parseInt(r[3], 10), parseInt(r[4], 10), parseInt(r[5], 10), isecs, msecs).getTime();
    } else {
      return new Date(parseInt(date, 10), 0, 1).getTime();
    }
  };

  Morris.commas = function(num) {
    var absnum, intnum, ret, strabsnum;
    if (num === null) {
      return "n/a";
    } else {
      ret = num < 0 ? "-" : "";
      absnum = Math.abs(num);
      intnum = Math.floor(absnum).toFixed(0);
      ret += intnum.replace(/(?=(?:\d{3})+$)(?!^)/g, ',');
      strabsnum = absnum.toString();
      if (strabsnum.length > intnum.length) ret += strabsnum.slice(intnum.length);
      return ret;
    }
  };

  Morris.pad2 = function(number) {
    return (number < 10 ? '0' : '') + number;
  };

  Morris.labelSeries = function(dmin, dmax, pxwidth, specName, xLabelsFormat) {
    var d, d0, ddensity, name, ret, s, spec, t, _i, _len, _ref;
    ddensity = 200 * (dmax - dmin) / pxwidth;
    d0 = new Date(dmin);
    spec = Morris.LABEL_SPECS[specName];
    if (spec === void 0) {
      _ref = Morris.AUTO_LABEL_ORDER;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        name = _ref[_i];
        s = Morris.LABEL_SPECS[name];
        if (ddensity >= s.span) {
          spec = s;
          break;
        }
      }
    }
    if (spec === void 0) spec = Morris.LABEL_SPECS["second"];
    if (xLabelsFormat) spec.fmt = xLabelsFormat;
    d = spec.start(d0);
    ret = [];
    while ((t = d.getTime()) <= dmax) {
      if (t >= dmin) ret.push([spec.fmt(d), t]);
      spec.incr(d);
    }
    return ret;
  };

  minutesSpecHelper = function(interval) {
    return {
      span: interval * 60 * 1000,
      start: function(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours());
      },
      fmt: function(d) {
        return "" + (Morris.pad2(d.getHours())) + ":" + (Morris.pad2(d.getMinutes()));
      },
      incr: function(d) {
        return d.setMinutes(d.getMinutes() + interval);
      }
    };
  };

  secondsSpecHelper = function(interval) {
    return {
      span: interval * 1000,
      start: function(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), d.getMinutes());
      },
      fmt: function(d) {
        return "" + (Morris.pad2(d.getHours())) + ":" + (Morris.pad2(d.getMinutes())) + ":" + (Morris.pad2(d.getSeconds()));
      },
      incr: function(d) {
        return d.setSeconds(d.getSeconds() + interval);
      }
    };
  };

  Morris.LABEL_SPECS = {
    "year": {
      span: 17280000000,
      start: function(d) {
        return new Date(d.getFullYear(), 0, 1);
      },
      fmt: function(d) {
        return "" + (d.getFullYear());
      },
      incr: function(d) {
        return d.setFullYear(d.getFullYear() + 1);
      }
    },
    "month": {
      span: 2419200000,
      start: function(d) {
        return new Date(d.getFullYear(), d.getMonth(), 1);
      },
      fmt: function(d) {
        return "" + (d.getFullYear()) + "-" + (Morris.pad2(d.getMonth() + 1));
      },
      incr: function(d) {
        return d.setMonth(d.getMonth() + 1);
      }
    },
    "day": {
      span: 86400000,
      start: function(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate());
      },
      fmt: function(d) {
        return "" + (d.getFullYear()) + "-" + (Morris.pad2(d.getMonth() + 1)) + "-" + (Morris.pad2(d.getDate()));
      },
      incr: function(d) {
        return d.setDate(d.getDate() + 1);
      }
    },
    "hour": minutesSpecHelper(60),
    "30min": minutesSpecHelper(30),
    "15min": minutesSpecHelper(15),
    "10min": minutesSpecHelper(10),
    "5min": minutesSpecHelper(5),
    "minute": minutesSpecHelper(1),
    "30sec": secondsSpecHelper(30),
    "15sec": secondsSpecHelper(15),
    "10sec": secondsSpecHelper(10),
    "5sec": secondsSpecHelper(5),
    "second": secondsSpecHelper(1)
  };

  Morris.AUTO_LABEL_ORDER = ["year", "month", "day", "hour", "30min", "15min", "10min", "5min", "minute", "30sec", "15sec", "10sec", "5sec", "second"];

  window.Morris = Morris;

}).call(this);
