# MarkMaker

General principles:

- each slides deck is described in a YAML manifest;
- the YAML manifest lists a number of Markdown files
  that compose the slides deck;
- a Python script "compiles" the YAML manifest into
  a HTML file;
- that HTML file can be displayed in your browser
  (you don't need to host it), or you can publish it
  (along with a few static assets) if you want.


## Getting started

Look at the YAML file corresponding to the deck that
you want to edit. The format should be self-explanatory.

*I (Jérôme) am still in the process of fine-tuning that
format. Once I settle for something, I will add better
documentation.*

Make changes in the YAML file, and/or in the referenced
Markdown files. If you have never used Remark before:

- use `---` to separate slides,
- use `.foo[bla]` if you want `bla` to have CSS class `foo`,
- define (or edit) CSS classes in [workshop.css](workshop.css).

After making changes, run `./build.sh once`; it will
compile each `foo.yml` file into `foo.yml.html`.

You can also run `./build.sh forever`: it will monitor the current
directory and rebuild slides automatically when files are modified.

If you have problems running `./build.sh` (because of
Python dependencies or whatever),
you can also run `docker-compose up` in this directory.
It will start the `./build.sh forever` script in a container.
It will also start a web server exposing the slides
(but the slides should also work if you load them from your
local filesystem).


## Publishing pipeline

Each time we push to `master`, a webhook pings
[Netlify](https://www.netlify.com/), which will pull
the repo, build the slides (by running `build.sh once`),
and publish them to http://container.training/.

Pull requests are automatically deployed to testing
subdomains. I had no idea that I would ever say this
about a static page hosting service, but it is seriously awesome. ⚡️💥


## Extra bells and whistles

You can run `./slidechecker foo.yml.html` to check for
missing images and show the number of slides in that deck.
It requires `phantomjs` to be installed. It takes some
time to run so it is not yet integrated with the publishing
pipeline.
