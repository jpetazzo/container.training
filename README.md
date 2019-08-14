# Container Training

This repository (formerly known as `orchestration-workshop`)
contains materials (slides, scripts, demo app, and other
code samples) used for various workshops, tutorials, and
training sessions around the themes of Docker, containers,
and orchestration.

For the moment, it includes:

- Introduction to Docker and Containers,
- Container Orchestration with Docker Swarm,
- Container Orchestration with Kubernetes.

These materials have been designed around the following
principles:

- they assume very little prior knowledge of Docker,
  containers, or a particular programming language;
- they can be used in a classroom setup (with an
  instructor), or self-paced at home;
- they are hands-on, meaning that they contain lots
  of examples and exercises that you can easily
  reproduce;
- they progressively introduce concepts in chapters
  that build on top of each other.

If you're looking for the materials, you can stop reading
right now, and hop to http://container.training/, which
hosts all the slides decks available.

The rest of this document explains how this repository
is structured, and how to use it to deliver (or create)
your own tutorials.


## Why a single repository?

All these materials have been gathered in a single repository
because they have a few things in common:

- some [shared slides](slides/shared/) that are re-used
  (and updated) identically between different decks;
- a [build system](slides/) generating HTML slides from
  Markdown source files;
- a [semi-automated test harness](slides/autopilot/) to check
  that the exercises and examples provided work properly;
- a [PhantomJS script](slides/slidechecker.js) to check
  that the slides look good and don't have formatting issues;
- [deployment scripts](prepare-vms/) to start training
  VMs in bulk;
