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


## Slides

The slides are in the `docs` directory.

To view them locally open `docs/index.html` in your browser.

To view them online open https://jpetazzo.github.io/orchestration-workshop/ in your browser.

## Sample code

The sample app is in the `dockercoins` directory.

To see it in action:

- `cd dockercoins && docker-compose up -d`
- this will build and start all the services
- the web UI will be available on port 8000


## Running the workshop

WARNING: those instructions are incomplete. Consider
them as notes quickly drafted on a napkin rather than
proper documentation!


### Creating the VMs

I use the `trainctl` script from the `docker-fundamentals`
repository. Sorry if you don't have that!

After starting the VMs, use the `trainctl ips` command
to dump the list of IP addresses into a file named `ips.txt`.


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
