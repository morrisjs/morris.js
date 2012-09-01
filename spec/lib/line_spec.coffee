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