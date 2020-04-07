#!/bin/sh

# This script helps to add "force-redirects" where needed.
# This might replace your entire git repos with Vogon poetry.
# Use at your own peril!

set -eu

# The easiest way to set this env var is by copy-pasting from
# the netlify web dashboard, then doctoring the output a bit.
# Yeah, that's gross, but after spending 10 minutes with the
# API and the CLI and OAuth, it took about 10 seconds to do it
# with le copier-coller, so ... :)

SITES="
2020-01-caen
2020-01-zr
2020-02-caen
2020-02-enix
2020-02-outreach
2020-02-vmware
2020-03-ardan
2020-03-qcon
alfun-2019-06
boosterconf2018
clt-2019-10
dc17eu
decembre2018
devopsdaysams2018
devopsdaysmsp2018
gotochgo2018
gotochgo2019
indexconf2018
intro-2019-01
intro-2019-04
intro-2019-06
intro-2019-08
intro-2019-09
intro-2019-11
intro-2019-12
k8s2d
kadm-2019-04
kadm-2019-06
kube
kube-2019-01
kube-2019-02
kube-2019-03
kube-2019-04
kube-2019-06
kube-2019-08
kube-2019-09
kube-2019-10
kube-2019-11
lisa-2019-10
lisa16t1
lisa17m7
lisa17t9
maersk-2019-07
maersk-2019-08
ndcminnesota2018
nr-2019-08
oscon2018
oscon2019
osseu17
pycon2019
qconsf18wkshp
qconsf2017intro
qconsf2017swarm
qconsf2018
qconuk2019
septembre2018
sfsf-2019-06
srecon2018
swarm2017
velny-k8s101-2018
velocity-2019-11
velocityeu2018
velocitysj2018
vmware-2019-11
weka
wwc-2019-10
wwrk-2019-05
wwrk-2019-06
"

for SITE in $SITES; do
	echo "##### $SITE"
	git checkout -q origin/$SITE
	# No _redirects? No problem.
	if ! [ -f _redirects ]; then
		continue
	fi
	# If there is already a force redirect on /, we're good.
	if grep '^/ .* 200!' _redirects; then
		continue
	fi
	# If there is a redirect on / ... and it's not forced ... do something.
	if grep "^/ .* 200$" _redirects; then
		echo "##### $SITE needs to be patched"
		sed -i 's,^/ \(.*\) 200$,/ \1 200!,' _redirects
		git add _redirects
		git commit -m "fix-redirects.sh: adding forced redirect"
		git push origin HEAD:$SITE
		continue
	fi
    if grep "^/ " _redirects; then
		echo "##### $SITE with / but no status code"
		echo "##### Should I add '200!' ?"
		read foo
		sed -i 's,^/ \(.*\)$,/ \1 200!,' _redirects
		git add _redirects
		git commit -m "fix-redirects.sh: adding status code and forced redirect"
		git push origin HEAD:$SITE
		continue
	fi
    echo "##### $SITE without / ?"
    cat _redirects
done
