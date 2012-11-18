(function() {
  var $, Morris, minutesSpecHelper, secondsSpecHelper,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Morris = window.Morris = {};

  $ = jQuery;

  Morris.Module = (function() {

    function Module() {}

    Module.extend = function(obj) {
      var key, value, _ref;
      for (key in obj) {
        value = obj[key];
        if (key !== 'extended' && key !== 'included') {
          this[key] = value;
        }
      }
      if ((_ref = obj.extended) != null) {
        _ref.apply(this);
      }
      return this;
    };

    Module.include = function(obj) {
      var key, value, _ref;
      for (key in obj) {
        value = obj[key];
        if (key !== 'extended' && key !== 'included') {
          this.prototype[key] = value;
        }
      }
      return (_ref = obj.included) != null ? _ref.apply(this) : void 0;
    };

    return Module;

  })();

  Morris.EventEmitter = (function(_super) {

    __extends(EventEmitter, _super);

    function EventEmitter() {
      return EventEmitter.__super__.constructor.apply(this, arguments);
    }

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

  })(Morris.Module);

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
      if (this.postInit) {
        this.postInit();
      }
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
              if (typeof yval !== 'number') {
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

  Morris.Hover = {
    hoverConfigure: function(options) {
      return this.hoverOptions = $.extend({}, this.hoverDefaults, options != null ? options : {});
    },
    hoverInit: function() {
      if (this.hoverOptions.enableHover) {
        this.hover = this.hoverBuild();
        this.hoverBindEvents();
        return this.hoverShow(this.hoverOptions.hideHover ? null : this.data.length - 1);
      }
    },
    hoverDefaults: {
      enableHover: true,
      popupClass: "morris-popup",
      hideHover: false,
      allowOverflow: false,
      pointMargin: 10,
      hoverFill: function(index, row) {
        return this.hoverFill(index, row);
      }
    },
    hoverBindEvents: function() {
      var touchHandler,
        _this = this;
      this.el.mousemove(function(evt) {
        return _this.hoverUpdate(evt.pageX);
      });
      if (this.hoverOptions.hideHover) {
        this.el.mouseout(function(evt) {
          return _this.hoverShow(null);
        });
      }
      touchHandler = function(evt) {
        var touch;
        touch = evt.originalEvent.touches[0] || evt.originalEvent.changedTouches[0];
        _this.hoverUpdate(touch.pageX);
        return touch;
      };
      this.el.bind('touchstart', touchHandler);
      this.el.bind('touchmove', touchHandler);
      this.el.bind('touchend', touchHandler);
      this.hover.mousemove(function(evt) {
        return evt.stopPropagation();
      });
      this.hover.mouseout(function(evt) {
        return evt.stopPropagation();
      });
      this.hover.bind('touchstart', function(evt) {
        return evt.stopPropagation();
      });
      this.hover.bind('touchmove', function(evt) {
        return evt.stopPropagation();
      });
      return this.hover.bind('touchend', function(evt) {
        return evt.stopPropagation();
      });
    },
    hoverCalculateMargins: function() {
      var i;
      return this.hoverMargins = (function() {
        var _i, _ref, _results;
        _results = [];
        for (i = _i = 1, _ref = this.data.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
          _results.push(this.left + i * this.width / this.data.length);
        }
        return _results;
      }).call(this);
    },
    hoverBuild: function() {
      var hover;
      hover = $("<div/>");
      hover.addClass("" + this.hoverOptions.popupClass + " js-morris-popup");
      hover.appendTo(this.el);
      hover.hide();
      return hover;
    },
    hoverUpdate: function(x) {
      var hoverIndex, _i, _ref;
      x -= this.el.offset().left;
      for (hoverIndex = _i = 0, _ref = this.hoverMargins.length; 0 <= _ref ? _i < _ref : _i > _ref; hoverIndex = 0 <= _ref ? ++_i : --_i) {
        if (this.hoverMargins[hoverIndex] > x) {
          break;
        }
      }
      return this.hoverShow(hoverIndex);
    },
    hoverShow: function(index) {
      if (index !== null) {
        this.hover.html("");
        this.hoverOptions.hoverFill.call(this, index, this.data[index]);
        this.hoverPosition(index);
        this.fire("hover.show", index);
        this.hover.show();
      }
      if (!(index != null)) {
        return this.hoverHide();
      }
    },
    hoverHide: function() {
      return this.hover.hide();
    },
    colorFor: function(row, i, type) {
      return "inherit";
    },
    yLabelFormat: function(label) {
      return Morris.commas(label);
    },
    hoverPosition: function(index) {
      var x, y, _ref;
      _ref = this.hoverGetPosition(index), x = _ref[0], y = _ref[1];
      return this.hover.css({
        top: "" + (this.el.offset().top + y) + "px",
        left: "" + (this.el.offset().left + x) + "px"
      });
    },
    hoverGetPosition: function(index) {
      var miny, row, x, y;
      row = this.data[index];
      this.hoverWidth = this.hover.outerWidth(true);
      this.hoverHeight = this.hover.outerHeight(true);
      miny = y = Math.min.apply(null, ((function() {
        var _i, _len, _ref, _results;
        _ref = row._y;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          y = _ref[_i];
          if (y !== null) {
            _results.push(y);
          }
        }
        return _results;
      })()).concat(this.bottom));
      x = row._x - this.hoverWidth / 2;
      y = miny;
      y = y - this.hoverHeight - this.hoverOptions.pointMargin;
      if (!this.hoverOptions.allowOverflow) {
        if (x < this.left) {
          x = row._x + this.hoverOptions.pointMargin;
        } else if (x > this.right - this.hoverWidth) {
          x = row._x - this.hoverWidth - this.hoverOptions.pointMargin;
        }
        y = Math.max(y, this.top);
        y = Math.min(y, this.bottom - this.hoverHeight - this.hoverOptions.pointMargin);
        if (y - miny < this.hoverWidth + this.hoverOptions.pointMargin) {
          y = miny + this.hoverOptions.pointMargin;
        }
      }
      return [x, y];
    },
    hoverFill: function(index, row) {
      var i, xLabel, y, yLabel, _i, _len, _ref, _results;
      xLabel = $("<h4/>");
      xLabel.text(row.label);
      xLabel.appendTo(this.hover);
      _ref = row.y;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        y = _ref[i];
        yLabel = $("<p/>");
        yLabel.css("color", this.colorFor(row, i, "hover"));
        yLabel.text("" + this.options.labels[i] + ": " + (this.yLabelFormat(y)));
        _results.push(yLabel.appendTo(this.hover));
      }
      return _results;
    }
  };

  Morris.Line = (function(_super) {

    __extends(Line, _super);

    Line.include(Morris.Hover);

    function Line(options) {
      this.updateHilight = __bind(this.updateHilight, this);

      this.hilight = __bind(this.hilight, this);
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
      this.hoverConfigure(this.options.hoverOptions);
      if (this.options.hilight) {
        this.prevHilight = null;
        this.el.mousemove(function(evt) {
          return _this.updateHilight(evt.pageX);
        });
        if (this.options.hilightAutoHide) {
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
      }
    };

    Line.prototype.postInit = function() {
      return this.hoverInit();
    };

    Line.prototype.defaults = {
      lineWidth: 3,
      pointSize: 4,
      lineColors: ['#0b62a4', '#7A92A3', '#4da74d', '#afd8f8', '#edc240', '#cb4b4b', '#9440ed'],
      pointWidths: [1],
      pointStrokeColors: ['#ffffff'],
      pointFillColors: [],
      smooth: true,
      hilight: true,
      hilightAutoHide: false,
      xLabels: 'auto',
      xLabelFormat: null
    };

    Line.prototype.calc = function() {
      this.calcPoints();
      this.hoverCalculateMargins();
      this.generatePaths();
      return this.calcHilightMargins();
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
              _results1.push(null);
            }
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Line.prototype.calcHilightMargins = function() {
      var i, r;
      return this.hilightMargins = (function() {
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

    Line.prototype.hoverCalculateMargins = function() {
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
      var coords, i, r, smooth;
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
              if (r._y[i] !== null) {
                _results1.push({
                  x: r._x,
                  y: r._y[i]
                });
              }
            }
            return _results1;
          }).call(this);
          if (coords.length > 1) {
            _results.push(this.createPath(coords, smooth));
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
      if (this.options.hilight) {
        return this.hilight(this.options.hilightAutoHide ? null : this.data.length - 1);
      }
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
          this.r.path(path).attr('stroke', this.colorFor(row, i, 'line')).attr('stroke-width', this.options.lineWidth);
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
            if (row._y[i] === null) {
              circle = null;
            } else {
              circle = this.r.circle(row._x, row._y[i], this.options.pointSize).attr('fill', this.colorFor(row, i, 'point')).attr('stroke-width', this.strokeWidthForSeries(i)).attr('stroke', this.strokeForSeries(i));
            }
            _results1.push(this.seriesPoints[i].push(circle));
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    Line.prototype.createPath = function(coords, smooth) {
      var c, g, grads, i, ix, lc, lg, path, x1, x2, y1, y2, _i, _ref;
      path = "";
      if (smooth) {
        grads = this.gradients(coords);
        for (i = _i = 0, _ref = coords.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
          c = coords[i];
          if (i === 0) {
            path += "M" + c.x + "," + c.y;
          } else {
            g = grads[i];
            lc = coords[i - 1];
            lg = grads[i - 1];
            ix = (c.x - lc.x) / 4;
            x1 = lc.x + ix;
            y1 = Math.min(this.bottom, lc.y + ix * lg);
            x2 = c.x - ix;
            y2 = Math.min(this.bottom, c.y - ix * g);
            path += "C" + x1 + "," + y1 + "," + x2 + "," + y2 + "," + c.x + "," + c.y;
          }
        }
      } else {
        path = "M" + ((function() {
          var _j, _len, _results;
          _results = [];
          for (_j = 0, _len = coords.length; _j < _len; _j++) {
            c = coords[_j];
            _results.push("" + c.x + "," + c.y);
          }
          return _results;
        })()).join("L");
      }
      return path;
    };

    Line.prototype.gradients = function(coords) {
      var c, i, _i, _len, _results;
      _results = [];
      for (i = _i = 0, _len = coords.length; _i < _len; i = ++_i) {
        c = coords[i];
        if (i === 0) {
          _results.push((coords[1].y - c.y) / (coords[1].x - c.x));
        } else if (i === (coords.length - 1)) {
          _results.push((c.y - coords[i - 1].y) / (c.x - coords[i - 1].x));
        } else {
          _results.push((coords[i + 1].y - coords[i - 1].y) / (coords[i + 1].x - coords[i - 1].x));
        }
      }
      return _results;
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
      }
      return this.prevHilight = index;
    };

    Line.prototype.updateHilight = function(x) {
      var hilightIndex, _i, _ref;
      x -= this.el.offset().left;
      for (hilightIndex = _i = 0, _ref = this.hilightMargins.length; 0 <= _ref ? _i < _ref : _i > _ref; hilightIndex = 0 <= _ref ? ++_i : --_i) {
        if (this.hilightMargins[hilightIndex] > x) {
          break;
        }
      }
      return this.hilight(hilightIndex);
    };

    Line.prototype.strokeWidthForSeries = function(index) {
      return this.options.pointWidths[index % this.options.pointWidths.length];
    };

    Line.prototype.strokeForSeries = function(index) {
      return this.options.pointStrokeColors[index % this.options.pointStrokeColors.length];
    };

    Line.prototype.colorFor = function(row, sidx, type) {
      if (typeof this.options.lineColors === 'function') {
        return this.options.lineColors.call(this, row, sidx, type);
      } else if (type === 'point') {
        return this.options.pointFillColors[sidx % this.options.pointFillColors.length] || this.options.lineColors[sidx % this.options.lineColors.length];
      } else {
        return this.options.lineColors[sidx % this.options.lineColors.length];
      }
    };

    return Line;

  })(Morris.Grid);

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
      color = Raphael.rgb2hsl(this.colorFor(this.data[i], i, 'line'));
      return Raphael.hsl(color.h, Math.min(255, color.s * 0.75), Math.min(255, color.l * 1.25));
    };

    return Area;

  })(Morris.Line);

  Morris.Bar = (function(_super) {

    __extends(Bar, _super);

    Bar.include(Morris.Hover);

    Bar.prototype.hoverGetPosition = function(index) {
      var x, y, _ref;
      _ref = Morris.Hover.hoverGetPosition.call(this, index), x = _ref[0], y = _ref[1];
      return [x, (this.top + this.bottom) / 2 - this.hoverHeight / 2];
    };

    function Bar(options) {
      if (!(this instanceof Morris.Bar)) {
        return new Morris.Bar(options);
      }
      Bar.__super__.constructor.call(this, $.extend({}, options, {
        parseTime: false
      }));
    }

    Bar.prototype.init = function() {
      return this.hoverConfigure(this.options.hoverOptions);
    };

    Bar.prototype.postInit = function() {
      return this.hoverInit();
    };

    Bar.prototype.defaults = {
      barSizeRatio: 0.75,
      barGap: 3,
      barColors: ['#0b62a4', '#7a92a3', '#4da74d', '#afd8f8', '#edc240', '#cb4b4b', '#9440ed']
    };

    Bar.prototype.calc = function() {
      this.calcBars();
      return this.hoverCalculateMargins();
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

    Bar.prototype.draw = function() {
      this.drawXAxis();
      return this.drawSeries();
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
      var barWidth, bottom, groupWidth, idx, left, leftPadding, numBars, row, sidx, top, ypos, zeroPos;
      groupWidth = this.width / this.options.data.length;
      numBars = this.options.ykeys.length;
      barWidth = (groupWidth * this.options.barSizeRatio - this.options.barGap * (numBars - 1)) / numBars;
      leftPadding = groupWidth * (1 - this.options.barSizeRatio) / 2;
      zeroPos = this.ymin <= 0 && this.ymax >= 0 ? this.transY(0) : null;
      return this.bars = (function() {
        var _i, _len, _ref, _results;
        _ref = this.data;
        _results = [];
        for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
          row = _ref[idx];
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
                left = this.left + idx * groupWidth + leftPadding + sidx * (barWidth + this.options.barGap);
                _results1.push(this.r.rect(left, top, barWidth, bottom - top).attr('fill', this.colorFor(row, sidx, 'bar')).attr('stroke-width', 0));
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

  Morris.Donut = (function() {

    Donut.prototype.defaults = {
      colors: ['#0B62A4', '#3980B5', '#679DC6', '#95BBD7', '#B0CCE1', '#095791', '#095085', '#083E67', '#052C48', '#042135'],
      formatter: Morris.commas
    };

    function Donut(options) {
      this.select = __bind(this.select, this);
      if (!(this instanceof Morris.Donut)) {
        return new Morris.Donut(options);
      }
      if (typeof options.element === 'string') {
        this.el = $(document.getElementById(options.element));
      } else {
        this.el = $(options.element);
      }
      this.options = $.extend({}, this.defaults, options);
      if (this.el === null || this.el.length === 0) {
        throw new Error("Graph placeholder not found.");
      }
      if (options.data === void 0 || options.data.length === 0) {
        return;
      }
      this.data = options.data;
      this.redraw();
    }

    Donut.prototype.redraw = function() {
      var C, cx, cy, d, idx, last, max_value, min, next, seg, total, w, x, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _results;
      this.el.empty();
      this.r = new Raphael(this.el[0]);
      cx = this.el.width() / 2;
      cy = this.el.height() / 2;
      w = (Math.min(cx, cy) - 10) / 3;
      total = 0;
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        x = _ref[_i];
        total += x.value;
      }
      min = 5 / (2 * w);
      C = 1.9999 * Math.PI - min * this.data.length;
      last = 0;
      idx = 0;
      this.segments = [];
      _ref1 = this.data;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        d = _ref1[_j];
        next = last + min + C * (d.value / total);
        seg = new Morris.DonutSegment(cx, cy, w * 2, w, last, next, this.options.colors[idx % this.options.colors.length], d);
        seg.render(this.r);
        this.segments.push(seg);
        seg.on('hover', this.select);
        last = next;
        idx += 1;
      }
      this.text1 = this.r.text(cx, cy - 10, '').attr({
        'font-size': 15,
        'font-weight': 800
      });
      this.text2 = this.r.text(cx, cy + 10, '').attr({
        'font-size': 14
      });
      max_value = Math.max.apply(null, (function() {
        var _k, _len2, _ref2, _results;
        _ref2 = this.data;
        _results = [];
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          d = _ref2[_k];
          _results.push(d.value);
        }
        return _results;
      }).call(this));
      idx = 0;
      _ref2 = this.data;
      _results = [];
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        d = _ref2[_k];
        if (d.value === max_value) {
          this.select(idx);
          break;
        }
        _results.push(idx += 1);
      }
      return _results;
    };

    Donut.prototype.select = function(idx) {
      var s, segment, _i, _len, _ref;
      _ref = this.segments;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        s = _ref[_i];
        s.deselect();
      }
      if (typeof idx === 'number') {
        segment = this.segments[idx];
      } else {
        segment = idx;
      }
      segment.select();
      return this.setLabels(segment.data.label, this.options.formatter(segment.data.value, segment.data));
    };

    Donut.prototype.setLabels = function(label1, label2) {
      var inner, maxHeightBottom, maxHeightTop, maxWidth, text1bbox, text1scale, text2bbox, text2scale;
      inner = (Math.min(this.el.width() / 2, this.el.height() / 2) - 10) * 2 / 3;
      maxWidth = 1.8 * inner;
      maxHeightTop = inner / 2;
      maxHeightBottom = inner / 3;
      this.text1.attr({
        text: label1,
        transform: ''
      });
      text1bbox = this.text1.getBBox();
      text1scale = Math.min(maxWidth / text1bbox.width, maxHeightTop / text1bbox.height);
      this.text1.attr({
        transform: "S" + text1scale + "," + text1scale + "," + (text1bbox.x + text1bbox.width / 2) + "," + (text1bbox.y + text1bbox.height)
      });
      this.text2.attr({
        text: label2,
        transform: ''
      });
      text2bbox = this.text2.getBBox();
      text2scale = Math.min(maxWidth / text2bbox.width, maxHeightBottom / text2bbox.height);
      return this.text2.attr({
        transform: "S" + text2scale + "," + text2scale + "," + (text2bbox.x + text2bbox.width / 2) + "," + text2bbox.y
      });
    };

    return Donut;

  })();

  Morris.DonutSegment = (function(_super) {

    __extends(DonutSegment, _super);

    function DonutSegment(cx, cy, inner, outer, p0, p1, color, data) {
      this.cx = cx;
      this.cy = cy;
      this.inner = inner;
      this.outer = outer;
      this.color = color;
      this.data = data;
      this.deselect = __bind(this.deselect, this);

      this.select = __bind(this.select, this);

      this.sin_p0 = Math.sin(p0);
      this.cos_p0 = Math.cos(p0);
      this.sin_p1 = Math.sin(p1);
      this.cos_p1 = Math.cos(p1);
      this.long = (p1 - p0) > Math.PI ? 1 : 0;
      this.path = this.calcSegment(this.inner + 3, this.inner + this.outer - 5);
      this.selectedPath = this.calcSegment(this.inner + 3, this.inner + this.outer);
      this.hilight = this.calcArc(this.inner);
    }

    DonutSegment.prototype.calcArcPoints = function(r) {
      return [this.cx + r * this.sin_p0, this.cy + r * this.cos_p0, this.cx + r * this.sin_p1, this.cy + r * this.cos_p1];
    };

    DonutSegment.prototype.calcSegment = function(r1, r2) {
      var ix0, ix1, iy0, iy1, ox0, ox1, oy0, oy1, _ref, _ref1;
      _ref = this.calcArcPoints(r1), ix0 = _ref[0], iy0 = _ref[1], ix1 = _ref[2], iy1 = _ref[3];
      _ref1 = this.calcArcPoints(r2), ox0 = _ref1[0], oy0 = _ref1[1], ox1 = _ref1[2], oy1 = _ref1[3];
      return ("M" + ix0 + "," + iy0) + ("A" + r1 + "," + r1 + ",0," + this.long + ",0," + ix1 + "," + iy1) + ("L" + ox1 + "," + oy1) + ("A" + r2 + "," + r2 + ",0," + this.long + ",1," + ox0 + "," + oy0) + "Z";
    };

    DonutSegment.prototype.calcArc = function(r) {
      var ix0, ix1, iy0, iy1, _ref;
      _ref = this.calcArcPoints(r), ix0 = _ref[0], iy0 = _ref[1], ix1 = _ref[2], iy1 = _ref[3];
      return ("M" + ix0 + "," + iy0) + ("A" + r + "," + r + ",0," + this.long + ",0," + ix1 + "," + iy1);
    };

    DonutSegment.prototype.render = function(r) {
      var _this = this;
      this.arc = r.path(this.hilight).attr({
        stroke: this.color,
        'stroke-width': 2,
        opacity: 0
      });
      return this.seg = r.path(this.path).attr({
        fill: this.color,
        stroke: 'white',
        'stroke-width': 3
      }).hover(function() {
        return _this.fire('hover', _this);
      });
    };

    DonutSegment.prototype.select = function() {
      if (!this.selected) {
        this.seg.animate({
          path: this.selectedPath
        }, 150, '<>');
        this.arc.animate({
          opacity: 1
        }, 150, '<>');
        return this.selected = true;
      }
    };

    DonutSegment.prototype.deselect = function() {
      if (this.selected) {
        this.seg.animate({
          path: this.path
        }, 150, '<>');
        this.arc.animate({
          opacity: 0
        }, 150, '<>');
        return this.selected = false;
      }
    };

    return DonutSegment;

  })(Morris.EventEmitter);

}).call(this);
