describe 'Morris.Line data', ->

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

  describe 'ymin/ymax', ->

    it 'should use a user-specified minimum and maximum value', ->
      line = Morris.Line
        element: 'graph'
        data: [{x: 1, y: 1}]
        xkey: 'x'
        ykeys: ['y', 'z']
        labels: ['y', 'z']
        ymin: 10
        ymax: 20
      line.ymin.should.equal 10
      line.ymax.should.equal 20

    describe 'auto', ->

      it 'should automatically calculate the minimum and maximum value', ->
        line = Morris.Line
          element: 'graph'
          data: [{x: 1, y: 10}, {x: 2, y: 15}, {x: 3, y: null}, {x: 4}]
          xkey: 'x'
          ykeys: ['y', 'z']
          labels: ['y', 'z']
          ymin: 'auto'
          ymax: 'auto'
        line.ymin.should.equal 10
        line.ymax.should.equal 15
        line = Morris.Line
          element: 'graph'
          data: [{x: 1}, {x: 2}, {x: 3}, {x: 4}]
          xkey: 'x'
          ykeys: ['y', 'z']
          labels: ['y', 'z']
          ymin: 'auto'
          ymax: 'auto'
        line.ymin.should.equal 0
        line.ymax.should.equal 1

    describe 'auto [n]', ->

      it 'should automatically calculate the minimum and maximum value', ->
        line = Morris.Line
          element: 'graph'
          data: [{x: 1, y: 10}, {x: 2, y: 15}, {x: 3, y: null}, {x: 4}]
          xkey: 'x'
          ykeys: ['y', 'z']
          labels: ['y', 'z']
          ymin: 'auto 11'
          ymax: 'auto 13'
        line.ymin.should.equal 10
        line.ymax.should.equal 15
        line = Morris.Line
          element: 'graph'
          data: [{x: 1}, {x: 2}, {x: 3}, {x: 4}]
          xkey: 'x'
          ykeys: ['y', 'z']
          labels: ['y', 'z']
          ymin: 'auto 11'
          ymax: 'auto 13'
        line.ymin.should.equal 11
        line.ymax.should.equal 13

      it 'should use a user-specified minimum and maximum value', ->
        line = Morris.Line
          element: 'graph'
          data: [{x: 1, y: 10}, {x: 2, y: 15}, {x: 3, y: null}, {x: 4}]
          xkey: 'x'
          ykeys: ['y', 'z']
          labels: ['y', 'z']
          ymin: 'auto 5'
          ymax: 'auto 20'
        line.ymin.should.equal 5
        line.ymax.should.equal 20
        line = Morris.Line
          element: 'graph'
          data: [{x: 1}, {x: 2}, {x: 3}, {x: 4}]
          xkey: 'x'
          ykeys: ['y', 'z']
          labels: ['y', 'z']
          ymin: 'auto 5'
          ymax: 'auto 20'
        line.ymin.should.equal 5
        line.ymax.should.equal 20

