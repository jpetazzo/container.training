# Helm secrets

- Helm can do *rollbacks*:

  - to previously installed charts

  - to previous sets of values

- How and where does it store the data needed to do that?

- Let's investigate!

---

## Adding the repo

- If you haven't done it before, you need to add the repo for that chart

.lab[

- Add the repo that holds the chart for the OWASP Juice Shop:
  ```bash
  helm repo add juice https://charts.securecodebox.io
  ```

]

---

## We need a release

- We need to install something with Helm

- Let's use the `juice/juice-shop` chart as an example

.lab[

- Install a release called `orange` with the chart `juice/juice-shop`:
  ```bash
  helm upgrade orange juice/juice-shop --install
  ```

- Let's upgrade that release, and change a value:
  ```bash
  helm upgrade orange juice/juice-shop --set ingress.enabled=true
  ```

]

---

## Release history

- Helm stores successive revisions of each release

.lab[

- View the history for that release:
  ```bash
  helm history orange
  ```

]

Where does that come from?

---

## Investigate

- Possible options:

  - local filesystem (no, because history is visible from other machines)

  - persistent volumes (no, Helm works even without them)

  - ConfigMaps, Secrets?

.lab[

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

.lab[

- Examine the secret corresponding to the second release of `orange`:
  ```bash
  kubectl describe secret sh.helm.release.v1.orange.v2
  ```
  (`v1` is the secret format; `v2` means revision 2 of the `orange` release)

]

There is a key named `release`.

---

## Unpacking the release data

- Let's see what's in this `release` thing!

.lab[

- Dump the secret:
  ```bash
  kubectl get secret sh.helm.release.v1.orange.v2 \
      -o go-template='{{ .data.release }}'
  ```

]

Secrets are encoded in base64. We need to decode that!

---

## Decoding base64

- We can pipe the output through `base64 -d` or use go-template's `base64decode`

.lab[

- Decode the secret:
  ```bash
  kubectl get secret sh.helm.release.v1.orange.v2 \
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

.lab[

- Decode it twice:
  ```bash
  kubectl get secret sh.helm.release.v1.orange.v2 \
      -o go-template='{{ .data.release | base64decode | base64decode }}'
  ```

]

--

... OK, that was *a lot* of binary data. What sould we do with it?

---

## Guessing data type

- We could use `file` to figure out the data type

.lab[

- Pipe the decoded release through `file -`:
  ```bash
  kubectl get secret sh.helm.release.v1.orange.v2 \
      -o go-template='{{ .data.release | base64decode | base64decode }}' \
      | file -
  ```

]

--

Gzipped data! It can be decoded with `gunzip -c`.

---

## Uncompressing the data

- Let's uncompress the data and save it to a file

.lab[

- Rerun the previous command, but with `| gunzip -c > release-info` :
  ```bash
  kubectl get secret sh.helm.release.v1.orange.v2 \
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
- `name` (name of the release, so `orange`)
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

???

:EN:- Deep dive into Helm internals
:FR:- Fonctionnement interne de Helm
