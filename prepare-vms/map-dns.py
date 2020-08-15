#!/usr/bin/env python
"""
There are two ways to use this script:

1. Pass a tag name as a single argument.
It will then take the clusters corresponding to that tag, and assign one
domain name per cluster. Currently it gets the domains from a hard-coded
path. There should be more domains than clusters.
Example: ./map-dns.py 2020-08-15-jp

2. Pass a domain as the 1st argument, and IP addresses then.
It will configure the domain with the listed IP addresses.
Example: ./map-dns.py open-duck.site 1.2.3.4 2.3.4.5 3.4.5.6

In both cases, the domains should be configured to use GANDI LiveDNS.
"""
import os
import requests
import sys
import yaml

# configurable stuff
domains_file = "../../plentydomains/domains.txt"
config_file = os.path.join(
	os.environ["HOME"], ".config/gandi/config.yaml")
tag = None
apiurl = "https://dns.api.gandi.net/api/v5/domains"

if len(sys.argv) == 2:
	tag = sys.argv[1]
	domains = open(domains_file).read().split()
	ips = open(f"tags/{tag}/ips.txt").read().split()
	settings_file = f"tags/{tag}/settings.yaml"
	clustersize = yaml.safe_load(open(settings_file))["clustersize"]
else:
	domains = [sys.argv[1]]
	ips = sys.argv[2:]
	clustersize = len(ips)

# inferred stuff
apikey = yaml.safe_load(open(config_file))["apirest"]["key"]

# now do the fucking work
while domains and ips:
	domain = domains[0]
	domains = domains[1:]
	cluster = ips[:clustersize]
	ips = ips[clustersize:]
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
		headers={"x-api-key": apikey},
		data=zone)
	print(r.text)

	#r = requests.get(
	#	f"{apiurl}/{domain}/records",
	#	headers={"x-api-key": apikey},
	#	)

if domains:
	print(f"Good, we have {len(domains)} domains left.")

if ips:
	print(f"Crap, we have {len(ips)} IP addresses left.")
