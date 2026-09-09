# k9s and sofka

- Somewhere in between CLI and GUI (or web UI), we can find the magic land of TUI

  - [Text-based user interfaces](https://en.wikipedia.org/wiki/Text-based_user_interface)

  - often using libraries like [curses](https://en.wikipedia.org/wiki/Curses_%28programming_library%29) and its successors

- Some folks love them, some folks hate them, some are indifferent ...

- But it's nice to have different options!

- Let's see a couple of  TUI for Kubernetes: [k9s] and [sofka]

[k9s]: https://k9scli.io/
[sofka]: https://sofka.rs/

---

## Why two tools?

- `k9s` came first (first commit in early 2019)

- Written in Go

- Lots of plugins, documentation, tutorials, etc

- `sofka` came later (first commit mid-2026)

- Written in Rust

- Lower RAM and CPU usage ("feels" faster)

---

## Installing them

- If you are using a training cluster or the [shpod] image, both are pre-installed

- Otherwise, they can be installed easily:

  - with various package managers ([k9s][k9spkg], [sofka][sofkapkg])

  - or by fetching a binary release ([k9s][k9sbin], [sofka][sofkabin])

- We don't need to set up or configure anything

  (it will use the same configuration as `kubectl` and other well-behaved clients)

- Just run `k9s` to fire it up!

[shpod]: https://github.com/jpetazzo/shpod
[k9spkg]: https://k9scli.io/topics/install/
[k9sbin]: https://github.com/derailed/k9s/releases
[sofkapkg]: https://sofka.rs/#install
[sofkabin]: https://github.com/nklmilojevic/sofka/releases

---

## What kind to we want to see?

- They both use `:` to change the type of resource to view

- Hit `:` then type, for instance, `ns` or `namespace`, then `[ENTER]`

  (note: they behave differently if you type a partial resource name)

- Use the arrows to move down to e.g. `kube-system`, and press `[ENTER]`

- Or, type `/kub` or `/sys` to filter the output, and press `[ENTER]` twice

  (once to exit the filter, once to enter the namespace)

- We now see the pods in `kube-system`!

---

## Interacting with pods

- Basic commands are the same between both tools

  (sofka adopted the same keyboard shortcuts here as well)

- `l` to view logs

- `d` to describe

- `s` to get a shell (won't work if `sh` isn't available in the container image)

- `e` to edit

- `shift-f` to define port forwarding

- `ctrl-k` to kill

- `[ESC]` to get out or get back

---

## Quick navigation between namespaces

- In both tools: hit `0` to see all namespaces

- In k9s, at the top of the screen, there are shortcuts to namespaces:

  ```
  <0> all
  <1> kube-system
  <2> default
  ```

- In sofka, hit `n` to display the namespace selector

---

## Interacting with Deployments

- View Deployments (type `:` `deploy` `[ENTER]`)

- Select e.g. `worker`

- Scale it with `s`

- View its aggregated logs with `l`

---

## Exit

- Exit at any time with `Ctrl-C`

- k9s will "remember" where you were

  (and go back there next time you run it)

---

## Pros

- Very convenient to navigate through resources

  (hopping from a deployment, to its pod, to another namespace, etc.)

- Very convenient to quickly view logs of e.g. init containers

- Very convenient to get a (quasi) realtime view of resources

  (if we use `watch kubectl get` a lot, we will probably like k9s and/or sofka)

- Some plugins can be extremely useful

  (e.g. to manage CNPG databases)

---

## Cons

- Doesn't promote automation / scripting

  (if you repeat the same things over and over, there is a scripting opportunity)

- Not all features are available

  (e.g. executing arbitrary commands in containers)

---

## Conclusion

Try them out, and see if it makes you more productive!

???

:EN:- The k9s and sofka TUI
:FR:- Les TUI k9s et sofka
