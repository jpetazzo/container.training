#!/usr/bin/env python3
import os
import sys
import yaml
import jinja2


# Read settings from user-provided settings file
context = dict(
    cards_template = "mlops.html",
    paper_size = "Letter",
) # {} # yaml.safe_load(open(sys.argv[1]))

logins = list(open("login.tsv"))
context["logins"] = []
for login in logins:	
    password, command, ipaddr, ipaddrs = login.split("\t", 3)
    context["logins"].append(dict(
        password=password,
        command=command,
        ipaddr=ipaddr,
        ipaddrs=ipaddrs,
    ))

print("---------------------------------------------")
print("   Number of cards: {}".format(len(logins)))
print("---------------------------------------------")

template_file_name = context["cards_template"]
template_file_path = os.path.join(
    os.path.dirname(__file__),
    "..",
    "templates",
    template_file_name
    )
template = jinja2.Template(open(template_file_path).read())
with open("cards.html", "w") as f:
    f.write(template.render(**context))
print("Generated cards.html")


try:
    import pdfkit
    paper_size = context["paper_size"]
    margin = {"A4": "0.5cm", "Letter": "0.2in"}[paper_size]
    with open("cards.html") as f:
        pdfkit.from_file(f, "cards.pdf", options={
            "page-size": paper_size,
            "margin-top": margin,
            "margin-bottom": margin,
            "margin-left": margin,
            "margin-right": margin,
            })
    print("Generated cards.pdf")
except ImportError:
    print("WARNING: could not import pdfkit; did not generate cards.pdf")