- a fancy pipeline powered by
  [Netlify](https://www.netlify.com/) and continuously
  deploying `master` to http://container.training/.


## What are the different courses available?

**Introduction to Docker** is derived from the first
"Docker Fundamentals" training materials. For more information,
see [jpetazzo/intro-to-docker](https://github.com/jpetazzo/intro-to-docker).
The version in this repository has been adapted to the Markdown
publishing pipeline. It is still maintained, but only receives
minor updates once in a while.

**Container Orchestration with Docker Swarm** (formerly
known as "Orchestration Workshop") is a workshop created by Jérôme
Petazzoni in June 2015. Since then, it has been continuously updated
and improved, and received contributions from many others authors.
It is actively maintained.

**Container Orchestration with Kubernetes** was created by
Jérôme Petazzoni in October 2017, with help and feedback from
a few other contributors. It is actively maintained.


## Repository structure

- [bin](bin/)
  - A few helper scripts that you can safely ignore for now.
- [dockercoins](dockercoins/)
  - The demo app used throughout the orchestration workshops.
- [efk](efk/), [elk](elk/), [prom](prom/), [snap](snap/):
  - Logging and metrics stacks used in the later parts of
    the orchestration workshops.
- [prepare-local](prepare-local/), [prepare-machine](prepare-machine/):
  - Contributed scripts to automate the creation of local environments.
    These could use some help to test/check that they work.
- [prepare-vms](prepare-vms/):
  - Scripts to automate the creation of AWS instances for students.
    These are routinely used and actively maintained.
- [slides](slides/):
  - All the slides! They are assembled from Markdown files with
    a custom Python script, and then rendered using [gnab/remark](
    https://github.com/gnab/remark). Check this directory for more details.
- [stacks](stacks/):
  - A handful of Compose files (version 3) allowing to easily
    deploy complex application stacks.


## Course structure

(This applies only for the orchestration workshops.)

The workshop introduces a demo app, "DockerCoins," built
around a micro-services architecture. First, we run it
on a single node, using Docker Compose. Then, we pretend
that we need to scale it, and we use an orchestrator
(SwarmKit or Kubernetes) to deploy and scale the app on
a cluster.

We explain the concepts of the orchestrator. For SwarmKit,
we setup the cluster with `docker swarm init` and `docker swarm join`.
For Kubernetes, we use pre-configured clusters.

Then, we cover more advanced concepts: scaling, load balancing,
updates, global services or daemon sets.

There are a number of advanced optional chapters about
logging, metrics, secrets, network encryption, etc.

The content is very modular: it is broken down in a large
number of Markdown files, that are put together according
to a YAML manifest. This allows to re-use content
between different workshops very easily.


### DockerCoins

The sample app is in the `dockercoins` directory.
It's used during all chapters
for explaining different concepts of orchestration.

To see it in action:

- `cd dockercoins && docker-compose up -d`
- this will build and start all the services
- the web UI will be available on port 8000


## Running the Workshop

If you want to deliver one of these workshops yourself,
this section is for you!

> *This section has been mostly contributed by
> [Bret Fisher](https://twitter.com/bretfisher), who was
> one of the first persons to have the bravery of delivering
> this workshop without me. Thanks Bret! 🍻
>
> Jérôme.*


### General timeline of planning a workshop

- Fork repo and run through slides, doing the hands-on to be sure you
  understand the different `dockercoins` repo's and the steps we go through to
  get to a full Swarm Mode cluster of many containers. You'll update the first
  few slides and last slide at a minimum, with your info.
- ~~Your docs directory can use GitHub Pages.~~
- This workshop expects 5 servers per student. You can get away with as little
  as 2 servers per student, but you'll need to change the slide deck to
  accommodate. More servers = more fun.
- If you have more then ~20 students, try to get an assistant (TA) to help
  people with issues, so you don't have to stop the workshop to help someone
  with ssh etc.
- AWS is our most tested process for generating student machines. In
  `prepare-vms` you'll find scripts to create EC2 instances, install docker,
  pre-pull images, and even print "cards" to place at each students seat with
  IP's and username/password.
- Test AWS Scripts: Be sure to test creating *all* your needed servers a week
  before workshop (just for a few minutes). You'll likely hit AWS limits in the
  region closest to your class, and it sometimes takes days to get AWS to raise
  those limits with a support ticket.
- Create a https://gitter.im chat room for your workshop and update slides
  with url. Also useful for TA to monitor this during workshop. You can use it
  before/after to answer questions, and generally works as a better answer then
  "email me that question".
- If you can send an email to students ahead of time, mention how they should
  get SSH, and test that SSH works. If they can `ssh github.com` and get
  `permission denied (publickey)` then they know it worked, and SSH is properly
  installed and they don't have anything blocking it. SSH and a browser are all
  they need for class.
- Typically you create the servers the day before or morning of workshop, and
  leave them up the rest of day after workshop. If creating hundreds of servers,
  you'll likely want to run all these `workshopctl` commands from a dedicated
  instance you have in same region as instances you want to create. Much faster
  this way if you're on poor internet. Also, create 2 sets of servers for
  yourself, and use one during workshop and the 2nd is a backup.
- Remember you'll need to print the "cards" for students, so you'll need to
  create instances while you have a way to print them.


### Things That Could Go Wrong

- Creating AWS instances ahead of time, and you hit its limits in region and
  didn't plan enough time to wait on support to increase your limits. :(
- Students have technical issues during workshop. Can't get ssh working,
  locked-down computer, host firewall, etc.
- Horrible wifi, or ssh port TCP/22 not open on network! If wifi sucks you
  can try using MOSH https://mosh.org which handles SSH over UDP. TMUX can also
  prevent you from losing your place if you get disconnected from servers.
  https://tmux.github.io
- Forget to print "cards" and cut them up for handing out IP's.
- Forget to have fun and focus on your students!


### Creating the VMs

`prepare-vms/workshopctl` is the script that gets you most of what you need for
setting up instances. See
[prepare-vms/README.md](prepare-vms)
for all the info on tools and scripts.


### Content for Different Workshop Durations

With all the slides, this workshop is a full day long. If you need to deliver
it in shorter timelines, here's some recommendations on what to cut out. You
can replace `---` with `???` which will hide slides. Or leave them there and
add something like `(EXTRA CREDIT)` to title so students can still view the
content but you also know to skip during presentation.


#### 3 Hour Version

- Limit time on debug tools, maybe skip a few. *"Chapter 1:
  Identifying bottlenecks"*
- Limit time on Compose, try to have them building the Swarm Mode by 30
  minutes in
- Skip most of Chapter 3, Centralized Logging and ELK
- Skip most of Chapter 4, but keep stateful services and DAB's if possible
- Mention what DAB's are, but make this part optional in case you run out
  of time


#### 2 Hour Version

- Skip all the above, and:
- Skip the story arc of debugging dockercoins all together, skipping the
  troubleshooting tools. Just focus on getting them from single-host to
  multi-host and multi-container.
- Goal is first 30min on intro and Docker Compose and what dockercoins is,
  and getting it up on one node in docker-compose.
- Next 60-75 minutes is getting dockercoins in Swarm Mode services across
  servers. Big Win.
- Last 15-30 minutes is for stateful services, DAB files, and questions.


### Pre-built images

There are pre-built images for the 4 components of the DockerCoins demo app: `dockercoins/hasher:v0.1`, `dockercoins/rng:v0.1`, `dockercoins/webui:v0.1`, and `dockercoins/worker:v0.1`. They correspond to the code in this repository.

There are also three variants, for demo purposes:

- `dockercoins/rng:v0.2` is broken (the server won't even start),
- `dockercoins/webui:v0.2` has bigger font on the Y axis and a green graph (instead of blue),
- `dockercoins/worker:v0.2` is 11x slower than `v0.1`.


## Past events

Since its inception, this workshop has been delivered dozens of times,
to thousands of people, and has continuously evolved. This is a short
history of the first times it was delivered. Look also in the "tags"
of this repository: they all correspond to successive iterations of
this workshop. If you attended a past version of the workshop, you
can use these tags to see what has changed since then.

- QCON, New York City (2015, June)
- KCDC, Kansas City (2015, June)
- JDEV, Bordeaux (2015, July)
- OSCON, Portland (2015, July)
- StrangeLoop, Saint Louis (2015, September)
- LISA, Washington D.C. (2015, November)
- SCALE, Pasadena (2016, January)
- Zenika, Paris (2016, February)
- Container Solutions, Amsterdam (2016, February)
- ... and much more!


# Problems? Bugs? Questions?

If there is a bug and you can fix it: submit a PR.
Make sure that I know who you are so that I can thank you
(because you're the real MVP!)

If there is a bug and you can't fix it, but you can
reproduce it: submit an issue explaining how to reproduce.

If there is a bug and you can't even reproduce it:
sorry. It is probably an Heisenbug. We can't act on it
until it's reproducible, alas.


# “Please teach us!”

If you have attended one of these workshops, and want
your team or organization to attend a similar one, you
can look at the list of upcoming events on
http://container.training/.

You are also welcome to reuse these materials to run
your own workshop, for your team or even at a meetup
or conference. In that case, you might enjoy watching
[Bridget Kromhout's talk at KubeCon 2018 Europe](
https://www.youtube.com/watch?v=mYsp_cGY2O0), explaining
precisely how to run such a workshop yourself.

Finally, you can also contact the following persons,
who are experienced speakers, are familiar with the
material, and are available to deliver these workshops
at your conference or for your company:

- jerome dot petazzoni at gmail dot com
- bret at bretfisher dot com

(If you are willing and able to deliver such workshops,
feel free to submit a PR to add your name to that list!)

**Thank you!**

