#!/usr/bin/env python3
# coding: utf-8

FLAGS=dict(
  cz=u"🇨🇿",
  de=u"🇩🇪",
  fr=u"🇫🇷",
  uk=u"🇬🇧",
  us=u"🇺🇸",
  www=u"🌐",
)

TEMPLATE="""<html>
<head>
  <title>{{ title }}</title>
  <link rel="stylesheet" href="index.css">
  <meta charset="UTF-8">
</head>
<body>
  <div class="main">
    <table>
      <tr><td class="header" colspan="3">{{ title }}</td></tr>
      <tr><td class="details" colspan="3">Note: while some workshops are delivered in other languages, slides are always in English.</td></tr>

      <tr><td class="title" colspan="3">Free Kubernetes intro course</td></tr>

      <tr>
      	<td>Getting Started With Kubernetes and Container Orchestration</td>
      	<td><a class="slides" href="https://qconuk2019.container.training" /></td>
      	<td><a class="video" href="https://www.youtube.com/playlist?list=PLBAFXs0YjviJwCoxSUkUPhsSxDJzpZbJd" /></td>
      </tr>
      <tr>
        <td class="details">This is a live recording of a 1-day workshop that took place at QCON London in March 2019.</td>
      </tr>
      <tr>
        <td class="details">If you're interested, we can deliver that workshop (or longer courses) to your team or organization.</td>
      </tr>
      <tr>
        <td class="details">Contact <a href="mailto:jerome.petazzoni@gmail.com">Jérôme Petazzoni</a> to make that happen!</td>
      </tr>

      {% if coming_soon %}
        <tr><td class="title" colspan="3">Coming soon</td></tr>

        {% for item in coming_soon %}
          <tr>
            <td>{{ item.flag }} {{ item.title }}</td>
            <td>{% if item.slides %}<a class="slides" href="{{ item.slides }}" />{% endif %}</td>
            <td>{% if item.attend %}<a class="attend" href="{{ item.attend }}" />
            {% else %}
              <p class="details">{{ item.status }}</p>
            {% endif %}</td>
          </tr>
          <tr>
            <td class="details">Scheduled {{ item.prettydate }} at {{ item.event }} in {{item.city }}.</td>
          </tr>
        {% endfor %}
      {% endif %}

      {% if past_workshops %}
        <tr><td class="title" colspan="3">Past workshops</td></tr>

        {% for item in past_workshops[:5] %}
          <tr>
            <td>{{ item.title }}</td>
            <td>{% if item.slides %}<a class="slides" href="{{ item.slides }}" />
            {% else %}
              <p class="details">{{ item.status }}</p>
            {% endif %}</td>
            <td>{% if item.video %}<a class="video" href="{{ item.video }}" />{% endif %}</td>
          </tr>
          <tr>
            <td class="details">Delivered {{ item.prettydate }} at {{ item.event }} in {{item.city }}.</td>
          </tr>

        {% endfor %}

        {% if past_workshops[5:] %}
          <tr>
            <td>... and at least <a href="past.html">{{ past_workshops[5:] | length }} more</a>.</td>
          </tr>
        {% endif %}
      {% endif %}

      {% if recorded_workshops %}
        <tr><td class="title" colspan="3">Recorded workshops</td></tr>

        {% for item in recorded_workshops %}
          <tr>
            <td>{{ item.title }}</td>
            <td><a class="slides" href="{{ item.slides }}" /></td>
            <td><a class="video" href="{{ item.video }}" /></td>
          </tr>
          <tr>
            <td class="details">Delivered {{ item.prettydate }} at {{ item.event }} in {{item.city }}.</td>
          </tr>
        {% endfor %}
      {% endif %}

      {% if self_paced %}
        <tr><td class="title" colspan="3">Self-paced tutorials</td></tr>
        {% for item in self_paced %}
          <tr>
            <td>{{ item.title }}</td>
            <td><a class="slides" href="{{ item.slides }}" /></td>
          </tr>
        {% endfor %}
      {% endif %}

      {% if all_past_workshops %}
        <tr><td class="title" colspan="3">Past workshops</td></tr>
        {% for item in all_past_workshops %}
          <tr>
            <td>{{ item.title }}</td>
            <td>{% if item.slides %}<a class="slides" href="{{ item.slides }}" />
            {% else %}
              <p class="details">{{ item.status }}</p>
            {% endif %}</td>
            {% if item.video %}
              <td><a class="video" href="{{ item.video }}" /></td>
            {% endif %}
          </tr>
          <tr>
            <td class="details">Delivered {{ item.prettydate }} at {{ item.event }} in {{item.city }}.</td>
          </tr>
        {% endfor %}
      {% endif %}

      <tr><td class="spacer"></td></tr>

      <tr>
        <td class="footer">
          Maintained by Jérôme Petazzoni (<a href="https://twitter.com/jpetazzo">@jpetazzo</a>) and <a href="https://github.com/jpetazzo/container.training/graphs/contributors">contributors</a>.
        </td>
      </tr>
    </table>
  </div>
</body>
</html>"""

