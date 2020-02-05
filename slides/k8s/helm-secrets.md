# Helm secrets

- Helm can do *rollbacks*:

  - to previously installed charts

  - to previous sets of values

- How and where does it store the data needed to do that?

- Let's investigate!

---

## We need a release

- We need to install something with Helm

- Let's use the `stable/tomcat` chart as an example

.exercise[

- Install a release called `tomcat` with the chart `stable/tomcat`:
  ```bash
  helm upgrade tomcat stable/tomcat --install
  ```

- Let's upgrade that release, and change a value:
  ```bash
  helm upgrade tomcat stable/tomcat --set ingress.enabled=true
  ```

]

---

## Release history

- Helm stores successive revisions of each release

.exercise[

- View the history for that release:
  ```bash
  helm history tomcat
  ```

]

Where does that come from?

---

## Investigate

- Possible options:

  - local filesystem (no, because history is visible from other machines)

  - persistent volumes (no, Helm works even without them)

  - ConfigMaps, Secrets?

.exercise[

- Look for ConfigMaps and Secrets:
  ```bash
  kubectl get configmaps,secrets
  ```

]

--

We should see a number of secrets with TYPE `helm.sh/release.v1`.

---

## Unpacking a secret

- Let's find out what is in these Helm secrets

.exercise[

- Examine the secret corresponding to the second release of `tomcat`:
  ```bash
  kubectl describe secret sh.helm.release.v1.tomcat.v2
  ```
  (`v1` is the secret format; `v2` means revision 2 of the `tomcat` release)

]

There is a key named `release`.

---

## Unpacking the release data

- Let's see what's in this `release` thing!

.exercise[

- Dump the secret:
  ```bash
  kubectl get secret sh.helm.release.v1.tomcat.v2 \
      -o go-template='{{ .data.release }}'
  ```

]

Secrets are encoded in base64. We need to decode that!

---

## Decoding base64

- We can pipe the output through `base64 -d` or use go-template's `base64decode`

.exercise[

- Decode the secret:
  ```bash
  kubectl get secret sh.helm.release.v1.tomcat.v2 \
      -o go-template='{{ .data.release | base64decode }}'
  ```

]

--

... Wait, this *still* looks like base64. What's going on?

--

Let's try one more round of decoding!

---

## Decoding harder

- Just add one more base64 decode filter

.exercise[

- Decode it twice:
  ```bash
  kubectl get secret sh.helm.release.v1.tomcat.v2 \
      -o go-template='{{ .data.release | base64decode | base64decode }}'
  ```

]

--

... OK, that was *a lot* of binary data. What sould we do with it?

---

## Guessing data type

- We could use `file` to figure out the data type

.exercise[

- Pipe the decoded release through `file -`:
  ```bash
  kubectl get secret sh.helm.release.v1.tomcat.v2 \
      -o go-template='{{ .data.release | base64decode | base64decode }}' \
      | file -
  ```

]

--

Gzipped data! It can be decoded with `gunzip -c`.

---

## Uncompressing the data

- Let's uncompress the data and save it to a file

.exercise[

- Rerun the previous command, but with `| gunzip -c > release-info` :
  ```bash
  kubectl get secret sh.helm.release.v1.tomcat.v2 \
      -o go-template='{{ .data.release | base64decode | base64decode }}' \
      | gunzip -c > release-info
  ```

- Look at `release-info`:
  ```bash
  cat release-info
  ```

]

--

It's a bundle of ~~YAML~~ JSON.

---

## Looking at the JSON

If we inspect that JSON (e.g. with `jq keys release-info`), we see:

- `chart` (contains the entire chart used for that release)
- `config` (contains the values that we've set)
- `info` (date of deployment, status messages)
- `manifest` (YAML generated from the templates)
- `name` (name of the release, so `tomcat`)
- `namespace` (namespace where we deployed the release)
- `version` (revision number within that release; starts at 1)

The chart is in a structured format, but it's entirely captured in this JSON.

---

## Conclusions

- Helm stores each release information in a Secret in the namespace of the release

- The secret is JSON object (gzipped and encoded in base64)

- It contains the manifests generated for that release

- ... And everything needed to rebuild these manifests

  (including the full source of the chart, and the values used)

- This allows arbitrary rollbacks, as well as tweaking values even without having access to the source of the chart (or the chart repo) used for deployment
