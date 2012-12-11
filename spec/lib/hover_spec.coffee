describe "Morris.Hover", ->

  describe "with dummy content", ->

    beforeEach ->
      @parent = $('<div style="width:200px;height:180px"></div>')
        .appendTo($('#test'))
      @hover = new Morris.Hover(
        parent:  @parent,
        content: '<div style="width:84px;height:84px"></div>')
      @element = $('#test .morris-popup')

    it "should initialise a hidden, empty popup", ->
      @element.should.exist
      @element.should.be.hidden
      @element.should.be.empty

    describe "#show", ->
      it "should show the popup", ->
        @hover.show()
        @element.should.be.visible

    describe "#hide", ->
      it "should hide the popup", ->
        @hover.show()
        @hover.hide()
        @element.should.be.hidden

    describe "#moveTo", ->
      beforeEach -> @hover.render()

      it "should place the popup directly above the given point", ->
        @hover.moveTo(100, 150)
        @element.should.have.css('left', '50px')
        @element.should.have.css('top', '40px')

      it "should place the popup below the given point if it does not fit above", ->
        @hover.moveTo(100, 50)
        @element.should.have.css('left', '50px')
        @element.should.have.css('top', '60px')

      it "should center the popup vertically if it will not fit above or below", ->
        @hover.moveTo(100, 100)
        @element.should.have.css('left', '50px')
        @element.should.have.css('top', '40px')

      it "should center the popup vertically if no y value is supplied", ->
        @hover.moveTo(100)
        @element.should.have.css('left', '50px')
        @element.should.have.css('top', '40px')

  describe "#render", ->
    it "should take content from a string", ->
      hover = new Morris.Hover(parent: $('#test'), content: 'Hello, World!')
      hover.render()
      $('#test .morris-popup').html().should.equal 'Hello, World!'

    it "should take content from a method", ->
      hover = new Morris.Hover(parent: $('#test'), content: (x) -> "Hello, #{x}!")
      hover.render('Tester')
      $('#test .morris-popup').html().should.equal 'Hello, Tester!'

  describe "#update", ->
    it "should update content, show and reposition the popup", ->
      hover = new Morris.Hover
        parent:  $('#test')
        content: (x) -> "<div style='width:84px;height:84px'>Hello, #{x}!</div>"
      hover.update(150, 200, 'Everyone')
      el = $('#test .morris-popup')
      el.should.have.css('left', '100px')
      el.should.have.css('top', '90px')
      el.should.have.text('Hello, Everyone!')
