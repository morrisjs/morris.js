gridLines = (ymin, ymax, nlines = 5) ->
  interval = ymax - ymin
  omag = Math.floor(Math.log(interval) / Math.log(10))
  unit = Math.pow(10, omag)

  ymin1 = Math.round(ymin / unit) * unit
  ymax1 = Math.round(ymax / unit) * unit
  step = (ymax1 - ymin1) / (nlines - 1)

  # ensure zero is plotted where the range includes zero
  if ymin1 < 0 and ymax1 > 0
    ymin1 = Math.round(ymin / step) * step
    ymax1 = Math.round(ymax / step) * step

  # small numbers
  if step < 1
    smag = Math.floor(Math.log(step) / Math.log(10))
    (parseFloat(y.toFixed(1 - smag)) for y in [ymin1..ymax1] by step)
  else
    (y for y in [ymin1..ymax1] by step)

describe 'Morris.Grid#gridLines', ->

  it 'should draw at fixed intervals', ->
    gridLines(0, 4).should.deep.equal [0, 1, 2, 3, 4]
    gridLines(0, 400).should.deep.equal [0, 100, 200, 300, 400]

  it 'should pick intervals that show significant numbers', ->
    gridLines(98, 502).should.deep.equal [100, 200, 300, 400, 500]
    gridLines(98, 302).should.deep.equal [100, 150, 200, 250, 300]
    gridLines(98, 202).should.deep.equal [100, 125, 150, 175, 200]

  it 'should draw zero when it falls within [ymin..ymax]', ->
    gridLines(-100, 300).should.deep.equal [-100, 0, 100, 200, 300]
    gridLines(-50, 350).should.deep.equal [0, 100, 200, 300, 400]
    gridLines(-500, 300).should.deep.equal [-400, -200, 0, 200, 400]
    gridLines(100, 500).should.deep.equal [100, 200, 300, 400, 500]
    gridLines(-500, -100).should.deep.equal [-500, -400, -300, -200, -100]

  it 'should generate decimal labels to 2 signigicant figures', ->
    gridLines(0, 1).should.deep.equal [0, 0.25, 0.5, 0.75, 1]
    gridLines(0.1, 0.5).should.deep.equal [0.1, 0.2, 0.3, 0.4, 0.5]
