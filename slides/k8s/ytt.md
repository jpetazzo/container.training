# YTT

- YAML Templating Tool

- Part of [Carvel]

  (a set of tools for Kubernetes application building, configuration, and deployment)

- Can be used for any YAML

  (Kubernetes, Compose, CI pipelines...)

[Carvel]: https://carvel.dev/

---

## Features

- Manipulate data structures, not text (≠ Helm)

- Deterministic, hermetic execution

- Define variables, blocks, functions

- Write code in Starlark (dialect of Python)

- Define and override values (Helm-style)

- Patch resources arbitrarily (Kustomize-style)

---

## Getting started

- Install `ytt` ([binary download][download])

- Start with one (or multiple) Kubernetes YAML files

  *(without comments; no `#` allowed at this point!)*

- `ytt -f one.yaml -f two.yaml | kubectl apply -f-`

- `ytt -f. | kubectl apply -f-`

[download]: https://github.com/vmware-tanzu/carvel-ytt/releases/latest

---

## No comments?!?

- Replace `#` with `#!`

- `#@` is used by ytt

- It's a kind of template tag, for instance:

  ```yaml
  #! This is a comment
  #@ a = 42
  #@ b = "*"
  a: #@ a
  b: #@ b
  operation: multiply
  result: #@ a*b
  ```

- `#@` at the beginning of a line = instruction

- `#@` somewhere else = value

---

## Building strings

- Concatenation:

  ```yaml
    #@ repository = "dockercoins"
    #@ tag = "v0.1"
    containers:
    - name: worker
      image: #@ repository + "/worker:" + tag
  ```

- Formatting:

  ```yaml
    #@ repository = "dockercoins"
    #@ tag = "v0.1"
    containers:
    - name: worker
      image: #@ "{}/worker:{}".format(repository, tag)
  ```

---

## Defining functions

- Reusable functions can be written in Starlark (=Python)

- Blocks (`def`, `if`, `for`...) must be terminated with `#@ end`

- Example:

  ```yaml
    #@ def image(component, repository="dockercoins", tag="v0.1"):
    #@   return "{}/{}:{}".format(repository, component, tag)
    #@ end
    containers:
    - name: worker
      image: #@ image("worker")
    - name: hasher
      image: #@ image("hasher")
  ```

---

## Structured data

- Functions can return complex types

- Example: defining a common set of labels

  ```yaml
    #@ name = "worker"
    #@ def labels(component):
    #@   return {
    #@     "app": component,
    #@     "container.training/generated-by": "ytt",
    #@   }
    #@ end
    kind: Pod
    apiVersion: v1
    metadata:
      name: #@ name
      labels: #@ labels(name)
  ```

---

## YAML functions

- Function body can also be straight YAML:

  ```yaml
    #@ name = "worker"

    #@ def labels(component):
    app: #@ component
    container.training/generated-by: ytt
    #@ end

    kind: Pod
    apiVersion: v1
    metadata:
      name: #@ name
      labels: #@ labels(name)
  ```

- The return type of the function is then a [YAML fragment][fragment]

[fragment]: https://carvel.dev/ytt/docs/v0.41.0/

---

## More YAML functions

- We can load library functions:
  ```yaml
  #@ load("@ytt:sha256", "sha256")
  ```

- This is (sort of) equivalent fo `from ytt.sha256 import sha256`

- Functions can contain a mix of code and YAML fragment:
  
  ```yaml
    #@ load("@ytt:sha256", "sha256")

    #@ def annotations():
    #@ author = "Jérôme Petazzoni"
    author: #@ author
    author_hash: #@ sha256.sum(author)[:8]
    #@ end

    annotations: #@ annotations()
  ```

---

## Data values

- We can define a *schema* in a separate file:
  ```yaml
    #@data/values-schema
    --- #! there must be a "---" here!
    repository: dockercoins
    tag: v0.1
  ```

- This defines the data values (=customizable parameters),

  as well as their *types* and *default values*

- Technically, `#@data/values-schema` is an annotation,
  and it applies to a YAML document; so the following
  element must be a YAML document

