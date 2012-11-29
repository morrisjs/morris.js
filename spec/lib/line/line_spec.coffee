describe 'Morris.Line', ->

  it 'should raise an error when the placeholder element is not found', ->
    my_data = [{x: 1, y: 1}, {x: 2, y: 2}]
    fn = ->
      Morris.Line(
        element: "thisplacedoesnotexist"
        data: my_data
        xkey: 'x'
        ykeys: ['y']
        labels: ['dontcare']
      )
    fn.should.throw(/Graph container element not found/)

  it 'should make point styles customizable', ->
    my_data = [{x: 1, y: 1}, {x: 2, y: 2}]
    red = '#ff0000'
    blue = '#0000ff'
    chart = Morris.Line
      element: 'graph'
      data: my_data
      xkey: 'x'
      ykeys: ['y']
      labels: ['dontcare']
      pointStrokeColors: [red, blue]
      pointWidths: [1, 2]
      pointFillColors: [null, red]
    chart.strokeWidthForSeries(0).should.equal 1
    chart.strokeForSeries(0).should.equal red
    chart.strokeWidthForSeries(1).should.equal 2
    chart.strokeForSeries(1).should.equal blue
    (null == chart.pointFillColorForSeries(0)).should.be
    (chart.pointFillColorForSeries(0) || chart.colorForSeries(0)).should.equal chart.colorForSeries(0)
    chart.pointFillColorForSeries(1).should.equal red

  describe 'generating column labels', ->

    it 'should use user-supplied x value strings by default', ->
      chart = Morris.Line
        element: 'graph'
        data: [{x: '2012 Q1', y: 1}, {x: '2012 Q2', y: 1}]
        xkey: 'x'
        ykeys: ['y']
        labels: ['dontcare']
      chart.data.map((x) -> x.label).should == ['2012 Q1', '2012 Q2']

    it 'should use a default format for timestamp x-values', ->
      d1 = new Date(2012, 0, 1)
      d2 = new Date(2012, 0, 2)
      chart = Morris.Line
        element: 'graph'
        data: [{x: d1.getTime(), y: 1}, {x: d2.getTime(), y: 1}]
        xkey: 'x'
        ykeys: ['y']
        labels: ['dontcare']
      chart.data.map((x) -> x.label).should == [d2.toString(), d1.toString()]

    it 'should use user-defined formatters', ->
      d = new Date(2012, 0, 1)
      chart = Morris.Line
        element: 'graph'
        data: [{x: d.getTime(), y: 1}, {x: '2012-01-02', y: 1}]
        xkey: 'x'
        ykeys: ['y']
        labels: ['dontcare']
        dateFormat: (d) ->
          x = new Date(d)
          "#{x.getYear()}/#{x.getMonth()+1}/#{x.getDay()}"
      chart.data.map((x) -> x.label).should == ['2012/1/1', '2012/1/2']

  describe '#generatePaths', ->
    TestDefaults = {}
    beforeEach ->
      TestDefaults = {element: 'graph', xkey: 'x', ykeys: ['y'], labels: ['dontcare']}

    it 'should generate smooth lines when options.smooth is true', ->
      testData = [{x: 1, y: 1}, {x: 3, y: 1 }]
      chart = Morris.Line(TestDefaults extends {data: testData, continuousLine: true})
      path = chart.generatePaths()[0]
      path.match(/[A-Z]/g).should.deep.equal ['M', 'C']

    it 'should generate jagged, continuous lines when options.smooth is false and options.continuousLine is true', ->
      testData = [{x: 1, y: 1}, {x: 2, y: null }, {x: 3, y: 1}]
      chart = Morris.Line(TestDefaults extends {data: testData, smooth: false, continuousLine: true})
      path = chart.generatePaths()[0]
      path.match(/[A-Z]/g).should.deep.equal ['M', 'L']

    it 'should generate jagged, discontinuous lines when options.smooth is false and options.continuousLine is false', ->
      testData = [{x: 1, y: 1}, {x: 2, y: null }, {x: 3, y: 1}, {x: 4, y: 1}]
      chart = Morris.Line(TestDefaults extends {data: testData, smooth: false, continuousLine: false})
      path = chart.generatePaths()[0]
      path.match(/[A-Z]/g).should.deep.equal ['M', 'M', 'L']

    it 'should generate smooth/jagged lines according to the value for each series when options.smooth is an array', ->
      testData = [{x: 1, a: 1, b: 1}, {x: 3, a: 1, b: 1}]
      chart = Morris.Line(TestDefaults extends {data: testData, smooth: ['a'], ykeys: ['a', 'b']})
      pathA = chart.generatePaths()[0]
      pathA.match(/[A-Z]/g).should.deep.equal ['M', 'C']

      pathB = chart.generatePaths()[1]
      pathB.match(/[A-Z]/g).should.deep.equal ['M', 'L']

    #skipping because undefined values are converted to nulls in the setData method morris.grid line#98
    it.skip 'should filter undefined values from series', ->
      testData = [{x: 1, y: 1}, {x: 2, y: undefined}, {x: 3, y: 1}]
      options =
        data: testData
        continuousLine: false #doesn't matter for undefined values

      chart = Morris.Line(TestDefaults extends options)
      path = chart.generatePaths()[0]
      path.match(/[A-Z]/g).should.deep.equal ['M', 'C']

    it 'should filter null values from series only when options.continuousLine is true', ->
      testData = [{x: 1, y: 1}, {x: 2, y: null}, {x: 3, y: 1}]
      chart = Morris.Line(TestDefaults extends {data: testData, continuousLine: true})
      path = chart.generatePaths()[0]
      path.match(/[A-Z]/g).should.deep.equal ['M', 'C']

    it 'should not filter null values from series when options.continuousLine is false', ->
      testData = [{x: 1, y: 1}, {x: 2, y: null}, {x: 3, y: 1}, {x: 4, y: 1}]
      chart = Morris.Line(TestDefaults extends {data: testData, continuousLine: false})
      path = chart.generatePaths()[0]
      path.match(/[A-Z]/g).should.deep.equal ['M', 'M', 'C']

  describe '#createPath', ->
    TestDefaults = {}
    beforeEach ->
      TestDefaults = {element: 'graph', xkey: 'x', ykeys: ['y'], labels: ['dontcare']}

    it 'should generate a smooth line', ->
      testData = [{x: 1, y: 1}, {x: 3, y: 1}]
      chart = Morris.Line(TestDefaults extends {data: testData})
      path = chart.createPath(testData, true)
      path.match(/[A-Z]/g).should.deep.equal ['M', 'C']

    it 'should generate a jagged line', ->
      testData = [{x: 1, y: 1}, {x: 3, y: 1}]
      chart = Morris.Line(TestDefaults extends {data: testData})
      path = chart.createPath(testData, false)
      path.match(/[A-Z]/g).should.deep.equal ['M', 'L']

    it 'should break the line at null values', ->
      testData = [{x: 1, y: 1}, {x: 2, y: null}, {x: 3, y: 1}, {x: 4, y: 1}]
      chart = Morris.Line(TestDefaults extends {data: testData})
      path = chart.createPath(testData, true)
      path.match(/[A-Z]/g).should.deep.equal ['M', 'M', 'C']
