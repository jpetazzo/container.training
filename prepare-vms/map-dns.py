#!/usr/bin/env python
"""
There are two ways to use this script:

1. Pass a file name and a tag name as a single argument.
It will load a list of domains from the given file (one per line),
and assign them to the clusters corresponding to that tag.
There should be more domains than clusters.
Example: ./map-dns.py domains.txt 2020-08-15-jp

2. Pass a domain as the 1st argument, and IP addresses then.
It will configure the domain with the listed IP addresses.
Example: ./map-dns.py open-duck.site 1.2.3.4 2.3.4.5 3.4.5.6

In both cases, the domains should be configured to use GANDI LiveDNS.
"""
import os
import requests
import sys
import yaml

# This can be tweaked if necessary.
config_file = os.path.join(
  os.environ["HOME"], ".config/gandi/config.yaml")
apiurl = "https://dns.api.gandi.net/api/v5/domains"
apikey = yaml.safe_load(open(config_file))["apirest"]["key"]

# Figure out if we're called for a bunch of domains, or just one.
domain_or_domain_file = sys.argv[1]
if os.path.isfile(domain_or_domain_file):
  domains = open(domain_or_domain_file).read().split()
  domains = [ d for d in domains if not d.startswith('#') ]
  ips_file_or_tag = sys.argv[2]
  if os.path.isfile(ips_file_or_tag):
    lines = open(ips_file_or_tag).read().split('\n')
    clusters = [line.split() for line in lines]
  else:
    ips = open(f"tags/{ips_file_or_tag}/ips.txt").read().split()
    settings_file = f"tags/{tag}/settings.yaml"
    clustersize = yaml.safe_load(open(settings_file))["clustersize"]
    clusters = []
    while ips:
      clusters.append(ips[:clustersize])
      ips = ips[clustersize:]
else:
  domains = [domain_or_domain_file]
  clusters = [sys.argv[2:]]

# Now, do the work.
while domains and clusters:
  domain = domains.pop(0)
  cluster = clusters.pop(0)
  print(f"{domain} => {cluster}")
  zone = ""
  node = 0
  for ip in cluster:
    node += 1
    zone += f"@ 300 IN A {ip}\n"
    zone += f"* 300 IN A {ip}\n"
    zone += f"node{node} 300 IN A {ip}\n"
  r = requests.put(
    f"{apiurl}/{domain}/records",
    headers={
      "x-api-key": apikey,
      "content-type": "text/plain",
    },
    data=zone)
  print(r.text)

  #r = requests.get(
  #  f"{apiurl}/{domain}/records",
  #  headers={"x-api-key": apikey},
  #  )

if domains:
  print(f"Good, we have {len(domains)} domains left.")

if clusters:
  print(f"Crap, we have {len(clusters)} clusters left.")
