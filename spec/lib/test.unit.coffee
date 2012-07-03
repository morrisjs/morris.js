describe 'Morris.line', ->

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

  it 'should insert commas into long numbers', ->
    # zero
    Morris.commas(0).should.equal("0")
    # positive integers
    Morris.commas(1).should.equal("1")
    Morris.commas(12).should.equal("12")
    Morris.commas(123).should.equal("123")
    Morris.commas(1234).should.equal("1,234")
    Morris.commas(12345).should.equal("12,345")
    Morris.commas(123456).should.equal("123,456")
    Morris.commas(1234567).should.equal("1,234,567")
    # negative integers
    Morris.commas(-1).should.equal("-1")
    Morris.commas(-12).should.equal("-12")
    Morris.commas(-123).should.equal("-123")
    Morris.commas(-1234).should.equal("-1,234")
    Morris.commas(-12345).should.equal("-12,345")
    Morris.commas(-123456).should.equal("-123,456")
    Morris.commas(-1234567).should.equal("-1,234,567")
    # positive decimals
    Morris.commas(1.2).should.equal("1.2")
    Morris.commas(12.34).should.equal("12.34")
    Morris.commas(123.456).should.equal("123.456")
    Morris.commas(1234.56).should.equal("1,234.56")
    # negative decimals
    Morris.commas(-1.2).should.equal("-1.2")
    Morris.commas(-12.34).should.equal("-12.34")
    Morris.commas(-123.456).should.equal("-123.456")
    Morris.commas(-1234.56).should.equal("-1,234.56")

  it 'should pad numbers', ->
    Morris.pad2(0).should.equal("00")
    Morris.pad2(1).should.equal("01")
    Morris.pad2(2).should.equal("02")
    Morris.pad2(3).should.equal("03")
    Morris.pad2(4).should.equal("04")
    Morris.pad2(5).should.equal("05")
    Morris.pad2(6).should.equal("06")
    Morris.pad2(7).should.equal("07")
    Morris.pad2(8).should.equal("08")
    Morris.pad2(9).should.equal("09")
    Morris.pad2(10).should.equal("10")
    Morris.pad2(12).should.equal("12")
    Morris.pad2(34).should.equal("34")
    Morris.pad2(123).should.equal("123")

  describe 'parsing timestamp strings', ->
    it 'should parse years', ->
      Morris.parseDate('2012').should.equal(new Date(2012, 0, 1).getTime())
    it 'should parse quarters', ->
      Morris.parseDate('2012 Q1').should.equal(new Date(2012, 2, 1).getTime())
    it 'should parse months', ->
      Morris.parseDate('2012-09').should.equal(new Date(2012, 8, 1).getTime())
      Morris.parseDate('2012-10').should.equal(new Date(2012, 9, 1).getTime())
    it 'should parse dates', ->
      Morris.parseDate('2012-09-15').should.equal(new Date(2012, 8, 15).getTime())
      Morris.parseDate('2012-10-15').should.equal(new Date(2012, 9, 15).getTime())
    it 'should parse times', ->
      Morris.parseDate("2012-10-15 12:34").should.equal(new Date(2012, 9, 15, 12, 34).getTime())
      Morris.parseDate("2012-10-15T12:34").should.equal(new Date(2012, 9, 15, 12, 34).getTime())
      Morris.parseDate("2012-10-15 12:34:55").should.equal(new Date(2012, 9, 15, 12, 34, 55).getTime())
      Morris.parseDate("2012-10-15T12:34:55").should.equal(new Date(2012, 9, 15, 12, 34, 55).getTime())
    it 'should parse times with timezones', ->
      Morris.parseDate("2012-10-15T12:34+0100").should.equal(Date.UTC(2012, 9, 15, 11, 34))
      Morris.parseDate("2012-10-15T12:34+02:00").should.equal(Date.UTC(2012, 9, 15, 10, 34))
      Morris.parseDate("2012-10-15T12:34-0100").should.equal(Date.UTC(2012, 9, 15, 13, 34))
      Morris.parseDate("2012-10-15T12:34-02:00").should.equal(Date.UTC(2012, 9, 15, 14, 34))
      Morris.parseDate("2012-10-15T12:34:55Z").should.equal(Date.UTC(2012, 9, 15, 12, 34, 55))
      Morris.parseDate("2012-10-15T12:34:55+0600").should.equal(Date.UTC(2012, 9, 15, 6, 34, 55))
      Morris.parseDate("2012-10-15T12:34:55+04:00").should.equal(Date.UTC(2012, 9, 15, 8, 34, 55))
      Morris.parseDate("2012-10-15T12:34:55-0600").should.equal(Date.UTC(2012, 9, 15, 18, 34, 55))
    it 'should pass-through timestamps', ->
      Morris.parseDate(new Date(2012, 9, 15, 12, 34, 55, 123).getTime())
        .should.equal(new Date(2012, 9, 15, 12, 34, 55, 123).getTime())

  describe 'automatically generating smart x-axis labels', ->
    it 'should generate year intervals', ->
      Morris.labelSeries(
        new Date(2007, 0, 1).getTime(),
        new Date(2012, 0, 1).getTime(),
        1000
      ).should.deep.equal([
        ["2007", new Date(2007, 0, 1).getTime()],
        ["2008", new Date(2008, 0, 1).getTime()],
        ["2009", new Date(2009, 0, 1).getTime()],
        ["2010", new Date(2010, 0, 1).getTime()],
        ["2011", new Date(2011, 0, 1).getTime()],
        ["2012", new Date(2012, 0, 1).getTime()]
      ])
      Morris.labelSeries(
        new Date(2007, 3, 1).getTime(),
        new Date(2012, 3, 1).getTime(),
        1000
      ).should.deep.equal([
        ["2008", new Date(2008, 0, 1).getTime()],
        ["2009", new Date(2009, 0, 1).getTime()],
        ["2010", new Date(2010, 0, 1).getTime()],
        ["2011", new Date(2011, 0, 1).getTime()],
        ["2012", new Date(2012, 0, 1).getTime()]
      ])
    it 'should generate month intervals', ->
      Morris.labelSeries(
        new Date(2012, 0, 1).getTime(),
        new Date(2012, 5, 1).getTime(),
        1000
      ).should.deep.equal([
        ["2012-01", new Date(2012, 0, 1).getTime()],
        ["2012-02", new Date(2012, 1, 1).getTime()],
        ["2012-03", new Date(2012, 2, 1).getTime()],
        ["2012-04", new Date(2012, 3, 1).getTime()],
        ["2012-05", new Date(2012, 4, 1).getTime()],
        ["2012-06", new Date(2012, 5, 1).getTime()]
      ])
    it 'should generate day intervals', ->
      Morris.labelSeries(
        new Date(2012, 0, 1).getTime(),
        new Date(2012, 0, 6).getTime(),
        1000
      ).should.deep.equal([
        ["2012-01-01", new Date(2012, 0, 1).getTime()],
        ["2012-01-02", new Date(2012, 0, 2).getTime()],
        ["2012-01-03", new Date(2012, 0, 3).getTime()],
        ["2012-01-04", new Date(2012, 0, 4).getTime()],
        ["2012-01-05", new Date(2012, 0, 5).getTime()],
        ["2012-01-06", new Date(2012, 0, 6).getTime()]
      ])
    it 'should generate hour intervals', ->
      Morris.labelSeries(
        new Date(2012, 0, 1, 0).getTime(),
        new Date(2012, 0, 1, 5).getTime(),
        1000
      ).should.deep.equal([
        ["00:00", new Date(2012, 0, 1, 0).getTime()],
        ["01:00", new Date(2012, 0, 1, 1).getTime()],
        ["02:00", new Date(2012, 0, 1, 2).getTime()],
        ["03:00", new Date(2012, 0, 1, 3).getTime()],
        ["04:00", new Date(2012, 0, 1, 4).getTime()],
        ["05:00", new Date(2012, 0, 1, 5).getTime()]
      ])
    it 'should generate half-hour intervals', ->
      Morris.labelSeries(
        new Date(2012, 0, 1, 0, 0).getTime(),
        new Date(2012, 0, 1, 2, 30).getTime(),
        1000
      ).should.deep.equal([
        ["00:00", new Date(2012, 0, 1, 0, 0).getTime()],
        ["00:30", new Date(2012, 0, 1, 0, 30).getTime()],
        ["01:00", new Date(2012, 0, 1, 1, 0).getTime()],
        ["01:30", new Date(2012, 0, 1, 1, 30).getTime()],
        ["02:00", new Date(2012, 0, 1, 2, 0).getTime()],
        ["02:30", new Date(2012, 0, 1, 2, 30).getTime()]
      ])
      Morris.labelSeries(
        new Date(2012, 4, 12, 0, 0).getTime(),
        new Date(2012, 4, 12, 2, 30).getTime(),
        1000
      ).should.deep.equal([
        ["00:00", new Date(2012, 4, 12, 0, 0).getTime()],
        ["00:30", new Date(2012, 4, 12, 0, 30).getTime()],
        ["01:00", new Date(2012, 4, 12, 1, 0).getTime()],
        ["01:30", new Date(2012, 4, 12, 1, 30).getTime()],
        ["02:00", new Date(2012, 4, 12, 2, 0).getTime()],
        ["02:30", new Date(2012, 4, 12, 2, 30).getTime()]
      ])
    it 'should generate fifteen-minute intervals', ->
      Morris.labelSeries(
        new Date(2012, 0, 1, 0, 0).getTime(),
        new Date(2012, 0, 1, 1, 15).getTime(),
        1000
      ).should.deep.equal([
        ["00:00", new Date(2012, 0, 1, 0, 0).getTime()],
        ["00:15", new Date(2012, 0, 1, 0, 15).getTime()],
        ["00:30", new Date(2012, 0, 1, 0, 30).getTime()],
        ["00:45", new Date(2012, 0, 1, 0, 45).getTime()],
        ["01:00", new Date(2012, 0, 1, 1, 0).getTime()],
        ["01:15", new Date(2012, 0, 1, 1, 15).getTime()]
      ])
      Morris.labelSeries(
        new Date(2012, 4, 12, 0, 0).getTime(),
        new Date(2012, 4, 12, 1, 15).getTime(),
        1000
      ).should.deep.equal([
        ["00:00", new Date(2012, 4, 12, 0, 0).getTime()],
        ["00:15", new Date(2012, 4, 12, 0, 15).getTime()],
        ["00:30", new Date(2012, 4, 12, 0, 30).getTime()],
        ["00:45", new Date(2012, 4, 12, 0, 45).getTime()],
        ["01:00", new Date(2012, 4, 12, 1, 0).getTime()],
        ["01:15", new Date(2012, 4, 12, 1, 15).getTime()]
      ])
    it 'should override automatic intervals', ->
      Morris.labelSeries(
        new Date(2011, 11, 12).getTime(),
        new Date(2012, 0, 12).getTime(),
        1000,
        "year"
      ).should.deep.equal([
        ["2012", new Date(2012, 0, 1).getTime()]
      ])
    it 'should apply custom formatters', ->
      Morris.labelSeries(
        new Date(2012, 0, 1).getTime(),
        new Date(2012, 0, 6).getTime(),
        1000,
        "day",
        (d) -> "#{d.getMonth()+1}/#{d.getDate()}/#{d.getFullYear()}"
      ).should.deep.equal([
        ["1/1/2012", new Date(2012, 0, 1).getTime()],
        ["1/2/2012", new Date(2012, 0, 2).getTime()],
        ["1/3/2012", new Date(2012, 0, 3).getTime()],
        ["1/4/2012", new Date(2012, 0, 4).getTime()],
        ["1/5/2012", new Date(2012, 0, 5).getTime()],
        ["1/6/2012", new Date(2012, 0, 6).getTime()]
      ])
