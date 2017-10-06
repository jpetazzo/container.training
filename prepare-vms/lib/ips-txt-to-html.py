#!/usr/bin/env python
import os
import sys
import yaml
import jinja2

def prettify(l):
    l = [ip.strip() for ip in l]
    ret = [ "node{}: <code>{}</code>".format(i+1, s) for (i, s) in zip(range(len(l)), l) ]
    return ret

# Read settings from user-provided settings file
SETTINGS = yaml.load(open(sys.argv[1]))

clustersize = SETTINGS["clustersize"]

ips = list(open("ips.txt"))

print("---------------------------------------------")
print("   Number of IPs: {}".format(len(ips)))
print(" VMs per cluster: {}".format(clustersize))
print("---------------------------------------------")

assert len(ips)%clustersize == 0

clusters = []

while ips:
    cluster = ips[:clustersize]
    ips = ips[clustersize:]
    clusters.append(cluster)

template_file_name = SETTINGS["cards_template"]
template = jinja2.Template(open(template_file_name).read())
with open("ips.html", "w") as f:
	f.write(template.render(clusters=clusters, **SETTINGS))
print("Generated ips.html")

try:
    import pdfkit
    with open("ips.html") as f:
        pdfkit.from_file(f, "ips.pdf", options={
            "page-size": SETTINGS["paper_size"],
            "margin-top": SETTINGS["paper_margin"],
            "margin-bottom": SETTINGS["paper_margin"],
            "margin-left": SETTINGS["paper_margin"],
            "margin-right": SETTINGS["paper_margin"],
            })
    print("Generated ips.pdf")
except ImportError:
    print("WARNING: could not import pdfkit; did not generate ips.pdf")
