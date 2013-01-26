## Your first chart

Start by adding a `<div>` to your page that will contain your chart. Make
sure it has an ID so you can refer to it in your Javascript later.

{% highlight html %}
<div id="myfirstchart" style="height: 250px;"></div>
{% endhighlight %}

*Note: in order to display something, you'll need to have given the div some
dimensions. Here I've used inline CSS just for illustration.*

Next add a `<script>` block to the end of your page, containing the following
javascript code:

{% highlight javascript %}
new Morris.Line({
  // ID of the element in which to draw the chart.
  element: 'myfirstchart',
  // Chart data records -- each entry in this array corresponds to a point on
  // the chart.
  data: [
    { year: '2008', value: 20 },
    { year: '2009', value: 10 },
    { year: '2010', value: 5 },
    { year: '2011', value: 5 },
    { year: '2012', value: 20 }
  ],
  // The name of the data record attribute that contains x-values.
  xkey: 'year',
  // A list of names of data record attributes that contain y-values.
  ykeys: ['value'],
  // Labels for the ykeys -- will be displayed when you hover over the
  // chart.
  labels: ['Value']
});
{% endhighlight %}

Assuming everything's working correctly, you should see the following chart on
your page:

<div class="graph-container">
  <div class="graph" id="examplefirst"> </div>
</div>


