# Creating even better charts

- We will going to use dependencies to write less code

- reuse a community chart for redis

- We will see how it improve the developer life as well as the one of the user

- We will see that sometimes dependencies could also remove a lot of code

---

## Assertions about dockercoins

- Every image is custom except the one of redis

- It's is quite logic that deployment are custom except of the one of redis

- So if redis is not custom can we use templates of someone else ?

- Yes, through dependencies

---

## Add redis dependency

- In `Chart.yaml` fill the `dependencies` section:
  ```yaml
    dependencies:
      - name: redis
        version: 11.0.5
        repository: https://charts.bitnami.com/bitnami
        condition: redis.enabled
  ```
- `condition` will trigger at install or upgrade to template or not the dependency

- Now, we can tell helm to fetch the dependency by running `helm dependency update`

  (abbv `helm dep up`)

- Another file has been created: `Chart.lock`. What should we do with this file ?

  - Short answer: add it to the source tree.
---

## Chart.lock

- The real command to fetch dependency is `helm depedency build`

  (abbv `helm dep build`)

- It looks into the `Chart.lock` to fetch the exact version

- So what's the matter with the version in `Chart.yaml`.

  - This is indicative version for the `helm dep update` *dependency resolution* process
  - You can specify loose version requirements
    ```yaml
      dependencies:
        - name: redis
          version: >=11 <12
          repository: https://charts.bitnami.com/bitnami
    ```
- We don't need to `helm dep build` after `helm dep up` : it's included

---

## Dependency live matters ?

- Every dependency lives in the `charts/` dependency

- Downloaded dependencies will stay in compress binary format (`.tgz`)

- Should we commit dependency ?

- Pro:

  - more resilient to internet/mirror failures/decomissioning

- Cons:

  - Tracking binary files in source tree may require additionnal tools (like git-lfs) to be done correctly

---

## Dependency tuning

- If we install our chart it will not work as the name of the redis service is not `redis`

- Debug:

  - Service name is `{{ template "redis.fullname" . }}-master`

  - `redis.fullname` looks like
    ```
      {{- define "redis.fullname" -}}
      {{- if .Values.fullnameOverride -}}
      {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
      {{- else -}}
      [...]
      {{- end }}
      {{- end }}
    ```
---
## Passing variable

- If we pass `fullnameOverride=redis`, we will make the template part to output `redis`

- We can pass variables from top-level to children, editing parent's `values.yaml`:
   ```yaml
     redis: # Name of the dependency
       fullnameOverride: redis # Value passed to redis
       cluster:                # Other values passed to redis
         enabled: false
   ```
- We can even pass template `{{ include "template.name" }}`, but warning:

   - Need to be evaluated with the `tpl` function, on the child side
   - Evaluated in the context of the child, with no access to parent variables

- User can also set variables with `--set=` or with `--values=`

---
## Embedding dependency

- To remove `-master`, we will need a bit more the values to pass.

- We need to edit the chart templates.

- First of all we need to decompress the chart

- Adjust `Chart.yaml` and reference to it
  ```yaml
    dependencies:
      - name: redis
        version: '*' # No need to constraint version, from local files
  ```

- Run `helm dep update`

- We can edit the template and test installation !
---

class: extra-details

## Chart v1

- Chart `apiVersion: v1` is the only version supported by helm v2

- Chart v1 is also supported by helm v3

- To be used, if we're looking for compatibility

- Instead of `Chart.yaml` it use a separated file `requirements.yaml`

- We should commit the created `requirements.lock` instead of `Charts.lock`

---

???

:EN: - helm dependencies
:FR: - dépendences helm

