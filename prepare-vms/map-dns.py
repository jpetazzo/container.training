#!/usr/bin/env python
import os
import requests
import yaml

# configurable stuff
domains_file = "../../plentydomains/domains.txt"
config_file = os.path.join(
	os.environ["HOME"], ".config/gandi/config.yaml")
tag = "test"
apiurl = "https://dns.api.gandi.net/api/v5/domains"

# inferred stuff
domains = open(domains_file).read().split()
apikey = yaml.safe_load(open(config_file))["apirest"]["key"]
ips = open(f"tags/{tag}/ips.txt").read().split()
settings_file = f"tags/{tag}/settings.yaml"
clustersize = yaml.safe_load(open(settings_file))["clustersize"]

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
