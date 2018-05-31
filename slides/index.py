#!/usr/bin/env python2
# coding: utf-8
TEMPLATE="""<html>
<head>
    <title>Container Training</title>
    <style type="text/css">
        body {
            background-image: url("images/container-background.jpg");
            max-width: 1024px;
            margin: 0 auto;
        }
        table {
            font-size: 20px;
            font-family: sans-serif;
            background: white;
            width: 100%;
            height: 100%;
            padding: 20px;
        }
        .header {
            font-size: 300%;
            font-weight: bold;
        }
        .title {
            font-size: 150%;
            font-weight: bold;
        }
        .details {
            font-size: 80%;
            font-style: italic;
        }
        td {
            padding: 1px;
            height: 1em;
        }
        td.spacer {
            height: unset;
        }
        td.footer {
            padding-top: 80px;
            height: 100px;
        }
        td.title {
            border-bottom: thick solid black;
            padding-bottom: 2px;
            padding-top: 20px;
        }
        a {
            text-decoration: none;
        }
        a:hover {
            background: yellow;
        }
        a.attend:after {
            content: "📅 attend";
        }
        a.slides:after {
            content: "📚 slides";
        }
        a.chat:after {
            content: "💬 chat";
        }
        a.video:after {
            content: "📺 video";
        }
    </style>
</head>
<body>
    <div class="main">
    <table>
        <tr><td class="header" colspan="4">Container Training</td></tr>

        <tr><td class="title" colspan="4">Coming soon near you</td></tr>

	    <!--
	     <td>Nothing for now (stay tuned...)</td>
thing for now (stay tuned...)</td>
             -->

        {% for item in coming_soon %}
        <tr>
            <td>{{ item.prettydate }}: {{ item.title }} at {{ item.event }} in {{ item.city }}</td>
            <td>{% if item.slides %}<a class="slides" href="{{ item.slides }}" />{% endif %}</td>
            <td><a class="attend" href="{{ item.attend }}" /></td>
        </tr>
        {% endfor %}

        <tr><td class="title" colspan="4">Past workshops</td></tr>

        {% for item in past_workshops[:5] %}
        <tr>
            <td>{{ item.prettydate }}: {{ item.title }} {% if item.event %}at {{ item.event }} {% endif %} {% if item.city %} in {{ item.city }} {% endif %}</td>
            <td><a class="slides" href="{{ item.slides }}" /></td>
            <td>{% if item.video %}<a class="video" href="{{ item.video }}" />{% endif %}</td>
        </tr>
        {% endfor %}

        {% if past_workshops[5:] %}
        <tr>
            <td>... and at least {{ past_workshops[5:] | length }} more.</td>
        </tr>
        {% endif %}
        
        <tr><td class="title" colspan="4">Recorded workshops</td></tr>
        
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

        <tr><td class="title" colspan="4">Self-paced tutorials</td></tr>
        {% for item in self_paced %}
        <tr>
            <td>{{ item.title }}</td>
            <td><a class="slides" href="{{ item.slides }}" /></td>
        </tr>
        {% endfor %}

        <tr><td class="spacer"></td></tr>

        <tr>
            <td class="footer">
                Maintained by Jérôme Petazzoni (<a href="https://twitter.com/jpetazzo">@jpetazzo</a>) and <a href="https://github.com/jpetazzo/container.training/graphs/contributors">contributors</a>.
            </td>
        </tr>
    </table>
    </div>
</body>
</html>""".decode("utf-8")

import datetime
import jinja2
import yaml

items = yaml.load(open("index.yaml"))

for item in items:
    if "date" in item:
        date = item["date"]
        suffix = {
                1: "st", 2: "nd", 3: "rd", 
                21: "st", 22: "nd", 23: "rd", 
                31: "st"}.get(date.day, "th")
        item["prettydate"] = date.strftime("%B %e{}, %Y").format(suffix)

today = datetime.date.today()
coming_soon = [i for i in items if i.get("date") and i["date"] >= today]
coming_soon.sort(key=lambda i: i["date"])
past_workshops = [i for i in items if i.get("date") and i["date"] < today]
past_workshops.sort(key=lambda i: i["date"], reverse=True)
self_paced = [i for i in items if not i.get("date")]
recorded_workshops = [i for i in items if i.get("video")]

template = jinja2.Template(TEMPLATE)
with open("index.html", "w") as f:
    f.write(template.render(coming_soon=coming_soon, past_workshops=past_workshops, self_paced=self_paced, recorded_workshops=recorded_workshops).encode("utf-8"))
