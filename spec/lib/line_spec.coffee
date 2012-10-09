describe 'Morris.Line', ->

  beforeEach ->
    placeholder = $('<div id="graph" style="width: 100px; height: 50px"></div>')
    $('#test').append(placeholder)

  afterEach ->
    $('#test').empty()

  it 'should not alter user-supplied data', ->
    my_data = [{x: 1, y: 1}, {x: 2, y: 2}]
    expected_data = [{x: 1, y: 1}, {x: 2, y: 2}]
    Morris.Line
      element: 'graph'
      data: my_data
      xkey: 'x'
      ykeys: ['y']
      labels: ['dontcare']
    my_data.should.deep.equal expected_data

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
    fn.should.throw(/Graph placeholder not found./)

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