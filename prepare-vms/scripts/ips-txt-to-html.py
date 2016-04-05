#!/usr/bin/env python
import os
import sys
import yaml
try:
    import pdfkit
except ImportError:
    print("WARNING: could not import pdfkit; PDF generation will fali.")

def prettify(l):
    l = [ip.strip() for ip in l]
    ret = [ "node{}: <code>{}</code>".format(i+1, s) for (i, s) in zip(range(len(l)), l) ]
    return ret


# Read settings from settings.yaml
with open(sys.argv[1]) as f:
    data = f.read()

SETTINGS = yaml.load(data)
SETTINGS['footer'] = SETTINGS['footer'].format(url=SETTINGS['url'])
globals().update(SETTINGS)

###############################################################################

ips = list(open("ips.txt"))

print("Current settings (as defined in settings.yaml):")
print("   Number of IPs: {}".format(len(ips)))
print(" VMs per cluster: {}".format(clustersize))
print("Background image: {}".format(background_image))
print("---------------------------------------------")

assert len(ips)%clustersize == 0

if clustersize == 1:
    blurb = blurb.format(
        cluster_or_machine="machine",
        this_or_each="this",
        machine_is_or_machines_are="machine is",
        workshop_name=workshop_short_name,
    )
else:
    blurb = blurb.format(
        cluster_or_machine="cluster",
        this_or_each="each",
        machine_is_or_machines_are="machines are",
        workshop_name=workshop_short_name,
    )

clusters = []

while ips:
    cluster = ips[:clustersize]
    ips = ips[clustersize:]
    clusters.append(cluster)

html = open("ips.html", "w")
html.write("<html><head><style>")
head = """
div {{
    float:left;
    border: 1px dotted black;
    width: 27%;
    padding: 6% 2.5% 2.5% 2.5%;
    font-size: x-small;
    background-image: url("{background_image}");
    background-size: 13%;
    background-position-x: 50%;
    background-position-y: 5%;
    background-repeat: no-repeat;
}}

p {{
    margin: 0.5em 0 0.5em 0;
}}

.pagebreak {{
    page-break-before: always;
    clear: both;
    display: block;
    height: 8px;
}}
"""


head = head.format(background_image=SETTINGS['background_image'])
html.write(head)

html.write("</style></head><body>")
for i, cluster in enumerate(clusters):
    if i>0 and i%pagesize==0:
        html.write('<span class="pagebreak"></span>\n')

    html.write("<div>")
    html.write(blurb)
    for s in prettify(cluster):
        html.write("<li>%s</li>\n"%s)
    html.write("</ul></p>")
    html.write("<p>login: <b><code>{}</code></b> <br>password: <b><code>{}</code></b></p>\n".format(instance_login, instance_password))
    html.write(footer)
    html.write("</div>")
html.close()

"""
    html.write("<div>")
    html.write("<p>{}</p>".format(blurb))
    for s in prettify(cluster):
        html.write("<li>{}</li>".format(s))
    html.write("</ul></p>")
    html.write("<center>")
    html.write("<p>login: <b><code>{}</code></b> &nbsp&nbsp  password: <b><code>{}</code></b></p>\n".format(instance_login, instance_password))
    html.write("</center>")
    html.write(footer)
    html.write("</div>")
html.close()
"""

with open('ips.html') as f:
    pdfkit.from_file(f, 'ips.pdf')
