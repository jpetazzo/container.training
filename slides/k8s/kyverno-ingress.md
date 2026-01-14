## Detecting duplicate Ingress routes

- What happens when two Ingress resources have the same host+path?

--

- Undefined behavior!

--

- Possibilities:

  - one of the Ingress rules is ignored (newer, older, lexicographic, random...)

  - both Ingress rules are ignored

  - traffic is randomly processed by both rules (sort of load balancing)

  - creation of the second resource is blocked by an admission policy

--

- Can we implement that last option with Kyverno? 🤔

---

## General idea

- When a new Ingress resource is created:

  *check if there is already an identical Ingress resource*

- We'll want to use the `apiCall` feature

  (to retrieve all existing Ingress resources across all Namespaces)

- Problem: we don't care about strict equality

  (there could be different labels, annotations, TLS configuration)

- Problem: an Ingress resource is a collection of *rules*

  (we want to check if any rule of the new Ingress...
  <br/>...conflicts with any rule of an existing Ingress)

---

## Good news, everyone

- There is an example in the Kyverno documentation!

  [Unique Ingress Host and Path][kyverno-unique-ingress]

--

- Unfortunately, the example doesn't really work

  (at least as of [Kyverno 1.16 / January 2026][kyverno-unique-ingress-github])

- Can you see problems with it?

--

- Suggestion: load the policy and make some experiments!

  (remember to switch the `validationFailureAction` to `Enforce` for easier testing)

[kyverno-unique-ingress]: https://kyverno.io/policies/other/unique-ingress-host-and-path/unique-ingress-host-and-path/
[kyverno-unique-ingress-github]: https://github.com/kyverno/policies/blob/release-1.16/other/unique-ingress-host-and-path/unique-ingress-host-and-path.yaml

---

## Problem - no `host`

- If we try to create an Ingress without specifying the `host`:
  ```
  JMESPath query failed: Unknown key "host" in path
  ```

- In some cases, this could be a feature

  (maybe we don't want to allow Ingress rules without a `host`!)

---

## Problem - no UPDATE

- If we try to modify an existing Ingress, the modification will be blocked

- This is because the "new" Ingress rules are checked against "existing" rules

- When we CREATE a new Ingress, its rules don't exist yet (no conflict)

- When we UPDATE an existing Ingress, its rules will show up in the existing rules

- By definition, a rule will always conflict with itself

- So UPDATE requests will always be blocked

- If we exclude UPDATE operations, then it will be possible to introduce conflicts

  (by modifying existing Ingress resources to add/edit rules in them)

- This problem makes the policy useless as it is (unless we completely block updates)

---

## Problem - poor UX

- When the policy detects a conflict, it doesn't say which other resource is involved

- Sometimes, it's possible to find it manually

  (with a bunch of clever `kubectl get ingresses --all-namespaces` commands)

- Sometimes, we don't have read permissions on the conflicting resource

  (e.g. if it's in a different Namespace that we cannot access)

- It would be nice if the policy could report the exact Ingress and Namespace involved

---

## Problem - useless block

- There is a `preconditions` block to ignore `DELETE` operations

- This is useless, as the default is to match only `CREATE` and `UPDATE` requests

  (See the [documentation about match statements][kyverno-match])

- This block can be safely removed

[kyverno-patch]: https://kyverno.io/docs/policy-types/cluster-policy/match-exclude/#match-statements

---

## Solution - no `host`

- In Kyverno, when doing a lookup, the way to handle non-existent keys is with a `||`

- For instance, replace `{{element.host}}` with `{{element.host||''}}`

  (or a placeholder value like `{{element.host||'NOHOST'}}`)

---

## Solution - no UPDATE

- When retrieving existing Ingress resources, we need to exclude the current one

- This can look like this:
  ```yaml
    context:
    - name: ingresses
      apiCall:
        urlPath: "/apis/networking.k8s.io/v1/ingresses"
        jmesPath: |
          items[?
            metadata.namespace!='{{request.object.metadata.namespace}}'
            ||
            metadata.name!='{{request.object.metadata.name}}'
          ]  
  ```

---

## Solution - poor UX

- Ideally, when there is a conflict, we'd like to display a message like this one:
  ```
  Ingress host+path combinations must be unique across the cluster.
  This Ingress contains a rule for host 'www.example.com' and path '/',
  which conflicts with Ingress 'example' in Namespace 'default'.  
  ```

- This requires a significant refactor of the policy logic

- Instead of:

  *loop on rules; filter by rule's host; find if there is any common path*

- We need e.g.:

  *loop on rules; nested loop on paths; filter ingresses with conflicts*

- This requires nested loops, and way to access the `element` of each nested loop

---

## Nested loops

- As of January 2026, this isn't very well documented

  (author's note: I had to [dive into Kyverno's code][kyverno-nested-element] to figure it out...)

- The trick is that the outer loop's element is `element0`, the next one is `element1`, etc.

- Additionally, there is a bug in Kyverno's context handling when defining a variable in a loop

  (the variable needs to be defined at the top-level, with e.g. a dummy value)

TODO: propose a PR to Kyverno's documentation! 🤓💡

[kyverno-nested-element]: https://github.com/kyverno/kyverno/blob/5d5345ec3347f4f5c281652461d42231ea3703e5/pkg/engine/context/context.go#L284

---

## Putting it all together

- Try to write a Kyverno policy to detect conflicting Ingress resources

- Make sure to test the following edge cases:

  - rules that don't define a host (e.g. `kubectl create ingress test --rule=/=test:80`)

  - ingresses with multiple rules

  - no-op edits (e.g. adding a label or annotation)

  - conflicting edits (e.g. adding/editing a rule that adds a conflict)

  - rules for `host1/path1` and `host2/path2` shouldn't conflict with `host1/path2`
