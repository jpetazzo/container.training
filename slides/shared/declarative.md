# Declarative vs imperative

- Our container orchestrator puts a very strong emphasis on being *declarative*

- Declarative:

  *I would like a cup of tea.*

- Imperative:

  *Boil some water. Pour it in a teapot. Add tea leaves. Steep for a while. Serve in a cup.*

--

- Declarative seems simpler at first ... 

--

- ... As long as you know how to brew tea

---

## Declarative vs imperative

- What declarative would really be:

  *I want a cup of tea, obtained by pouring an infusion¹ of tea leaves in a cup.*

--

  *¹An infusion is obtained by letting the object steep a few minutes in hot² water.*

--

  *²Hot liquid is obtained by pouring it in an appropriate container³ and setting it on a stove.*

--

  *³Ah, finally, containers! Something we know about. Let's get to work, shall we?*

--

.footnote[Did you know there was an [ISO standard](https://en.wikipedia.org/wiki/ISO_3103)
specifying how to brew tea?]

---

## Declarative vs imperative

- Imperative systems:

  - simpler

  - if a task is interrupted, we have to restart from scratch

- Declarative systems:

  - if a task is interrupted (or if we show up to the party half-way through),
    we can figure out what's missing and do only what's necessary

  - we need to be able to *observe* the system

  - ... and compute a "diff" between *what we have* and *what we want*