import datetime
import jinja2
import yaml

items = yaml.safe_load(open("index.yaml"))


def prettyparse(date):
    months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ]
    month = months[date.month-1]
    suffix = {
            1: "st", 2: "nd", 3: "rd",
            21: "st", 22: "nd", 23: "rd",
            31: "st"}.get(date.day, "th")
    return date.year, month, "{}{}".format(date.day, suffix)


# Items with a date correspond to scheduled sessions.
# Items without a date correspond to self-paced content.
# The date should be specified as a string (e.g. 2018-11-26).
# It can also be a list of two elements (e.g. [2018-11-26, 2018-11-28]).
# The latter indicates an event spanning multiple dates.
# The event will be considered "current" (shown in the list of
# upcoming events) until the second date.

for item in items:
    if "date" in item:
        date = item["date"]
        if type(date) == list:
            date_begin, date_end = date
        else:
            date_begin, date_end = date, date
        y1, m1, d1 = prettyparse(date_begin)
        y2, m2, d2 = prettyparse(date_end)
        if (y1, m1, d1) == (y2, m2, d2):
            # Single day event
            pretty_date = "{} {}, {}".format(m1, d1, y1)
        elif (y1, m1) == (y2, m2):
            # Multi-day event within a single month
            pretty_date = "{} {}-{}, {}".format(m1, d1, d2, y1)
        elif y1 == y2:
            # Multi-day event spanning more than a month
            pretty_date = "{} {}-{} {}, {}".format(m1, d1, m2, d2, y1)
        else:
            # Event spanning the turn of the year (REALLY???)
            pretty_date = "{} {}, {}-{} {}, {}".format(m1, d1, y1, m2, d2, y2)
        item["begin"] = date_begin
        item["end"] = date_end
        item["prettydate"] = pretty_date
    item["flag"] = FLAGS.get(item.get("country"),"")

today = datetime.date.today()
coming_soon = [i for i in items if i.get("date") and i["end"] >= today]
coming_soon.sort(key=lambda i: i["begin"])
past_workshops = [i for i in items if i.get("date") and i["end"] < today]
past_workshops.sort(key=lambda i: i["begin"], reverse=True)
self_paced = [i for i in items if not i.get("date")]
recorded_workshops = [i for i in items if i.get("video")]

template = jinja2.Template(TEMPLATE)
with open("index.html", "w") as f:
    f.write(template.render(
    	title="Container Training",
    	coming_soon=coming_soon,
    	past_workshops=past_workshops,
    	self_paced=self_paced,
    	recorded_workshops=recorded_workshops
    	))

with open("past.html", "w") as f:
	f.write(template.render(
		title="Container Training",
		all_past_workshops=past_workshops
		))
