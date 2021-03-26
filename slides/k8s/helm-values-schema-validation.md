---
## Helm mistake

- What if I put wrong values and deploy the helm chart ?

.exercice[

  - Install a helm release with wrong values:

     `helm install broken-release --set=foo=bar --set=ImAgeTAg=toto`
]

- What happened ?

    - The `broken-release` is installed 😨

- Is-it really broken ?

    - Not really: helm just ignored the values it doesn't know about 😓

- Is there something we can do to avoid mistakes ?


---

## Helm values schema validation

- With *values schema validation*, we can write a spec representing the possible
  values accepted by the chart.

- Moving away from the spec make helm bailing out the installation/upgrade

- It uses [jsonschema](https://json-schema.org/) language which is a

    `"a vocabulary that allows you to annotate and validate JSON documents."`

- But can be adapted like here to validate any markup language that consist in
   `map|dict|associativearray` and `list|array|sequence|tuple` like *yaml*

---
.exercise[

- Let's create a `values.schema.json`:
  ```json
    {
      "$schema": "http://json-schema.org/schema#",
      "type": "object",
      "properties": {
        "image": {
          "type": "object",
          "properties": {
            "repository": {
              "type": "string",
              "pattern": "^[a-z0-9-_]+$"
            },
            "pullPolicy": {
              "type": "string",
              "pattern": "^(Always|Never|IfNotPresent)$"
    } } } } }
  ```
]

---
## Testing Helm validation

- Now we can test to install Wrong release:

.exercise[

- Run:

   `helm install broken --set image=image.pullPolicy=ShallNotPass`

- Run:

   `helm install should-break --set=foo=bar --set=ImAgeTAg=toto`
]

- First fails, but second one still pass even if we put a `values.schema.json` !

- Why ?

---
## Bailing out on unkown properties

- We told helm more about valid properties but not what to do with non-existing ones

- We can fix that with `"additionalProperties": false`:

.exercise[

- Edit `values.schema.json` to add `"additionalProperties": false`
  ```json
    {
      "$schema": "http://json-schema.org/schema#",
      "type": "object",
      "properties": {
        "image": {  [...]  }
      },
      "additionalProperties": false
    }
  ```

- And test again: `helm install should-break --set=foo=bar --set=ImAgeTAg=toto`
]
---


