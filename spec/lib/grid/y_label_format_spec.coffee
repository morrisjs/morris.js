describe 'Morris.Grid#yLabelFormat', ->
  
  it 'should use custom formatter for y labels', ->
    formatter = (label, prefix, suffix) ->
      flabel = parseFloat(label) / 1000
      "#{prefix}#{flabel.toFixed(1)}k#{suffix}"
    line = Morris.Line
      element: 'graph'
      data: [{x: 1, y: 1500}, {x: 2, y: 2500}]
      xkey: 'x'
      ykeys: ['y']
      labels: ['dontcare']
      preUnits: "$"
      yLabelFormat: formatter
    line.yLabelFormat(1500).should.equal "$1.5k"