- This is conceptually similar to Helm's *values* file
  <br/>
  (but with type enforcement as a bonus)

---

## Using data values

- Requires loading `@ytt:data`

- Values are then available in `data.values`

- Example:

  ```yaml
    #@ load("@ytt:data", "data")
    #@ def image(component):
    #@   return "{}/{}:{}".format(data.values.repository, component, data.values.tag)
    #@ end
    #@ name = "worker"
    containers:
    - name: #@ name
      image: #@ image(name)
  ```

---

## Overriding data values

- There are many ways to set and override data values:

  - plain YAML files

  - data value overlays

  - environment variables

  - command-line flags

- Precedence of the different methods is defined in the [docs]

[docs]: https://carvel.dev/ytt/docs/v0.41.0/ytt-data-values/#data-values-merge-order

---

## Values in plain YAML files

- Content of `values.yaml`:
  ```yaml
  tag: latest
  ```

- Values get merged with `--data-values-file`:
  ```bash
  ytt -f config/ --data-values-file values.yaml
  ```

- Multiple files can be specified

- These files can also be URLs!

---

## Data value overlay

- Content of `values.yaml`:
  ```yaml
  #@data/values
  --- #! must have --- here
  tag: latest
  ```

- Values get merged by being specified like "normal" files:
  ```bash
  ytt -f config/ -f values.yaml
  ```

- Multiple files can be specified

---

## Set a value with a flag

- Set a string value:
  ```bash
  ytt -f config/ --data-value tag=latest
  ```

- Set a YAML value (useful to parse it as e.g. integer, boolean...):
  ```bash
  ytt -f config/ --data-value-yaml replicas=10
  ```

- Read a string value from a file:
  ```bash
  ytt -f config/ --data-value-file ca_cert=cert.pem
  ```

---

## Set values from environment variables

- Set environment variables with a prefix:
  ```bash
  export VAL_tag=latest
  export VAL_repository=ghcr.io/dockercoins
  ```

- Use the variables as strings:
  ```bash
  ytt -f config/ --data-values-env VAL
  ```

- Or parse them as YAML:
  ```bash
  ytt -f config/ --data-values-env-yaml VAL
  ```

---

## Lines starting with `#@`

- This generates an empty document:
  ```yaml
  #@ def hello():
  hello: world
  #@ end
  
  #@ hello()
  ```

- Do this instead:
  ```yaml
  #@ def hello():
  hello: world
  #@ end
  
  --- #@ hello()
  ```

---

## Generating multiple documents, take 1

- This won't work:

  ```yaml
  #@ def app():
  kind: Deployment
  apiVersion: apps/v1
  --- #! separate from next document
  kind: Service
  apiVersion: v1
  #@ end

  --- #@ app()
  ```

---

## Generating multiple documents, take 2

- This won't work either:

  ```yaml
  #@ def app():
  --- #! the initial separator indicates "this is a Document Set"
  kind: Deployment
  apiVersion: apps/v1
  --- #! separate from next document
  kind: Service
  apiVersion: v1
  #@ end

  --- #@ app()
  ```

---

## Generating multiple documents, take 3

- We must use the `template` module:

  ```yaml
  #@ load("@ytt:template", "template")

  #@ def app():
  --- #! the initial separator indicates "this is a Document Set"
  kind: Deployment
  apiVersion: apps/v1
  --- #! separate from next document
  kind: Service
  apiVersion: v1
  #@ end

  --- #@ template.replace(app())
  ```

- `template.replace(...)` is the only way (?) to replace one element with many

---

## Libraries

- A reusable ytt configuration can be transformed into a library

- Put it in a subdirectory named `_ytt_lib/whatever`, then:

  ```yaml
  #@ load("@ytt:library", "library")
  #@ load("@ytt:template", "template")
  #@ whatever = library.get("whatever")
  #@ my_values = {"tag": "latest", "registry": "..."}
  #@ output = whatever.with_data_values(my_values).eval()
  --- #@ template.replace(output)
  ```

- The `with_data_values()` step is optional, but useful to "configure" the library

- Note the whole combo:
  ```yaml
  template.replace(library.get("...").with_data_values(...).eval())
  ```

