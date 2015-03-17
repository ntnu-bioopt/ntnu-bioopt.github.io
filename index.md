---
layout: page
---

<p>This website aims to present <a href="{{ site.url }}/software">free software</a> resulting from research by the Biomedical Optics group at
the Department of Electronics and Telecommunications, NTNU Norwegian University of Science
and Technology.</p>

<p>The Biomedical Optics group is a smaller subset of the Nanoelectronics and Photonics group. Current members are listed below.</p>


{% for people in site.data.people %}

<div class="people-list-element">
{% if people.img %}
<img src="{{ site.url }}/assets/people/{{ people.img }}">
{% endif %}
<h2>{{ people.name }}</h2>
<ul>
	<li>{{ people.title }}</li>
	<li><a href="{{ people.ntnu }}">Contact information</a></li>
</ul>
</div>

{% endfor %}

