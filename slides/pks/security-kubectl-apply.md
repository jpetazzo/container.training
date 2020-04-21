
# Security implications of `kubectl apply`

- When we do `kubectl apply -f <URL>`, we create arbitrary resources

- Resources can be evil; imagine a `deployment` that ...

--

  - starts bitcoin miners on the whole cluster

--

  - hides in a non-default namespace

--

  - bind-mounts our nodes' filesystem

--

  - inserts SSH keys in the root account (on the node)

--

  - encrypts our data and ransoms it

--

  - ☠️☠️☠️

---

## `kubectl apply` is the new `curl | sh`

- `curl | sh` is convenient

- It's safe if you use HTTPS URLs from trusted sources

--

- `kubectl apply -f` is convenient

- It's safe if you use HTTPS URLs from trusted sources

- Example: the official setup instructions for most pod networks

--

- It introduces new failure modes

  (for instance, if you try to apply YAML from a link that's no longer valid)
