## Getting started

Add **morris.js** and its dependencies ([jQuery](http://jquery.com) &
[Raphaël](http://raphaeljs.com)) to your page.

{% highlight html linenos %}
<link rel="stylesheet" href="//cdn.oesmith.co.uk/morris-{{ page.morris_version}}.min.css">
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"></script>
<script src="//cdnjs.cloudflare.com/ajax/libs/raphael/2.1.0/raphael-min.js"></script>
<script src="//cdn.oesmith.co.uk/morris-{{ page.morris_version }}.min.js"></script>
{% endhighlight %}

If you don't want to use the CDN-hosted assets, then you can extract them from
the [zip bundle](//cdn.oesmith.co.uk/morris-{{ page.morris_version }}.zip) and
upload them to your own site.

