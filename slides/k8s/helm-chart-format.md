# Helm chart format

- What exactly is a chart?

- What's in it?

- What would be involved in creating a chart?

  (we won't create a chart, but we'll see the required steps)

---

## What is a chart

- A chart is a set of files

- Some of these files are mandatory for the chart to be viable

  (more on that later)

- These files are typically packed in a tarball

- These tarballs are stored in "repos"

  (which can be static HTTP servers)

- We can install from a repo, from a local tarball, or an unpacked tarball

  (the latter option is preferred when developing a chart)

---

## What's in a chart

- A chart must have at least:

  - a `templates` directory, with YAML manifests for Kubernetes resources

  - a `values.yaml` file, containing (tunable) parameters for the chart

  - a `Chart.yaml` file, containing metadata (name, version, description ...)

- Let's look at a simple chart, `stable/tomcat`

---

## Downloading a chart

- We can use `helm pull` to download a chart from a repo

.exercise[

- Download the tarball for `stable/tomcat`:
  ```bash
  helm pull stable/tomcat
  ```
  (This will create a file named `tomcat-X.Y.Z.tgz`.)

- Or, download + untar `stable/tomcat`:
  ```bash
  helm pull stable/tomcat --untar
  ```
  (This will create a directory named `tomcat`.)

]

---

## Looking at the chart's content

- Let's look at the files and directories in the `tomcat` chart

.exercise[

- Display the tree structure of the chart we just downloaded:
  ```bash
  tree tomcat
  ```

]

We see the components mentioned above: `Chart.yaml`, `templates/`, `values.yaml`.

---

## Templates

- The `templates/` directory contains YAML manifests for Kubernetes resources

  (Deployments, Services, etc.)

- These manifests can contain template tags

  (using the standard Go template library)


.exercise[

- Look at the template file for the tomcat Service resource:
  ```bash
  cat tomcat/templates/appsrv-svc.yaml
  ```

]

---

## Analyzing the template file

- Tags are identified by `{{ ... }}`

- `{{ template "x.y" }}` expands a [named template](https://helm.sh/docs/chart_template_guide/named_templates/#declaring-and-using-templates-with-define-and-template)

  (previously defined with `{{ define "x.y "}}...stuff...{{ end }}`)

- The `.` in `{{ template "x.y" . }}` is the *context* for that named template

  (so that the named template block can access variables from the local context)

- `{{ .Release.xyz }}` refers to [built-in variables](https://helm.sh/docs/chart_template_guide/builtin_objects/) initialized by Helm

  (indicating the chart name, version, whether we are installing or upgrading ...)

- `{{ .Values.xyz }}` refers to tunable/settable [values](https://helm.sh/docs/chart_template_guide/values_files/)

  (more on that in a minute)

---

## Values

- Each chart comes with a
  [values file](https://helm.sh/docs/chart_template_guide/values_files/)

- It's a YAML file containing a set of default parameters for the chart

- The values can be accessed in templates with e.g. `{{ .Values.x.y }}`

  (corresponding to field `y` in map `x` in the values file)

- The values can be set or overridden when installing or ugprading a chart:

  - with `--set x.y=z` (can be used multiple times to set multiple values)

  - with `--values some-yaml-file.yaml` (set a bunch of values from a file)

- Charts following best practices will have values following specific patterns

  (e.g. having a `service` map allowing to set `service.type` etc.)

---

## Other useful tags

- `{{ if x }} y {{ end }}` allows to include `y` if `x` evaluates to `true`

  (can be used for e.g. healthchecks, annotations, or even an entire resource)

- `{{ range x }} y {{ end }}` iterates over `x`, evaluating `y` each time

  (the elements of `x` are assigned to `.` in the range scope)

- `{{- x }}`/`{{ x -}}` will remove whitespace on the left/right

- The whole [Sprig](http://masterminds.github.io/sprig/) library, with additions:

  `lower` `upper` `quote` `trim` `default` `b64enc` `b64dec` `sha256sum` `indent` `toYaml` ...

---

## Pipelines

- `{{ quote blah }}` can also be expressed as `{{ blah | quote }}`

- With multiple arguments, `{{ x y z }}` can be expressed as `{{ z | x y }}`)

- Example: `{{ .Values.annotations | toYaml | indent 4 }}`

  - transforms the map under `annotations` into a YAML string

  - indents it with 4 spaces (to match the surrounding context)

- Pipelines are not specific to Helm, but a feature of Go templates

  (check the [Go text/template documentation](https://golang.org/pkg/text/template/) for more details and examples)

---

## README and NOTES.txt

- At the top-level of the chart, it's a good idea to have a README

- It will be viewable with e.g. `helm show readme stable/tomcat`

- In the `templates/` directory, we can also have a `NOTES.txt` file

- When the template is installed (or upgraded), `NOTES.txt` is processed too

  (i.e. its `{{ ... }}` tags are evaluated)

- It gets displayed after the install or upgrade

- It's a great place to generate messages to tell the user:

  - how to connect to the release they just deployed

  - any passwords or other thing that we generated for them

---

## Additional files

- We can place arbitrary files in the chart (outside of the `templates/` directory)

- They can be accessed in templates with `.Files`

- They can be transformed into ConfigMaps or Secrets with `AsConfig` and `AsSecrets`

  (see [this example](https://helm.sh/docs/chart_template_guide/accessing_files/#configmap-and-secrets-utility-functions) in the Helm docs)

---

## Hooks and tests

- We can define *hooks* in our templates

- Hooks are resources annotated with `"helm.sh/hook": NAME-OF-HOOK`

- Hook names include `pre-install`, `post-install`, `test`, [and much more](https://helm.sh/docs/topics/charts_hooks/#the-available-hooks)

- The resources defined in hooks are loaded at a specific time

- Hook execution is *synchronous*

  (if the resource is a Job or Pod, Helm will wait for its completion)

- This can be use for database migrations, backups, notifications, smoke tests ...

- Hooks named `test` are executed only when running `helm test RELEASE-NAME`

???

:EN:- Helm charts format
:FR:- Le format des *Helm charts*
