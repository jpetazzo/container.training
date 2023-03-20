# Gentle introduction to YAML

- YAML Ain't Markup Language (according to [yaml.org][yaml])

- *Almost* required when working with containers:

  - Docker Compose files

  - Kubernetes manifests

  - Many CI pipelines (GitHub, GitLab...)

- If you don't know much about YAML, this is for you!

[yaml]: https://yaml.org/

---

## What is it?

- Data representation language

```yaml
- country: France
  capital: Paris
  code: fr
  population: 68042591
- country: Germany
  capital: Berlin
  code: de
  population: 84270625
- country: Norway
  capital: Oslo
  code: no # It's a trap!
  population: 5425270
```

- Even without knowing YAML, we probably can add a country to that file :)

---

## Trying YAML

- Method 1: in the browser

  https://onlineyamltools.com/convert-yaml-to-json

  https://onlineyamltools.com/highlight-yaml

- Method 2: in a shell

  ```bash
  yq . foo.yaml
  ```

- Method 3: in Python

  ```python
    import yaml; yaml.safe_load("""
    - country: France
      capital: Paris
    """)
  ```

---

## Basic stuff

- Strings, numbers, boolean values, `null`

- Sequences (=arrays, lists)

- Mappings (=objects)

- Superset of JSON

  (if you know JSON, you can just write JSON)

- Comments start with `#`

- A single *file* can have multiple *documents*

  (separated by `---` on a single line)

---

## Sequences

- Example: sequence of strings
  ```yaml
  [ "france", "germany", "norway" ]
  ```

- Example: the same sequence, without the double-quotes
  ```yaml
  [ france, germany, norway ]
  ```

- Example: the same sequence, in "block collection style" (=multi-line)
  ```yaml
  - france
  - germany
  - norway
  ```

---

## Mappings

- Example: mapping strings to numbers
  ```yaml
  { "france": 68042591, "germany": 84270625, "norway": 5425270 }
  ```

- Example: the same mapping, without the double-quotes
  ```yaml
  { france: 68042591, germany: 84270625, norway: 5425270 }
  ```

- Example: the same mapping, in "block collection style"
  ```yaml
  france: 68042591
  germany: 84270625
  norway: 5425270
  ```

---

## Combining types

- In a sequence (or mapping) we can have different types

  (including other sequences or mappings)

- Example:
  ```yaml
  questions: [ name, quest, favorite color ]
  answers: [ "Arthur, King of the Britons", Holy Grail, purple, 42 ]
  ```

- Note that we need to quote "Arthur" because of the comma

- Note that we don't have the same number of elements in questions and answers

---

## More combinations

- Example:
  ```yaml
    - service: nginx
      ports: [ 80, 443 ]
    - service: bind
      ports: [ 53/tcp, 53/udp ]
    - service: ssh
      ports: 22
  ```

- Note that `ports` doesn't always have the same type

  (the code handling that data will probably have to be smart!)

---

## ⚠️ Automatic booleans

```yaml
codes:
  france: fr
  germany: de
  norway: no
```

--

```json
{
  "codes": {
    "france": "fr",
    "germany": "de",
    "norway": false
  }
}
```

---

## ⚠️ Automatic booleans

- `no` can become `false`

  (it depends on the YAML parser used)

- It should be quoted instead:

  ```yaml
    codes:
      france: fr
      germany: de
      norway: "no"
  ```

---

## ⚠️ Automatic floats

```yaml
version:
  libfoo: 1.10
  fooctl: 1.0
```

--

```json
{
  "version": {
    "libfoo": 1.1,
    "fooctl": 1
  }
}
```

---

## ⚠️ Automatic floats

- Trailing zeros disappear

- These should also be quoted:

  ```yaml
    version:
      libfoo: "1.10"
      fooctl: "1.0"
  ```

---

## ⚠️ Automatic times

```yaml
portmap:
- 80:80
- 22:22
```

--

```json
{
  "portmap": [
    "80:80",
    1342
  ]
}
```

---

## ⚠️ Automatic times

- `22:22` becomes `1342`

- Thats 22 minutes and 22 seconds = 1342 seconds

- Again, it should be quoted

---

## Document separator

- A single YAML *file* can have multiple *documents* separated by `---`:

  ```yaml
    This is a document consisting of a single string.
    --- 💡
    name: The second document
    type: This one is a mapping (key→value)
    --- 💡
    - Third document
    - This one is a sequence
  ```

- Some folks like to add an extra `---` at the beginning and/or at the end

  (it's not mandatory but can help e.g. to `cat` multiple files together)

.footnote[💡 Ignore this; it's here to work around [this issue][remarkyaml].]

[remarkyaml]: https://github.com/gnab/remark/issues/679

---

## Multi-line strings

Try the following block in a YAML parser:

```yaml
add line breaks: "in double quoted strings\n(like this)"
preserve line break: |
  by using
  a pipe (|)
  (this is great for embedding shell scripts, configuration files...)
do not preserve line breaks: >
  by using
  a greater-than (>)
  (this is great for embedding very long lines)
```

See https://yaml-multiline.info/ for advanced multi-line tips!

(E.g. to strip or keep extra `\n` characters at the end of the block.)

---

class: extra-details

## Advanced features

Anchors let you "memorize" and re-use content:

```yaml
debian: &debian
  packages: deb
  latest-stable: bullseye

also-debian: *debian

ubuntu:
  <<: *debian
  latest-stable: jammy
```

---

class: extra-details

## YAML, good or evil?

- Natural progression from XML to JSON to YAML

- There are other data languages out there

  (e.g. HCL, domain-specific things crafted with Ruby, CUE...)

- Compromises are made, for instance:

  - more user-friendly → more "magic" with side effects

  - more powerful → steeper learning curve

- Love it or loathe it but it's a good idea to understand it!

- Interesting tool if you appreciate YAML: https://carvel.dev/ytt/

???

:EN:- Understanding YAML and its gotchas
:FR:- Comprendre le YAML et ses subtilités
