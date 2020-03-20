#!/usr/bin/env python3
import os
import sys
import yaml
import jinja2


# Read settings from user-provided settings file
context = yaml.safe_load(open(sys.argv[1]))

ips = list(open("ips.txt"))
clustersize = context["clustersize"]

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

context["clusters"] = clusters

template_file_name = context["cards_template"]
template_file_path = os.path.join(
    os.path.dirname(__file__),
    "..",
    "templates",
    template_file_name
    )
template = jinja2.Template(open(template_file_path).read())
with open("ips.html", "w") as f:
	f.write(template.render(**context))
print("Generated ips.html")


try:
    import pdfkit
    paper_size = context["paper_size"]
    margin = {"A4": "0.5cm", "Letter": "0.2in"}[paper_size]
    with open("ips.html") as f:
        pdfkit.from_file(f, "ips.pdf", options={
            "page-size": paper_size,
            "margin-top": margin,
            "margin-bottom": margin,
            "margin-left": margin,
            "margin-right": margin,
            })
    print("Generated ips.pdf")
except ImportError:
    print("WARNING: could not import pdfkit; did not generate ips.pdf")
