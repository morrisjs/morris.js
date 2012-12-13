(function() {
  var $, Morris, minutesSpecHelper, secondsSpecHelper,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Morris = window.Morris = {};

  $ = jQuery;

  Morris.EventEmitter = (function() {

    function EventEmitter() {}

    EventEmitter.prototype.on = function(name, handler) {
      if (this.handlers == null) {
        this.handlers = {};
      }
      if (this.handlers[name] == null) {
        this.handlers[name] = [];
      }
      return this.handlers[name].push(handler);
    };

    EventEmitter.prototype.fire = function() {
      var args, handler, name, _i, _len, _ref, _results;
      name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if ((this.handlers != null) && (this.handlers[name] != null)) {
        _ref = this.handlers[name];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          handler = _ref[_i];
          _results.push(handler.apply(null, args));
        }
        return _results;
      }
    };

    return EventEmitter;

  })();

  Morris.commas = function(num) {
    var absnum, intnum, ret, strabsnum;
    if (num != null) {
      ret = num < 0 ? "-" : "";
      absnum = Math.abs(num);
      intnum = Math.floor(absnum).toFixed(0);
      ret += intnum.replace(/(?=(?:\d{3})+$)(?!^)/g, ',');
      strabsnum = absnum.toString();
      if (strabsnum.length > intnum.length) {
        ret += strabsnum.slice(intnum.length);
      }
      return ret;
    } else {
      return '-';
    }
  };

  Morris.pad2 = function(number) {
    return (number < 10 ? '0' : '') + number;
  };

  Morris.Grid = (function(_super) {

    __extends(Grid, _super);

    function Grid(options) {
      if (typeof options.element === 'string') {
        this.el = $(document.getElementById(options.element));
      } else {
        this.el = $(options.element);
      }
      if (!(this.el != null) || this.el.length === 0) {
        throw new Error("Graph container element not found");
      }
      this.options = $.extend({}, this.gridDefaults, this.defaults || {}, options);
      if (this.options.data === void 0 || this.options.data.length === 0) {
        return;
      }
      if (typeof this.options.units === 'string') {
        this.options.postUnits = options.units;
      }
      this.r = new Raphael(this.el[0]);
      this.elementWidth = null;
      this.elementHeight = null;
      this.dirty = false;
      if (this.init) {
        this.init();
      }
      this.setData(this.options.data);
    }

    Grid.prototype.gridDefaults = {
      dateFormat: null,
      gridLineColor: '#aaa',
      gridStrokeWidth: 0.5,
      gridTextColor: '#888',
      gridTextSize: 12,
      numLines: 5,
      padding: 25,
      parseTime: true,
      postUnits: '',
      preUnits: '',
      ymax: 'auto',
      ymin: 'auto 0',
      goals: [],
      goalStrokeWidth: 1.0,
      goalLineColors: ['#666633', '#999966', '#cc6666', '#663333'],
      events: [],
      eventStrokeWidth: 1.0,
      eventLineColors: ['#005a04', '#ccffbb', '#3a5f0b', '#005502']
    };

    Grid.prototype.setData = function(data, redraw) {
      var e, idx, index, maxGoal, minGoal, ret, row, total, ykey, ymax, ymin, yval;
      if (redraw == null) {
        redraw = true;
      }
      ymax = this.cumulative ? 0 : null;
      ymin = this.cumulative ? 0 : null;
      if (this.options.goals.length > 0) {
        minGoal = Math.min.apply(null, this.options.goals);
        maxGoal = Math.max.apply(null, this.options.goals);
        ymin = ymin != null ? Math.min(ymin, minGoal) : minGoal;
        ymax = ymax != null ? Math.max(ymax, maxGoal) : maxGoal;
      }
      this.data = (function() {
        var _i, _len, _results;
        _results = [];
        for (index = _i = 0, _len = data.length; _i < _len; index = ++_i) {
          row = data[index];
          ret = {};
          ret.label = row[this.options.xkey];
          if (this.options.parseTime) {
            ret.x = Morris.parseDate(ret.label);
            if (this.options.dateFormat) {
              ret.label = this.options.dateFormat(ret.x);
            } else if (typeof ret.label === 'number') {
              ret.label = new Date(ret.label).toString();
            }
          } else {
            ret.x = index;
          }
          total = 0;
          ret.y = (function() {
            var _j, _len1, _ref, _results1;
            _ref = this.options.ykeys;
            _results1 = [];
            for (idx = _j = 0, _len1 = _ref.length; _j < _len1; idx = ++_j) {
              ykey = _ref[idx];
              yval = row[ykey];
              if (typeof yval === 'string') {
                yval = parseFloat(yval);
              }
              if ((yval != null) && typeof yval !== 'number') {
                yval = null;
              }
              if (yval != null) {
                if (this.cumulative) {
                  total += yval;
                } else {
                  if (ymax != null) {
                    ymax = Math.max(yval, ymax);
                    ymin = Math.min(yval, ymin);
                  } else {
                    ymax = ymin = yval;
                  }
                }
              }
              if (this.cumulative && (total != null)) {
                ymax = Math.max(total, ymax);
                ymin = Math.min(total, ymin);
              }
              _results1.push(yval);
            }
            return _results1;
          }).call(this);
          _results.push(ret);
        }
        return _results;
      }).call(this);
      if (this.options.parseTime) {
        this.data = this.data.sort(function(a, b) {
          return (a.x > b.x) - (b.x > a.x);
        });
      }
      this.xmin = this.data[0].x;
      this.xmax = this.data[this.data.length - 1].x;
      this.events = [];
      if (this.options.parseTime && this.options.events.length > 0) {
        this.events = (function() {
          var _i, _len, _ref, _results;
          _ref = this.options.events;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            e = _ref[_i];
            _results.push(Morris.parseDate(e));
          }
          return _results;
        }).call(this);
        this.xmax = Math.max(this.xmax, Math.max.apply(null, this.events));
        this.xmin = Math.min(this.xmin, Math.min.apply(null, this.events));
      }
      if (this.xmin === this.xmax) {
        this.xmin -= 1;
        this.xmax += 1;
      }
      if (typeof this.options.ymax === 'string') {
        if (this.options.ymax.slice(0, 4) === 'auto') {
          if (this.options.ymax.length > 5) {
            this.ymax = parseInt(this.options.ymax.slice(5), 10);
            if (ymax != null) {
              this.ymax = Math.max(ymax, this.ymax);
            }
          } else {
            this.ymax = ymax != null ? ymax : 0;
          }
        } else {
          this.ymax = parseInt(this.options.ymax, 10);
        }
      } else {
        this.ymax = this.options.ymax;
      }
      if (typeof this.options.ymin === 'string') {
        if (this.options.ymin.slice(0, 4) === 'auto') {
          if (this.options.ymin.length > 5) {
            this.ymin = parseInt(this.options.ymin.slice(5), 10);
            if (ymin != null) {
              this.ymin = Math.min(ymin, this.ymin);
            }
          } else {
            this.ymin = ymin !== null ? ymin : 0;
          }
        } else {
          this.ymin = parseInt(this.options.ymin, 10);
        }
      } else {
        this.ymin = this.options.ymin;
      }
      if (this.ymin === this.ymax) {
        if (ymin) {
          this.ymin -= 1;
        }
        this.ymax += 1;
      }
      this.yInterval = (this.ymax - this.ymin) / (this.options.numLines - 1);
      if (this.yInterval > 0 && this.yInterval < 1) {
        this.precision = -Math.floor(Math.log(this.yInterval) / Math.log(10));
      } else {
        this.precision = 0;
      }
      this.dirty = true;
      if (redraw) {
        return this.redraw();
      }
    };

    Grid.prototype._calc = function() {
      var h, maxYLabelWidth, w;
      w = this.el.width();
      h = this.el.height();
      if (this.elementWidth !== w || this.elementHeight !== h || this.dirty) {
        this.elementWidth = w;
        this.elementHeight = h;
        this.dirty = false;
        maxYLabelWidth = Math.max(this.measureText(this.yAxisFormat(this.ymin), this.options.gridTextSize).width, this.measureText(this.yAxisFormat(this.ymax), this.options.gridTextSize).width);
        this.left = maxYLabelWidth + this.options.padding;
        this.right = this.elementWidth - this.options.padding;
        this.top = this.options.padding;
        this.bottom = this.elementHeight - this.options.padding - 1.5 * this.options.gridTextSize;
        this.width = this.right - this.left;
        this.height = this.bottom - this.top;
        this.dx = this.width / (this.xmax - this.xmin);
        this.dy = this.height / (this.ymax - this.ymin);
        if (this.calc) {
          return this.calc();
        }
      }
    };

    Grid.prototype.transY = function(y) {
      return this.bottom - (y - this.ymin) * this.dy;
    };

    Grid.prototype.transX = function(x) {
      if (this.data.length === 1) {
        return (this.left + this.right) / 2;
      } else {
        return this.left + (x - this.xmin) * this.dx;
      }
    };

    Grid.prototype.redraw = function() {
      this.r.clear();
      this._calc();
      this.drawGrid();
      this.drawGoals();
      this.drawEvents();
      if (this.draw) {
        return this.draw();
      }
    };

    Grid.prototype.drawGoals = function() {
      var goal, i, _i, _len, _ref, _results;
      _ref = this.options.goals;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        goal = _ref[i];
        _results.push(this.r.path("M" + this.left + "," + (this.transY(goal)) + "H" + (this.left + this.width)).attr('stroke', this.options.goalLineColors[i % this.options.goalLineColors.length]).attr('stroke-width', this.options.goalStrokeWidth));
      }
      return _results;
    };

    Grid.prototype.drawEvents = function() {
      var event, i, _i, _len, _ref, _results;
      _ref = this.events;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        event = _ref[i];
        _results.push(this.r.path("M" + (this.transX(event)) + "," + this.bottom + "V" + this.top).attr('stroke', this.options.eventLineColors[i % this.options.eventLineColors.length]).attr('stroke-width', this.options.eventStrokeWidth));
      }
      return _results;
    };

    Grid.prototype.drawGrid = function() {
      var firstY, lastY, lineY, v, y, _i, _ref, _results;
      firstY = this.ymin;
      lastY = this.ymax;
      _results = [];
      for (lineY = _i = firstY, _ref = this.yInterval; firstY <= lastY ? _i <= lastY : _i >= lastY; lineY = _i += _ref) {
        v = parseFloat(lineY.toFixed(this.precision));
        y = this.transY(v);
        this.r.text(this.left - this.options.padding / 2, y, this.yAxisFormat(v)).attr('font-size', this.options.gridTextSize).attr('fill', this.options.gridTextColor).attr('text-anchor', 'end');
        _results.push(this.r.path("M" + this.left + "," + y + "H" + (this.left + this.width)).attr('stroke', this.options.gridLineColor).attr('stroke-width', this.options.gridStrokeWidth));
      }
      return _results;
    };

    Grid.prototype.measureText = function(text, fontSize) {
      var ret, tt;
      if (fontSize == null) {
        fontSize = 12;
      }
      tt = this.r.text(100, 100, text).attr('font-size', fontSize);
      ret = tt.getBBox();
      tt.remove();
      return ret;
    };

    Grid.prototype.yAxisFormat = function(label) {
      return this.yLabelFormat(label);
    };

    Grid.prototype.yLabelFormat = function(label) {
      return "" + this.options.preUnits + (Morris.commas(label)) + this.options.postUnits;
    };

    return Grid;

  })(Morris.EventEmitter);

  Morris.parseDate = function(date) {
    var isecs, m, msecs, n, o, offsetmins, p, q, r, ret, secs;
    if (typeof date === 'number') {
      return date;
    }
    m = date.match(/^(\d+) Q(\d)$/);
    n = date.match(/^(\d+)-(\d+)$/);
    o = date.match(/^(\d+)-(\d+)-(\d+)$/);
    p = date.match(/^(\d+) W(\d+)$/);
    q = date.match(/^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+)(Z|([+-])(\d\d):?(\d\d))?$/);
    r = date.match(/^(\d+)-(\d+)-(\d+)[ T](\d+):(\d+):(\d+(\.\d+)?)(Z|([+-])(\d\d):?(\d\d))?$/);
    if (m) {
      return new Date(parseInt(m[1], 10), parseInt(m[2], 10) * 3 - 1, 1).getTime();
    } else if (n) {
      return new Date(parseInt(n[1], 10), parseInt(n[2], 10) - 1, 1).getTime();
    } else if (o) {
      return new Date(parseInt(o[1], 10), parseInt(o[2], 10) - 1, parseInt(o[3], 10)).getTime();
    } else if (p) {
      ret = new Date(parseInt(p[1], 10), 0, 1);
      if (ret.getDay() !== 4) {
        ret.setMonth(0, 1 + ((4 - ret.getDay()) + 7) % 7);
      }
      return ret.getTime() + parseInt(p[2], 10) * 604800000;
    } else if (q) {
      if (!q[6]) {
        return new Date(parseInt(q[1], 10), parseInt(q[2], 10) - 1, parseInt(q[3], 10), parseInt(q[4], 10), parseInt(q[5], 10)).getTime();
      } else {
        offsetmins = 0;
        if (q[6] !== 'Z') {
          offsetmins = parseInt(q[8], 10) * 60 + parseInt(q[9], 10);
          if (q[7] === '+') {
            offsetmins = 0 - offsetmins;
          }
        }
        return Date.UTC(parseInt(q[1], 10), parseInt(q[2], 10) - 1, parseInt(q[3], 10), parseInt(q[4], 10), parseInt(q[5], 10) + offsetmins);
      }
    } else if (r) {
      secs = parseFloat(r[6]);
      isecs = Math.floor(secs);
      msecs = Math.round((secs - isecs) * 1000);
      if (!r[8]) {
        return new Date(parseInt(r[1], 10), parseInt(r[2], 10) - 1, parseInt(r[3], 10), parseInt(r[4], 10), parseInt(r[5], 10), isecs, msecs).getTime();
      } else {
        offsetmins = 0;
        if (r[8] !== 'Z') {
          offsetmins = parseInt(r[10], 10) * 60 + parseInt(r[11], 10);
          if (r[9] === '+') {
            offsetmins = 0 - offsetmins;
          }
        }
        return Date.UTC(parseInt(r[1], 10), parseInt(r[2], 10) - 1, parseInt(r[3], 10), parseInt(r[4], 10), parseInt(r[5], 10) + offsetmins, isecs, msecs);
      }
    } else {
      return new Date(parseInt(date, 10), 0, 1).getTime();
    }
  };

  Morris.Line = (function(_super) {

    __extends(Line, _super);

    function Line(options) {
      this.updateHilight = __bind(this.updateHilight, this);

      this.hilight = __bind(this.hilight, this);

      this.updateHover = __bind(this.updateHover, this);
      if (!(this instanceof Morris.Line)) {
        return new Morris.Line(options);
      }
      Line.__super__.constructor.call(this, options);
    }

    Line.prototype.init = function() {
      var touchHandler,
        _this = this;
      this.pointGrow = Raphael.animation({
        r: this.options.pointSize + 3
      }, 25, 'linear');
      this.pointShrink = Raphael.animation({
        r: this.options.pointSize
      }, 25, 'linear');
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

    Line.prototype.defaults = {
      lineWidth: 3,
      pointSize: 4,
      lineColors: ['#0b62a4', '#7A92A3', '#4da74d', '#afd8f8', '#edc240', '#cb4b4b', '#9440ed'],
      pointWidths: [1],
      pointStrokeColors: ['#ffffff'],
      pointFillColors: [],
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
      xLabels: 'auto',
      xLabelFormat: null,
      continuousLine: true
    };

    Line.prototype.calc = function() {
      this.calcPoints();
      this.generatePaths();
      return this.calcHoverMargins();
    };

    Line.prototype.calcPoints = function() {
      var row, y, _i, _len, _ref, _results;
      _ref = this.data;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        row._x = this.transX(row.x);
        _results.push(row._y = (function() {
          var _j, _len1, _ref1, _results1;
          _ref1 = row.y;
          _results1 = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            y = _ref1[_j];
            if (y != null) {
              _results1.push(this.transY(y));
            } else {
              _results1.push(y);
            }
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Line.prototype.calcHoverMargins = function() {
      var i, r;
      return this.hoverMargins = (function() {
        var _i, _len, _ref, _results;
        _ref = this.data.slice(1);
        _results = [];
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          r = _ref[i];
          _results.push((r._x + this.data[i]._x) / 2);
        }
        return _results;
      }).call(this);
    };

    Line.prototype.generatePaths = function() {
      var c, coords, i, r, smooth;
      return this.paths = (function() {
        var _i, _ref, _ref1, _results;
        _results = [];
        for (i = _i = 0, _ref = this.options.ykeys.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
          smooth = this.options.smooth === true || (_ref1 = this.options.ykeys[i], __indexOf.call(this.options.smooth, _ref1) >= 0);
          coords = (function() {
            var _j, _len, _ref2, _results1;
            _ref2 = this.data;
            _results1 = [];
            for (_j = 0, _len = _ref2.length; _j < _len; _j++) {
              r = _ref2[_j];
              if (r._y[i] !== void 0) {
                _results1.push({
                  x: r._x,
                  y: r._y[i]
                });
              }
            }
            return _results1;
          }).call(this);
          if (this.options.continuousLine) {
            coords = (function() {
              var _j, _len, _results1;
              _results1 = [];
              for (_j = 0, _len = coords.length; _j < _len; _j++) {
                c = coords[_j];
                if (c.y !== null) {
                  _results1.push(c);
                }
              }
              return _results1;
            })();
          }
          if (coords.length > 1) {
            _results.push(Morris.Line.createPath(coords, smooth, this.bottom));
          } else {
            _results.push(null);
          }
        }
        return _results;
      }).call(this);
    };

    Line.prototype.draw = function() {
      this.drawXAxis();
      this.drawSeries();
      this.drawHover();
      return this.hilight(this.options.hideHover ? null : this.data.length - 1);
    };

    Line.prototype.drawXAxis = function() {
      var drawLabel, l, labels, prevLabelMargin, row, xLabelMargin, ypos, _i, _len, _results,
        _this = this;
      ypos = this.bottom + this.options.gridTextSize * 1.25;
      xLabelMargin = 50;
      prevLabelMargin = null;
      drawLabel = function(labelText, xpos) {
        var label, labelBox;
        label = _this.r.text(_this.transX(xpos), ypos, labelText).attr('font-size', _this.options.gridTextSize).attr('fill', _this.options.gridTextColor);
        labelBox = label.getBBox();
        if ((!(prevLabelMargin != null) || prevLabelMargin >= labelBox.x + labelBox.width) && labelBox.x >= 0 && (labelBox.x + labelBox.width) < _this.el.width()) {
          return prevLabelMargin = labelBox.x - xLabelMargin;
        } else {
          return label.remove();
        }
      };
      if (this.options.parseTime) {
        if (this.data.length === 1 && this.options.xLabels === 'auto') {
          labels = [[this.data[0].label, this.data[0].x]];
        } else {
          labels = Morris.labelSeries(this.xmin, this.xmax, this.width, this.options.xLabels, this.options.xLabelFormat);
        }
      } else {
        labels = (function() {
          var _i, _len, _ref, _results;
          _ref = this.data;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            row = _ref[_i];
            _results.push([row.label, row.x]);
          }
          return _results;
        }).call(this);
      }
      labels.reverse();
      _results = [];
      for (_i = 0, _len = labels.length; _i < _len; _i++) {
        l = labels[_i];
        _results.push(drawLabel(l[0], l[1]));
      }
      return _results;
    };

    Line.prototype.drawSeries = function() {
      var circle, i, path, row, _i, _j, _ref, _ref1, _results;
      for (i = _i = _ref = this.options.ykeys.length - 1; _ref <= 0 ? _i <= 0 : _i >= 0; i = _ref <= 0 ? ++_i : --_i) {
        path = this.paths[i];
        if (path !== null) {
          this.r.path(path).attr('stroke', this.colorForSeries(i)).attr('stroke-width', this.options.lineWidth);
        }
      }
      this.seriesPoints = (function() {
        var _j, _ref1, _results;
        _results = [];
        for (i = _j = 0, _ref1 = this.options.ykeys.length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
          _results.push([]);
        }
        return _results;
      }).call(this);
      _results = [];
      for (i = _j = _ref1 = this.options.ykeys.length - 1; _ref1 <= 0 ? _j <= 0 : _j >= 0; i = _ref1 <= 0 ? ++_j : --_j) {
        _results.push((function() {
          var _k, _len, _ref2, _results1;
          _ref2 = this.data;
          _results1 = [];
          for (_k = 0, _len = _ref2.length; _k < _len; _k++) {
            row = _ref2[_k];
            if (row._y[i] != null) {
              circle = this.r.circle(row._x, row._y[i], this.options.pointSize).attr('fill', this.pointFillColorForSeries(i) || this.colorForSeries(i)).attr('stroke-width', this.strokeWidthForSeries(i)).attr('stroke', this.strokeForSeries(i));
            } else {
              circle = null;
            }
            _results1.push(this.seriesPoints[i].push(circle));
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Line.createPath = function(coords, smooth, bottom) {
      var coord, g, grads, i, ix, lg, path, prevCoord, x1, x2, y1, y2, _i, _len;
      path = "";
      if (smooth) {
        grads = Morris.Line.gradients(coords);
      }
      prevCoord = {
        y: null
      };
      for (i = _i = 0, _len = coords.length; _i < _len; i = ++_i) {
        coord = coords[i];
        if (coord.y != null) {
          if (prevCoord.y != null) {
            if (smooth) {
              g = grads[i];
              lg = grads[i - 1];
              ix = (coord.x - prevCoord.x) / 4;
              x1 = prevCoord.x + ix;
              y1 = Math.min(bottom, prevCoord.y + ix * lg);
              x2 = coord.x - ix;
              y2 = Math.min(bottom, coord.y - ix * g);
              path += "C" + x1 + "," + y1 + "," + x2 + "," + y2 + "," + coord.x + "," + coord.y;
            } else {
              path += "L" + coord.x + "," + coord.y;
            }
          } else {
            if (!smooth || (grads[i] != null)) {
              path += "M" + coord.x + "," + coord.y;
            }
          }
        }
        prevCoord = coord;
      }
      return path;
    };

    Line.gradients = function(coords) {
      var coord, grad, i, nextCoord, prevCoord, _i, _len, _results;
      grad = function(a, b) {
        return (a.y - b.y) / (a.x - b.x);
      };
      _results = [];
      for (i = _i = 0, _len = coords.length; _i < _len; i = ++_i) {
        coord = coords[i];
        if (coord.y != null) {
          nextCoord = coords[i + 1] || {
            y: null
          };
          prevCoord = coords[i - 1] || {
            y: null
          };
          if ((prevCoord.y != null) && (nextCoord.y != null)) {
            _results.push(grad(prevCoord, nextCoord));
          } else if (prevCoord.y != null) {
            _results.push(grad(prevCoord, coord));
          } else if (nextCoord.y != null) {
            _results.push(grad(coord, nextCoord));
          } else {
            _results.push(null);
          }
        } else {
          _results.push(null);
        }
      }
      return _results;
    };

    Line.prototype.drawHover = function() {
      var i, idx, yLabel, _i, _ref, _results;
      this.hoverHeight = this.options.hoverFontSize * 1.5 * (this.options.ykeys.length + 1);
      this.hover = this.r.rect(-10, -this.hoverHeight / 2 - this.options.hoverPaddingY, 20, this.hoverHeight + this.options.hoverPaddingY * 2, 10).attr('fill', this.options.hoverFillColor).attr('stroke', this.options.hoverBorderColor).attr('stroke-width', this.options.hoverBorderWidth).attr('opacity', this.options.hoverOpacity);
      this.xLabel = this.r.text(0, (this.options.hoverFontSize * 0.75) - this.hoverHeight / 2, '').attr('fill', this.options.hoverLabelColor).attr('font-weight', 'bold').attr('font-size', this.options.hoverFontSize);
      this.hoverSet = this.r.set();
      this.hoverSet.push(this.hover);
      this.hoverSet.push(this.xLabel);
      this.yLabels = [];
      _results = [];
      for (i = _i = 0, _ref = this.options.ykeys.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        idx = this.cumulative ? this.options.ykeys.length - i - 1 : i;
        yLabel = this.r.text(0, this.options.hoverFontSize * 1.5 * (idx + 1.5) - this.hoverHeight / 2, '').attr('fill', this.colorForSeries(i)).attr('font-size', this.options.hoverFontSize);
        this.yLabels.push(yLabel);
        _results.push(this.hoverSet.push(yLabel));
      }
      return _results;
    };

    Line.prototype.updateHover = function(index) {
      var i, l, maxLabelWidth, row, xloc, y, yloc, _i, _len, _ref;
      this.hoverSet.show();
      row = this.data[index];
      this.xLabel.attr('text', row.label);
      _ref = row.y;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        y = _ref[i];
        this.yLabels[i].attr('text', "" + this.options.labels[i] + ": " + (this.yLabelFormat(y)));
      }
      maxLabelWidth = Math.max.apply(null, (function() {
        var _j, _len1, _ref1, _results;
        _ref1 = this.yLabels;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          l = _ref1[_j];
          _results.push(l.getBBox().width);
        }
        return _results;
      }).call(this));
      maxLabelWidth = Math.max(maxLabelWidth, this.xLabel.getBBox().width);
      this.hover.attr('width', maxLabelWidth + this.options.hoverPaddingX * 2);
      this.hover.attr('x', -this.options.hoverPaddingX - maxLabelWidth / 2);
      yloc = Math.min.apply(null, ((function() {
        var _j, _len1, _ref1, _results;
        _ref1 = row._y;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          y = _ref1[_j];
          if (y != null) {
            _results.push(y);
          }
        }
        return _results;
      })()).concat(this.bottom));
      if (yloc > this.hoverHeight + this.options.hoverPaddingY * 2 + this.options.hoverMargin + this.top) {
        yloc = yloc - this.hoverHeight / 2 - this.options.hoverPaddingY - this.options.hoverMargin;
      } else {
        yloc = yloc + this.hoverHeight / 2 + this.options.hoverPaddingY + this.options.hoverMargin;
      }
      yloc = Math.max(this.top + this.hoverHeight / 2 + this.options.hoverPaddingY, yloc);
      yloc = Math.min(this.bottom - this.hoverHeight / 2 - this.options.hoverPaddingY, yloc);
      xloc = Math.min(this.right - maxLabelWidth / 2 - this.options.hoverPaddingX, this.data[index]._x);
      xloc = Math.max(this.left + maxLabelWidth / 2 + this.options.hoverPaddingX, xloc);
      return this.hoverSet.attr('transform', "t" + xloc + "," + yloc);
    };

    Line.prototype.hideHover = function() {
      return this.hoverSet.hide();
    };

    Line.prototype.hilight = function(index) {
      var i, _i, _j, _ref, _ref1;
      if (this.prevHilight !== null && this.prevHilight !== index) {
        for (i = _i = 0, _ref = this.seriesPoints.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
          if (this.seriesPoints[i][this.prevHilight]) {
            this.seriesPoints[i][this.prevHilight].animate(this.pointShrink);
          }
        }
      }
      if (index !== null && this.prevHilight !== index) {
        for (i = _j = 0, _ref1 = this.seriesPoints.length - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
          if (this.seriesPoints[i][index]) {
            this.seriesPoints[i][index].animate(this.pointGrow);
          }
        }
        this.updateHover(index);
      }
      this.prevHilight = index;
      if (!(index != null)) {
        return this.hideHover();
      }
    };

    Line.prototype.updateHilight = function(x) {
      var hoverIndex, _i, _ref;
      x -= this.el.offset().left;
      for (hoverIndex = _i = 0, _ref = this.hoverMargins.length; 0 <= _ref ? _i < _ref : _i > _ref; hoverIndex = 0 <= _ref ? ++_i : --_i) {
        if (this.hoverMargins[hoverIndex] > x) {
          break;
        }
      }
      return this.hilight(hoverIndex);
    };

    Line.prototype.colorForSeries = function(index) {
      return this.options.lineColors[index % this.options.lineColors.length];
    };

    Line.prototype.strokeWidthForSeries = function(index) {
      return this.options.pointWidths[index % this.options.pointWidths.length];
    };

    Line.prototype.strokeForSeries = function(index) {
      return this.options.pointStrokeColors[index % this.options.pointStrokeColors.length];
    };

    Line.prototype.pointFillColorForSeries = function(index) {
      return this.options.pointFillColors[index % this.options.pointFillColors.length];
    };

    return Line;

  })(Morris.Grid);

  Morris.labelSeries = function(dmin, dmax, pxwidth, specName, xLabelFormat) {
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
    if (spec === void 0) {
      spec = Morris.LABEL_SPECS["second"];
    }
    if (xLabelFormat) {
      spec = $.extend({}, spec, {
        fmt: xLabelFormat
      });
    }
    d = spec.start(d0);
    ret = [];
    while ((t = d.getTime()) <= dmax) {
      if (t >= dmin) {
        ret.push([spec.fmt(d), t]);
      }
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
    "decade": {
      span: 172800000000,
      start: function(d) {
        return new Date(d.getFullYear() - d.getFullYear() % 10, 0, 1);
      },
      fmt: function(d) {
        return "" + (d.getFullYear());
      },
      incr: function(d) {
        return d.setFullYear(d.getFullYear() + 10);
      }
    },
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

  Morris.AUTO_LABEL_ORDER = ["decade", "year", "month", "day", "hour", "30min", "15min", "10min", "5min", "minute", "30sec", "15sec", "10sec", "5sec", "second"];

  Morris.Area = (function(_super) {

    __extends(Area, _super);

    function Area(options) {
      if (!(this instanceof Morris.Area)) {
        return new Morris.Area(options);
      }
      this.cumulative = true;
      Area.__super__.constructor.call(this, options);
    }

    Area.prototype.calcPoints = function() {
      var row, total, y, _i, _len, _ref, _results;
      _ref = this.data;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        row._x = this.transX(row.x);
        total = 0;
        _results.push(row._y = (function() {
          var _j, _len1, _ref1, _results1;
          _ref1 = row.y;
          _results1 = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            y = _ref1[_j];
            total += y || 0;
            _results1.push(this.transY(total));
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Area.prototype.drawSeries = function() {
      var i, path, _i, _ref;
      for (i = _i = _ref = this.options.ykeys.length - 1; _ref <= 0 ? _i <= 0 : _i >= 0; i = _ref <= 0 ? ++_i : --_i) {
        path = this.paths[i];
        if (path !== null) {
          path = path + ("L" + (this.transX(this.xmax)) + "," + this.bottom + "L" + (this.transX(this.xmin)) + "," + this.bottom + "Z");
          this.r.path(path).attr('fill', this.fillForSeries(i)).attr('stroke-width', 0);
        }
      }
      return Area.__super__.drawSeries.call(this);
    };

    Area.prototype.fillForSeries = function(i) {
      var color;
      color = Raphael.rgb2hsl(this.colorForSeries(i));
      return Raphael.hsl(color.h, Math.min(255, color.s * 0.75), Math.min(255, color.l * 1.25));
    };

    return Area;

  })(Morris.Line);

  Morris.Bar = (function(_super) {

    __extends(Bar, _super);

    function Bar(options) {
      this.updateHilight = __bind(this.updateHilight, this);

      this.hilight = __bind(this.hilight, this);

      this.updateHover = __bind(this.updateHover, this);
      if (!(this instanceof Morris.Bar)) {
        return new Morris.Bar(options);
      }
      Bar.__super__.constructor.call(this, $.extend({}, options, {
        parseTime: false
      }));
    }

    Bar.prototype.init = function() {
      var touchHandler,
        _this = this;
      this.cumulative = this.options.stacked;
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

    Bar.prototype.defaults = {
      barSizeRatio: 0.75,
      barGap: 3,
      barColors: ['#0b62a4', '#7a92a3', '#4da74d', '#afd8f8', '#edc240', '#cb4b4b', '#9440ed'],
      hoverPaddingX: 10,
      hoverPaddingY: 5,
      hoverMargin: 10,
      hoverFillColor: '#fff',
      hoverBorderColor: '#ccc',
      hoverBorderWidth: 2,
      hoverOpacity: 0.95,
      hoverLabelColor: '#444',
      hoverFontSize: 12,
      hideHover: false
    };

    Bar.prototype.calc = function() {
      this.calcBars();
      return this.calcHoverMargins();
    };

    Bar.prototype.calcBars = function() {
      var idx, row, y, _i, _len, _ref, _results;
      _ref = this.data;
      _results = [];
      for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
        row = _ref[idx];
        row._x = this.left + this.width * (idx + 0.5) / this.data.length;
        _results.push(row._y = (function() {
          var _j, _len1, _ref1, _results1;
          _ref1 = row.y;
          _results1 = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            y = _ref1[_j];
            if (y != null) {
              _results1.push(this.transY(y));
            } else {
              _results1.push(null);
            }
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Bar.prototype.calcHoverMargins = function() {
      var i;
      return this.hoverMargins = (function() {
        var _i, _ref, _results;
        _results = [];
        for (i = _i = 1, _ref = this.data.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
          _results.push(this.left + i * this.width / this.data.length);
        }
        return _results;
      }).call(this);
    };

    Bar.prototype.draw = function() {
      this.drawXAxis();
      this.drawSeries();
      this.drawHover();
      return this.hilight(this.options.hideHover ? null : this.data.length - 1);
    };

    Bar.prototype.drawXAxis = function() {
      var i, label, labelBox, prevLabelMargin, row, xLabelMargin, ypos, _i, _ref, _results;
      ypos = this.bottom + this.options.gridTextSize * 1.25;
      xLabelMargin = 50;
      prevLabelMargin = null;
      _results = [];
      for (i = _i = 0, _ref = this.data.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        row = this.data[this.data.length - 1 - i];
        label = this.r.text(row._x, ypos, row.label).attr('font-size', this.options.gridTextSize).attr('fill', this.options.gridTextColor);
        labelBox = label.getBBox();
        if ((!(prevLabelMargin != null) || prevLabelMargin >= labelBox.x + labelBox.width) && labelBox.x >= 0 && (labelBox.x + labelBox.width) < this.el.width()) {
          _results.push(prevLabelMargin = labelBox.x - xLabelMargin);
        } else {
          _results.push(label.remove());
        }
      }
      return _results;
    };

    Bar.prototype.drawSeries = function() {
      var barWidth, bottom, groupWidth, idx, lastTop, left, leftPadding, numBars, row, sidx, size, top, ypos, zeroPos;
      groupWidth = this.width / this.options.data.length;
      numBars = this.options.stacked != null ? 1 : this.options.ykeys.length;
      barWidth = (groupWidth * this.options.barSizeRatio - this.options.barGap * (numBars - 1)) / numBars;
      leftPadding = groupWidth * (1 - this.options.barSizeRatio) / 2;
      zeroPos = this.ymin <= 0 && this.ymax >= 0 ? this.transY(0) : null;
      return this.bars = (function() {
        var _i, _len, _ref, _results;
        _ref = this.data;
        _results = [];
        for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
          row = _ref[idx];
          lastTop = 0;
          _results.push((function() {
            var _j, _len1, _ref1, _results1;
            _ref1 = row._y;
            _results1 = [];
            for (sidx = _j = 0, _len1 = _ref1.length; _j < _len1; sidx = ++_j) {
              ypos = _ref1[sidx];
              if (ypos !== null) {
                if (zeroPos) {
                  top = Math.min(ypos, zeroPos);
                  bottom = Math.max(ypos, zeroPos);
                } else {
                  top = ypos;
                  bottom = this.bottom;
                }
                left = this.left + idx * groupWidth + leftPadding;
                if (!this.options.stacked) {
                  left += sidx * (barWidth + this.options.barGap);
                }
                size = bottom - top;
                if (this.options.stacked) {
                  top -= lastTop;
                }
                this.r.rect(left, top, barWidth, size).attr('fill', this.colorFor(row, sidx, 'bar')).attr('stroke-width', 0);
                _results1.push(lastTop += size);
              } else {
                _results1.push(null);
              }
            }
            return _results1;
          }).call(this));
        }
        return _results;
      }).call(this);
    };

    Bar.prototype.drawHover = function() {
      var i, yLabel, _i, _ref, _results;
      this.hoverHeight = this.options.hoverFontSize * 1.5 * (this.options.ykeys.length + 1);
      this.hover = this.r.rect(-10, -this.hoverHeight / 2 - this.options.hoverPaddingY, 20, this.hoverHeight + this.options.hoverPaddingY * 2, 10).attr('fill', this.options.hoverFillColor).attr('stroke', this.options.hoverBorderColor).attr('stroke-width', this.options.hoverBorderWidth).attr('opacity', this.options.hoverOpacity);
      this.xLabel = this.r.text(0, (this.options.hoverFontSize * 0.75) - this.hoverHeight / 2, '').attr('fill', this.options.hoverLabelColor).attr('font-weight', 'bold').attr('font-size', this.options.hoverFontSize);
      this.hoverSet = this.r.set();
      this.hoverSet.push(this.hover);
      this.hoverSet.push(this.xLabel);
      this.yLabels = [];
      _results = [];
      for (i = _i = 0, _ref = this.options.ykeys.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        yLabel = this.r.text(0, this.options.hoverFontSize * 1.5 * (i + 1.5) - this.hoverHeight / 2, '').attr('font-size', this.options.hoverFontSize);
        this.yLabels.push(yLabel);
        _results.push(this.hoverSet.push(yLabel));
      }
      return _results;
    };

    Bar.prototype.updateHover = function(index) {
      var i, l, maxLabelWidth, row, xloc, y, yloc, _i, _len, _ref;
      this.hoverSet.show();
      row = this.data[index];
      this.xLabel.attr('text', row.label);
      _ref = row.y;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        y = _ref[i];
        this.yLabels[i].attr('fill', this.colorFor(row, i, 'hover'));
        this.yLabels[i].attr('text', "" + this.options.labels[i] + ": " + (this.yLabelFormat(y)));
      }
      maxLabelWidth = Math.max.apply(null, (function() {
        var _j, _len1, _ref1, _results;
        _ref1 = this.yLabels;
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          l = _ref1[_j];
          _results.push(l.getBBox().width);
        }
        return _results;
      }).call(this));
      maxLabelWidth = Math.max(maxLabelWidth, this.xLabel.getBBox().width);
      this.hover.attr('width', maxLabelWidth + this.options.hoverPaddingX * 2);
      this.hover.attr('x', -this.options.hoverPaddingX - maxLabelWidth / 2);
      yloc = (this.bottom + this.top) / 2;
      xloc = Math.min(this.right - maxLabelWidth / 2 - this.options.hoverPaddingX, this.data[index]._x);
      xloc = Math.max(this.left + maxLabelWidth / 2 + this.options.hoverPaddingX, xloc);
      return this.hoverSet.attr('transform', "t" + xloc + "," + yloc);
    };

    Bar.prototype.hideHover = function() {
      return this.hoverSet.hide();
    };

    Bar.prototype.hilight = function(index) {
      if (index !== null && this.prevHilight !== index) {
        this.updateHover(index);
      }
      this.prevHilight = index;
      if (!(index != null)) {
        return this.hideHover();
      }
    };

    Bar.prototype.updateHilight = function(x) {
      var hoverIndex, _i, _ref;
      x -= this.el.offset().left;
      for (hoverIndex = _i = 0, _ref = this.hoverMargins.length; 0 <= _ref ? _i < _ref : _i > _ref; hoverIndex = 0 <= _ref ? ++_i : --_i) {
        if (this.hoverMargins[hoverIndex] > x) {
          break;
        }
      }
      return this.hilight(hoverIndex);
    };

    Bar.prototype.colorFor = function(row, sidx, type) {
      var r, s;
      if (typeof this.options.barColors === 'function') {
        r = {
          x: row.x,
          y: row.y[sidx],
          label: row.label
        };
        s = {
          index: sidx,
          key: this.options.ykeys[sidx],
          label: this.options.labels[sidx]
        };
        return this.options.barColors.call(this, r, s, type);
      } else {
        return this.options.barColors[sidx % this.options.barColors.length];
      }
    };

    return Bar;

  })(Morris.Grid);

  Array.prototype.isUniform = function(value, compare) {
    var el, _i, _len;
    value = value != null ? value : this[0];
    compare = compare != null ? compare : function(a, b) {
      return a === b;
    };
    if (this.length === 0) {
      return true;
    }
    for (_i = 0, _len = this.length; _i < _len; _i++) {
      el = this[_i];
      if (!compare(el, value)) {
        return false;
      }
    }
    return true;
  };

  Morris.Pie = (function(_super) {

    __extends(Pie, _super);

    Pie.prototype.pieDefaults = {
      colors: ['#0B62A4', '#3980B5', '#679DC6', '#95BBD7', '#B0CCE1', '#095791', '#095085', '#083E67', '#052C48', '#042135'],
      idKey: "label",
      stroke: "#FFFFFF",
      strokeWidth: 3,
      sort: false,
      formatter: Morris.commas,
      showLabel: "hover",
      drawOut: 5,
      includeZeros: false
    };

    function Pie(options) {
      var _this = this;
      if (!(this instanceof Morris.Pie)) {
        return new Morris.Pie(options);
      }
      if (typeof options.element === 'string') {
        this.el = $(document.getElementById(options.element));
      } else {
        this.el = $(options.element);
      }
      if (this.el === null || this.el.length === 0) {
        throw new Error("Container element not found.");
      }
      if (options.data === void 0 || options.data.length === 0) {
        return;
      }
      this.options = $.extend({}, this.pieDefaults, options);
      this.setData(options.data);
      if (this.options.showLabel === "hover") {
        this.el.mouseout(function(evt) {
          return _this.hideLabel();
        });
      }
      if (this.options.showLabel !== true) {
        this.el.mouseout(function(evt) {
          return _this.deselect();
        });
      }
      this.redraw();
    }

    Pie.prototype.setData = function(data) {
      var i, row, total, _i, _j, _len, _len1, _ref, _ref1;
      total = data.reduce(function(x, y) {
        return {
          value: x.value + y.value
        };
      });
      if (total.value === 0) {
        total.value = 1;
      }
      this.data = [];
      for (i = _i = 0, _len = data.length; _i < _len; i = ++_i) {
        row = data[i];
        this.data.push({
          label: row.label,
          value: this.options.formatter.call(null, row.value, row),
          segment: row.value / total.value * 100,
          id: row[this.options.idKey]
        });
      }
      if (this.data.isUniform(0)) {
        _ref = this.data;
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          row = _ref[_j];
          row.segment = 100 / this.data.length;
        }
      }
      if ((_ref1 = this.options.sortData) === true || _ref1 === "asc") {
        return this.data = this.data.sort(function(a, b) {
          return a.segment > b.segment;
        });
      } else if (this.options.sortData === "desc") {
        return this.data = this.data.sort(function(a, b) {
          return a.segment < b.segment;
        });
      }
    };

    Pie.prototype.redraw = function() {
      this.clear();
      this.calc();
      return this.draw();
    };

    Pie.prototype.clear = function() {
      this.label = null;
      this.middles = [];
      this.segments = [];
      this.el.empty();
      return this.r = new Raphael(this.el[0]);
    };

    Pie.prototype.calc = function() {
      this.width = this.el.width();
      this.height = this.el.height();
      if (this.options.showLabel !== false) {
        this.height -= 30;
      }
      this.cx = this.width / 2.0;
      this.cy = this.height / 2.0;
      this.radius = 0.8 * Math.min(this.cx, this.cy);
      if (this.options.showLabel !== false) {
        return this.cy += 30;
      }
    };

    Pie.prototype.select = function(i) {
      var s, segment, _i, _len, _ref;
      _ref = this.segments;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        s = _ref[_i];
        s.deselect();
      }
      segment = i;
      if (typeof i === "number") {
        segment = this.segments[i];
      }
      segment.select();
      this.fire("hover", segment.data.id, segment.data);
      if (this.options.showLabel !== false) {
        return this.showLabel(segment);
      }
    };

    Pie.prototype.showLabel = function(segment) {
      if (this.label === null) {
        this.label = this.r.text(this.cx, 30, "").attr({
          "font-size": 15,
          "font-weight": "bold"
        });
      }
      return this.label.attr({
        fill: segment.color,
        text: "" + segment.data.label + ": " + segment.data.value
      });
    };

    Pie.prototype.hideLabel = function() {
      this.deselect();
      if (this.label !== null) {
        return this.label.attr("text", "");
      }
    };

    Pie.prototype.deselect = function() {
      var s, _i, _len, _ref, _results;
      _ref = this.segments;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        s = _ref[_i];
        _results.push(s.deselect());
      }
      return _results;
    };

    Pie.prototype.draw = function() {
      if (this.data.length === 1) {
        return this.drawSingle();
      } else {
        return this.drawSegments();
      }
    };

    Pie.prototype.drawSingle = function() {
      var segment,
        _this = this;
      segment = this.genSingle(this.data[0]);
      segment.render(this.r);
      segment.on("hover", function(s) {
        return _this.select(s);
      });
      segment.on("click", function(id, data) {
        return _this.fire("click", id, data);
      });
      this.segments.push(segment);
      if (this.options.showLabel === true) {
        return this.select(0);
      }
    };

    Pie.prototype.drawSegments = function() {
      var angle, from, i, mangle, row, segment, to, _i, _len, _ref, _ref1,
        _this = this;
      angle = 0;
      _ref = this.data;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        row = _ref[i];
        if (row.segment === 0) {
          continue;
        }
        mangle = angle - 360 * row.segment / 200;
        if (!i) {
          angle = 90 - mangle;
          mangle = angle - 360.0 * row.segment / 200;
        }
        _ref1 = [angle, angle - 3.6 * row.segment], from = _ref1[0], to = _ref1[1];
        angle = to;
        segment = this.genSegment(row, from, to, i);
        segment.render(this.r);
        segment.on("hover", function(s) {
          return _this.select(s);
        });
        segment.on("click", function(id, data) {
          return _this.fire("click", id, data);
        });
        this.segments.push(segment);
      }
      if (this.options.showLabel === true) {
        return this.select(this.data.length - 1);
      }
    };

    Pie.prototype.genSingle = function(row) {
      return new Morris.Pie.FullSegment(this.cx, this.cy, this.radius, this.getColor(0), row, this.options);
    };

    Pie.prototype.genSegment = function(row, from, to, i) {
      return new Morris.Pie.Segment(this.cx, this.cy, this.radius, from, to, this.getColor(i), row, this.options);
    };

    Pie.prototype.getColor = function(i) {
      if (typeof this.options.colors === "function") {
        return this.options.colors.call(this.data[i], i, this.options);
      } else {
        return this.options.colors[i % this.options.colors.length];
      }
    };

    return Pie;

  })(Morris.EventEmitter);

  Morris.Pie.FullSegment = (function(_super) {

    __extends(FullSegment, _super);

    function FullSegment(cx, cy, radius, color, data, options) {
      this.cx = cx;
      this.cy = cy;
      this.radius = radius;
      this.color = color;
      this.data = data;
      this.options = options;
      this.selected = false;
    }

    FullSegment.prototype.render = function(r) {
      var _this = this;
      return this.seg = r.circle(this.cx, this.cy, this.radius - this.options.drawOut).attr({
        fillr: this.color,
        stroke: this.options.stroke,
        "stroke-width": this.options.strokeWidth,
        "stroke-linejoin": "round"
      }).hover(function() {
        return _this.fire("hover", _this);
      }).click(function() {
        return _this.fire("click", _this.data.id, _this.data);
      });
    };

    FullSegment.prototype.select = function() {
      if (!this.selected) {
        this.seg.animate({
          r: this.radius
        }, 150, "<>");
        return this.selected = true;
      }
    };

    FullSegment.prototype.deselect = function() {
      if (this.selected) {
        this.seg.animate({
          r: this.radius - this.options.drawOut
        }, 150, "<>");
        return this.selected = false;
      }
    };

    return FullSegment;

  })(Morris.EventEmitter);

  Morris.Pie.Segment = (function(_super) {

    __extends(Segment, _super);

    function Segment(cx, cy, radius, from, to, color, data, options) {
      var rad;
      this.cx = cx;
      this.cy = cy;
      this.radius = radius;
      this.color = color;
      this.data = data;
      this.options = options;
      rad = Math.PI / 180;
      this.diff = Math.abs(to - from);
      this.cos = Math.cos(-(from + (to - from) / 2) * rad);
      this.sin = Math.sin(-(from + (to - from) / 2) * rad);
      this.sin_from = Math.sin(-from * rad);
      this.cos_from = Math.cos(-from * rad);
      this.sin_to = Math.sin(-to * rad);
      this.cos_to = Math.cos(-to * rad);
      this.long = +(this.diff > 180);
      this.path = this.calcSegment(this.radius - this.options.drawOut);
      this.selectedPath = this.calcSegment(this.radius);
      this.selected = false;
      this.mx = this.cx + this.radius / 2 * this.cos;
      this.my = this.cy + this.radius / 2 * this.sin;
    }

    Segment.prototype.calcArcPoints = function(r) {
      return [this.cx + r * this.cos_from, this.cy + r * this.sin_from, this.cx + r * this.cos_to, this.cy + r * this.sin_to];
    };

    Segment.prototype.calcSegment = function(r) {
      var x1, x2, y1, y2, _ref;
      _ref = this.calcArcPoints(r), x1 = _ref[0], y1 = _ref[1], x2 = _ref[2], y2 = _ref[3];
      return "M" + this.cx + "," + this.cy + "L" + x1 + "," + y1 + "A" + r + "," + r + ",0," + this.long + ",1," + x2 + "," + y2 + "Z";
    };

    Segment.prototype.render = function(r) {
      var _this = this;
      return this.seg = r.path(this.path).attr({
        fill: this.color,
        stroke: this.options.stroke,
        'stroke-width': this.options.strokeWidth,
        'stroke-linejoin': 'round'
      }).hover(function() {
        return _this.fire('hover', _this);
      }).click(function() {
        return _this.fire("click", _this.data.id, _this.data);
      });
    };

    Segment.prototype.select = function() {
      if (!this.selected) {
        this.seg.animate({
          path: this.selectedPath
        }, 150, '<>');
        return this.selected = true;
      }
    };

    Segment.prototype.deselect = function() {
      if (this.selected) {
        this.seg.animate({
          path: this.path
        }, 150, '<>');
        return this.selected = false;
      }
    };

    return Segment;

  })(Morris.EventEmitter);

  Morris.Donut = (function(_super) {

    __extends(Donut, _super);

    Donut.prototype.donutDefaults = {
      width: "50%"
    };

    function Donut(options) {
      if (!(this instanceof Morris.Donut)) {
        return new Morris.Donut(options);
      }
      Donut.__super__.constructor.call(this, $.extend({}, this.donutDefaults, options));
    }

    Donut.prototype.genSingle = function(row) {
      return new Morris.Donut.FullSegment(this.cx, this.cy, this.radius, this.getColor(0), row, this.options);
    };

    Donut.prototype.genSegment = function(row, from, to, i) {
      return new Morris.Donut.Segment(this.cx, this.cy, this.radius, from, to, this.getColor(i), row, this.options);
    };

    return Donut;

  })(Morris.Pie);

  Morris.Donut.Segment = (function(_super) {

    __extends(Segment, _super);

    function Segment(cx, cy, r, to, from, color, data, options) {
      var rad, width;
      this.cx = cx;
      this.cy = cy;
      this.r = r;
      this.color = color;
      this.data = data;
      this.options = options;
      rad = Math.PI / 180;
      this.long = +(to - from > 180);
      this.sin_from = Math.sin(-from * rad);
      this.cos_from = Math.cos(-from * rad);
      this.sin_to = Math.sin(-to * rad);
      this.cos_to = Math.cos(-to * rad);
      width = this.options.width;
      if (width.match(/[0-9]+(\.[0-9]+)?\%/)) {
        width = this.r * parseFloat(width) / 100;
      }
      this.rin = this.r - width;
      this.drawOut = this.options.drawOut;
      this.drawOutInner = 0.5 * this.options.drawOut * this.rin / this.r;
      this.selected = false;
      this.path = this.calcSegment(this.r - this.drawOut, this.rin - this.drawOutInner);
      this.selectedPath = this.calcSegment(this.r, this.rin);
    }

    Segment.prototype.calcArcPoints = function(r) {
      return [this.cx + r * this.cos_from, this.cy + r * this.sin_from, this.cx + r * this.cos_to, this.cy + r * this.sin_to];
    };

    Segment.prototype.calcSegment = function(r, rin) {
      var path, x1, x2, xx1, xx2, y1, y2, yy1, yy2, _ref, _ref1;
      _ref = this.calcArcPoints(r), x1 = _ref[0], y1 = _ref[1], x2 = _ref[2], y2 = _ref[3];
      _ref1 = this.calcArcPoints(rin), xx1 = _ref1[0], yy1 = _ref1[1], xx2 = _ref1[2], yy2 = _ref1[3];
      return path = ["M", xx1, yy1, "L", x1, y1, "A", r, r, 0, this.long, 0, x2, y2, "L", xx2, yy2, "A", rin, rin, 0, this.long, 1, xx1, yy1, "z"];
    };

    Segment.prototype.render = function(r) {
      var _this = this;
      return this.seg = r.path(this.path).attr({
        fill: this.color,
        stroke: this.options.stroke,
        'stroke-width': this.options.strokeWidth,
        'stroke-linejoin': 'round'
      }).hover(function() {
        return _this.fire('hover', _this);
      }).click(function() {
        return _this.fire("click", _this.data.id, _this.data);
      });
    };

    Segment.prototype.select = function() {
      if (!this.selected) {
        this.seg.animate({
          path: this.selectedPath
        }, 150, '<>');
        return this.selected = true;
      }
    };

    Segment.prototype.deselect = function() {
      if (this.selected) {
        this.seg.animate({
          path: this.path
        }, 150, '<>');
        return this.selected = false;
      }
    };

    return Segment;

  })(Morris.EventEmitter);

  Morris.Donut.FullSegment = (function(_super) {

    __extends(FullSegment, _super);

    function FullSegment(cx, cy, r, color, data, options) {
      this.cx = cx;
      this.cy = cy;
      this.r = r;
      this.color = color;
      this.data = data;
      this.options = options;
      if (!(this instanceof Morris.Donut.FullSegment)) {
        return new Morris.Donut.FullSegment(this.cx, this.cy, this.r, this.color, this.data, this.options);
      }
      FullSegment.__super__.constructor.call(this, this.cx, this.cy, this.r, 0, Math.PI * 2, this.color, this.data, this.options);
    }

    return FullSegment;

  })(Morris.Donut.Segment);

}).call(this);
