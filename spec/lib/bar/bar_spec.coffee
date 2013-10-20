describe 'Morris.Bar', ->
  describe 'when using vertical grid', ->
    defaults =
      element: 'graph'
      data: [{x: 'foo', y: 2, z: 3}, {x: 'bar', y: 4, z: 6}]
      xkey: 'x'
      ykeys: ['y', 'z']
      labels: ['Y', 'Z']
      verticalGrid:
        condition: (index) -> index % 2
        color: '#888888'
        opacity: '0.2'

    describe 'svg structure', ->
      it 'should contain extra rectangles for vertical grid', ->
        chart = Morris.Bar $.extend {}, defaults
        $('#graph').find("rect").size().should.equal 6

    describe 'svg attributes', ->
      it 'should have to bars with verticalGrid.color', ->
        chart = Morris.Bar $.extend {}, defaults
        $('#graph').find("rect[fill='#{defaults.verticalGrid.color}']").size().should.equal 2
      it 'should have to bars with verticalGrid.color', ->
        chart = Morris.Bar $.extend {}, defaults
        $('#graph').find("rect[fill-opacity='#{defaults.verticalGrid.opacity}']").size().should.equal 2

  describe 'svg structure', ->
    defaults =
      element: 'graph'
      data: [{x: 'foo', y: 2, z: 3}, {x: 'bar', y: 4, z: 6}]
      xkey: 'x'
      ykeys: ['y', 'z']
      labels: ['Y', 'Z']

    it 'should contain a rect for each bar', ->
      chart = Morris.Bar $.extend {}, defaults
      $('#graph').find("rect").size().should.equal 4

    it 'should contain 5 grid lines', ->
      chart = Morris.Bar $.extend {}, defaults
      $('#graph').find("path").size().should.equal 5

    it 'should contain 7 text elements', ->
      chart = Morris.Bar $.extend {}, defaults
      $('#graph').find("text").size().should.equal 7

  describe 'svg attributes', ->
    defaults =
      element: 'graph'
      data: [{x: 'foo', y: 2, z: 3}, {x: 'bar', y: 4, z: 6}]
      xkey: 'x'
      ykeys: ['y', 'z']
      labels: ['Y', 'Z']
      barColors: [ '#0b62a4', '#7a92a3']
      gridLineColor: '#aaa'
      gridStrokeWidth: 0.5
      gridTextColor: '#888'
      gridTextSize: 12

    it 'should have a bar with the first default color', ->
      chart = Morris.Bar $.extend {}, defaults
      $('#graph').find("rect[fill='#0b62a4']").size().should.equal 2

    it 'should have a bar with stroke width 0', ->
      chart = Morris.Bar $.extend {}, defaults
      $('#graph').find("rect[stroke-width='0']").size().should.equal 4

    it 'should have text with configured fill color', ->
      chart = Morris.Bar $.extend {}, defaults
      $('#graph').find("text[fill='#888888']").size().should.equal 7

    it 'should have text with configured font size', ->
      chart = Morris.Bar $.extend {}, defaults
      $('#graph').find("text[font-size='12px']").size().should.equal 7

  describe 'when having set yCaption', ->
    defaults =
      element: 'graph'
      data: [{x: 'foo', y: 2, z: 3}, {x: 'bar', y: 4, z: 6}]
      xkey: 'x'
      ykeys: ['y', 'z']
      labels: ['Y', 'Z']
      barColors: [ '#0b62a4', '#7a92a3']
      gridLineColor: '#aaa'
      gridStrokeWidth: 0.5
      gridTextColor: '#888'
      gridTextSize: 12
      padding: 40
      hoverCallback: (index, options, content) -> options.data[index].percentage_value + '% - ' + 'haha'
      yCaption:
        offsetX: -30
        text: 'THIS IS VERY LONG Y CAPTION'
        fSize: 16
        fFamily: 'Arial'
        fWeight: 800
        color: '#123'

    describe 'svg structure', ->
      it 'should have a caption\'s text node', ->
        chart = Morris.Bar $.extend {}, defaults
        $('#graph').find("text[font-size='16px']").size().should.equal 1
      it 'should contain caption.text', ->
        chart = Morris.Bar $.extend {}, defaults
        $('#graph').find("text[font-size='16px']").text().should.equal 'THIS IS VERY LONG Y CAPTION'
    describe 'svg attributes', ->
      it 'should have attributes defined in options', ->
        chart = Morris.Bar $.extend {}, defaults
        $('#graph').find("text[font-size='16px']").attr('font-weight').should.equal '800'
        $('#graph').find("text[font-size='16px']").attr('font-family').should.equal 'Arial'
        $('#graph').find("text[font-size='16px']").attr('fill').should.equal '#112233'
      it 'should fallback to grid text attribute, in case some are missing', ->
        delete defaults.yCaption
        chart = Morris.Bar $.extend {
          yCaption:
            offsetX: -30
            text: 'THIS IS VERY LONG Y CAPTION'
            fSize: 16
            fFamily: 'Arial'
            fWeight: 800
        }, defaults
        $('#graph').find("text[font-size='16px']").attr('fill').should.equal '#888888'
