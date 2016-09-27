# Orchestration at scale(s)

This is the material for the "Docker orchestration workshop"
written and delivered by Jérôme Petazzoni (and possibly others)
at multiple conferences and events like:

- QCON, New York City (2015, June)
- KCDC, Kansas City (2015, June)
- JDEV, Bordeaux (2015, July)
- OSCON, Portland (2015, July)
- StrangeLoop, Saint Louis (2015, September)
- LISA, Washington D.C. (2015, November)
- SCALE, Pasadena (2016, January)
- Zenika, Paris (2016, February)
- Container Solutions, Amsterdam (2016, February)

## How this repo is organized
- **dockercoins**
  - compose files and source code for the dockercoins sample apps used throughout the workshop
- **docs**
  - presentation slide deck, using https://remarkjs.com
- **prepare-vms**
  - scripts for automating the creation of AWS instances for students

## Slide Deck
- The slides are in the `docs` directory.
- To view them locally open `docs/index.html` in your browser. It works offline too.
- To view them online open https://jpetazzo.github.io/orchestration-workshop/ in your browser.
- They use https://remarkjs.com to allow simple markdown in a html file that remark will transform into a presentation in the browser.

## Sample code

The sample app is in the `dockercoins` directory.

To see it in action:

- `cd dockercoins && docker-compose up -d`
- this will build and start all the services
- the web UI will be available on port 8000


## Running the workshop

General timeline of planning a workshop

- Run through slides, doing the hands-on to be sure you understand the different `dockercoins` repo's and the steps we go through to get to a full Swarm Mode cluster of many containers.
- This workshop expects 5 servers per student. You can get away with as little as 2 servers per student, but you'll need to change the slide deck to accomidate.
- AWS is our most tested process for generating student machines. In `prepare-vms` you'll find scripts to create EC2 instances, install docker, pre-pull images, and even print "cards" to place at each students seat with IP's and username/password.
- Be sure to test creating *all* your needed servers a week before workshop. You'll likely hit AWS limits in the region closest to your class, and it sometimes takes days to get AWS to raise those limits with a support ticket.
- Typically we create the servers the day before or morning of workshop, and leave them up the rest of day after workshop. If creating hundreds of servers, you'll likely want to run all these `trainer` commands from a dedicated instance you have in same region as instances you want to create.
- Remember you'll need to print the "cards" for students, so you'll need to create instances while you have a way to print them.


### Creating the VMs

`prepare-vms/trainer` is the script that gets you most of what you need for setting up instances. See `prepare-vms/README.md` for more info.



### Generating the printed cards

- Put `ips.txt` file in `prepare-vms` directory.
- Generate HTML file.
- Open it in Chrome.
- Transform to PDF.
- Print it.


### Deploying your SSH key to all the machines

- Make sure that you have SSH keys loaded (`ssh-add -l`).
- Source `rc`.
- Run `pcopykey`.


### Installing extra packages

- Source `postprep.rc`.
  (This will install a few extra packages, add entries to
  /etc/hosts, generate SSH keys, and deploy them on all hosts.)


### Final touches

- Set two groups of machines for instructor's use.
- You will use the first group during the workshop.
- The second group will run a web server with the slides.
- Log into the first machine of the second group.
- Git clone this repo.
- Put up the web server as instructed above.
- Use cli53 to add an A record for e.g. `view.dckr.info`.


# Problems? Bugs? Questions?

If there is a bug and you can fix it: submit a PR.
Make sure that I know who you are so that I can thank you
(because you're the real MVP!)

If there is a bug and you can't fix it, but you can
reproduce it: submit an issue explaining how to reproduce.

If there is a bug and you can't even reproduce it:
sorry. It is probably an Heisenbug. I can't act on it
until it's reproducible.

if you have attended this workshop and have feedback,
or if you want us to deliver that workshop at your
conference or for your company: contact me (jerome
at docker dot com).

Thank you!
