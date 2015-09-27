#!/usr/bin/env python

SETTINGS_BASIC = dict(
    clustersize=1,
    pagesize=12,
    blurb="<p>Here is the connection information to your very own "
    "VM for this intro to Docker workshop. You can connect "
    "to the VM using your SSH client.</p>\n"
    "<p>Your VM is reachable on the following address:</p>\n",
    prettify=lambda x: x,
    footer="",
    )

SETTINGS_ADVANCED = dict(
    clustersize=5,
    pagesize=12,
    blurb="<p>Here is the connection information to your very own "
    "cluster for this orchestration workshop. You can connect "
    "to each VM with any SSH client.</p>\n"
    "<p>Your machines are:<ul>\n",
    prettify=lambda l: [ "node%d: %s"%(i+1, s) 
                         for (i, s) in zip(range(len(l)), l) ],
    footer="<p>You can find the last version of the slides on "
    "http://view.dckr.info/.</p>"
    )

SETTINGS = SETTINGS_ADVANCED

globals().update(SETTINGS)

###############################################################################

ips = list(open("ips.txt"))

assert len(ips)%clustersize == 0

clusters = []

while ips:
    cluster = ips[:clustersize]
    ips = ips[clustersize:]
    clusters.append(cluster)

html = open("ips.html", "w")
html.write("<html><head><style>")
html.write("""
div { 
    float:left;
    border: 1px solid black;
    width: 28%;
    padding: 4% 2.5% 2.5% 2.5%;
    font-size: x-small;
    background-image: url("docker-nb.svg");
    background-size: 15%;
    background-position-x: 50%;
    background-repeat: no-repeat;
}
p {
    margin: 0.5em 0 0.5em 0;
}
.pagebreak {
    page-break-before: always;
    clear: both;
    display: block;
    height: 8px;
}
""")
html.write("</style></head><body>")
for i, cluster in enumerate(clusters):
    if i>0 and i%pagesize==0:
        html.write('<span class="pagebreak"></span>\n')
    html.write("<div>")
    html.write(blurb)
    for s in prettify(cluster):
        html.write("<li>%s</li>\n"%s)
    html.write("</ul></p>")
    html.write("<p>login=docker password=training</p>\n")
    html.write(footer)
    html.write("</div>")
html.close()

