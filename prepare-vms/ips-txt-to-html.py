#!/usr/bin/env python

clustersize = 5

pagesize = 12

###############################################################################

ips = list(open("ips.txt"))

assert len(ips)%clustersize == 0

clusters = []

while ips:
    cluster = ips[:clustersize]
    ips = ips[clustersize:]
    clusters.append(cluster)

def makenames(addrs):
    return [ "node%d"%(i+1) for i in range(len(addrs)) ]

html = open("ips.html", "w")
html.write("<html><head><style>")
html.write("""
div { 
    float:left;
    border: 1px solid black;
    width: 25%;
    padding: 4%;
    font-size: x-small;
    background-image: url("docker-nb.svg");
    background-size: 15%;
    background-position-x: 50%;
    background-repeat: no-repeat;
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
    html.write("<p>Here is the connection information to your very own ")
    html.write("cluster for this orchestration workshop. You can connect ")
    html.write("to each VM with your SSH client.</p>\n")
    html.write("<p>login=docker password=training</p>\n")
    html.write("<p>Your machines are:<ul>\n")
    for ipaddr, hostname in zip(cluster, makenames(cluster)):
        html.write("<li>%s - %s</li>\n"%(hostname, ipaddr))
    html.write("</ul></p>")
    html.write("</div>")
html.close()