---

## Overlays

- Powerful, but complex, but powerful! 💥

- Define transformations that are applied after generating the whole document set

- General idea:

  - select YAML nodes to be transformed with an `#@overlay/match` decorator

  - write a YAML snippet with the modifications to be applied
    <br/>
    (a bit like a strategic merge patch)

---

## Example

```yaml
#@ load("@ytt:overlay", "overlay")

#@ selector = {"kind": "Deployment", "metadata": {"name": "worker"}}
#@overlay/match by=overlay.subset(selector)
--- 
spec:
  replicas: 10
```

- By default, `#@overlay/match` must find *exactly* one match

  (that can be changed by specifying `expects=...`, `missing_ok=True`... see [docs])

- By default, the specified fields (here, `spec.replicas`) must exist

  (that can also be changed by annotating the optional fields)

[docs]: https://carvel.dev/ytt/docs/v0.41.0/lang-ref-ytt-overlay/#overlaymatch

---

## Matching using a YAML document

```yaml
#@ load("@ytt:overlay", "overlay")

#@ def match():
kind: Deployment
metadata:
  name: worker
#@ end

#@overlay/match by=overlay.subset(match())
--- 
spec:
  replicas: 10
```

- This is equivalent to the subset match of the previous slide

- It will find YAML nodes having all the listed fields

---

## Removing a field

```yaml
#@ load("@ytt:overlay", "overlay")

#@ def match():
kind: Deployment
metadata:
  name: worker
#@ end

#@overlay/match by=overlay.subset(match())
--- 
spec:
  #@overlay/remove
  replicas:
```

- This would remove the `replicas:` field from a specific Deployment spec

- This could be used e.g. when enabling autoscaling

---

## Selecting multiple nodes

```yaml
#@ load("@ytt:overlay", "overlay")

#@ def match():
kind: Deployment
#@ end

#@overlay/match by=overlay.subset(match()), expects="1+"
--- 
spec:
  #@overlay/remove
  replicas:
```

- This would match all Deployments
  <br/>
  (assuming that *at least one* exists)

- It would remove the `replicas:` field from their spec
  <br/>
  (the field must exist!)

---

## Adding a field

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.all, expects="1+"
--- 
metadata:
  #@overlay/match missing_ok=True
  annotations:
    #@overlay/match expects=0
    rainbow: 🌈
```

- `#@overlay/match missing_ok=True`
  <br/>
  *will match whether our resources already have annotations or not*

- `#@overlay/match expects=0`
  <br/>
  *will only match if the `rainbow` annotation doesn't exist*
  <br/>
  *(to make sure that we don't override/replace an existing annotation)*

---

## Overlays vs data values

- The documentation has a [detailed discussion][docs] about this question

- In short:

  - values = for parameters that are exposed to the user

  - overlays = for arbitrary extra modifications

- Values are easier to use (use them when possible!)

- Fallback to overlays when values don't expose what you need

  (keeping in mind that overlays are harder to write/understand/maintain)

[docs]: https://carvel.dev/ytt/docs/v0.41.0/data-values-vs-overlays/

---

## Gotchas

- Reminder: put your `#@` at the right place!

```yaml
#! This will generate "hello, world!"
--- #@ "{}, {}!".format("hello", "world")
```

```yaml
#! But this will generate an empty document
--- 
#@ "{}, {}!".format("hello", "world")
```

- Also, don't use YAML anchors (`*foo` and `&foo`)

- They don't mix well with ytt

- Remember to use `template.render(...)` when generating multiple nodes

  (or to update lists or arrays without replacing them entirely)

---

## Next steps with ytt

- Read this documentation page about [injecting secrets][secrets]

- Check the [FAQ], it gives some insights about what's possible with ytt

- Exercise idea: write an overlay that will find all ConfigMaps mounted in Pods...

  ...and annotate the Pod with a hash of the ConfigMap

[FAQ]: https://carvel.dev/ytt/docs/v0.41.0/faq/
[secrets]: https://carvel.dev/ytt/docs/v0.41.0/injecting-secrets/

???

:EN:- YTT
:FR:- YTT
