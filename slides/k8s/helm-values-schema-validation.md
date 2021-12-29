# Helm and invalid values

- A lot of Helm charts let us specify an image tag like this:
  ```bash
  helm install ... --set image.tag=v1.0
  ```

- What happens if we make a small mistake, like this:
  ```bash
  helm install ... --set imagetag=v1.0
  ```

- Or even, like this:
  ```bash
  helm install ... --set image=v1.0
  ```

🤔

---

## Making mistakes

- In the first case:

  - we set `imagetag=v1.0` instead of `image.tag=v1.0`

  - Helm will ignore that value (if it's not used anywhere in templates)

  - the chart is deployed with the default value instead

- In the second case:

  - we set `image=v1.0` instead of `image.tag=v1.0`

  - `image` will be a string instead of an object

  - Helm will *probably* fail when trying to evaluate `image.tag`

---

## Preventing mistakes

- To prevent the first mistake, we need to tell Helm:

  *"let me know if any additional (unknown) value was set!"*

- To prevent the second mistake, we need to tell Helm:

  *"`image` should be an object, and `image.tag` should be a string!"*

- We can do this with *values schema validation*

---

## Helm values schema validation

- We can write a spec representing the possible values accepted by the chart

- Helm will check the validity of the values before trying to install/upgrade

- If it finds problems, it will stop immediately

- The spec uses [JSON Schema](https://json-schema.org/):

  *JSON Schema is a vocabulary that allows you to annotate and validate JSON documents.*

- JSON Schema is designed for JSON, but can easily work with YAML too

  (or any language with `map|dict|associativearray` and `list|array|sequence|tuple`)

---

## In practice

- We need to put the JSON Schema spec in a file called `values.schema.json`

  (at the root of our chart; right next to `values.yaml` etc.)

- The file is optional

- We don't need to register or declare it in `Chart.yaml` or anywhere

- Let's write a schema that will verify that ...

  - `image.repository` is an official image (string without slashes or dots)

  - `image.pullPolicy` can only be `Always`, `Never`, `IfNotPresent`

---

## `values.schema.json`

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
        }
      } 
    } 
  } 
}
```

---

## Testing our schema

- Let's try to install a couple releases with that schema!

.lab[

- Try an invalid `pullPolicy`:
  ```bash
  helm install broken --set image.pullPolicy=ShallNotPass
  ```

- Try an invalid value:
  ```bash
  helm install should-break --set ImAgeTAg=toto
  ```

]

- The first one fails, but the second one still passes ...

- Why?

---

## Bailing out on unkown properties

- We told Helm what properties (values) were valid

- We didn't say what to do about additional (unknown) properties!

- We can fix that with `"additionalProperties": false`

.lab[

- Edit `values.schema.json` to add `"additionalProperties": false`
  ```json
    {
      "$schema": "http://json-schema.org/schema#",
      "type": "object",
      "additionalProperties": false,
      "properties": {
      ...
  ```

]

---

## Testing with unknown properties

.lab[

- Try to pass an extra property:
  ```bash
  helm install should-break --set ImAgeTAg=toto
  ```

- Try to pass an extra nested property:
  ```bash
  helm install does-it-work --set image.hello=world
  ```

]

The first command should break.

The second will not.

`"additionalProperties": false` needs to be specified at each level.

???

:EN:- Helm schema validation
:FR:- Validation de schema Helm
