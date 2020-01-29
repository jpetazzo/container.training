# Security and kubernetes

There are many mechanisms in kubernetes to ensure the security.
Obviously the more you constrain your app, the better.

There is also mechanism to forbid "unsafe" application to be launched on
kubernetes, but that's more for ops-guys 😈 (more on that next days)

Let's focus on what can we do on the developer latop, to make app
compatible with secure system, enforced or not (it's always a good practice)

---
## No container in privileged mode

- risks:
   - If one privileged container get compromised,
     we basically get full access to the node from within a container
     (not need to tamper auth logs, alter binary).

   - Sniffing networks allow often to get access to the entire cluster.

- how to avoid:
   ```
   [...]
   spec:
     containers:
       - name: foo
         securityContext:
           privileged: false
   ```

   Luckily that's the default !

---
## No container run as "root"

- risks:
   - bind mounting a directory like /usr/bin allow to change node system core
     </br>ex: copy a tampered version of "ping", wait for an admin to login
     and to issue a ping command and bingo !

- how to avoid:

   ```
   [...]
   spec:
     containers:
       - name: foo
         securityContext:
           runAsUser: 1000
           runAsGroup: 100
   ```
   - The default is to use the image default

   - If your writing your own Dockerfile, don't forget about the `USER` instruction
---
## Capabilities

- You can give capabilities one-by-one to a container

- It's useful if you need more capabilities (for some reason), but not grating 'root' privileged

- risks: no risks whatsoever, except by granting a big list of capabilities

- how to use:
   ```
   [...]
   spec:
     containers:
       - name: foo
         securityContext:
           capabilities:
             add: ["NET_ADMIN", "SYS_TIME"]
             drop: []
   ```
   The default use the container runtime defaults

- and we can also drop default capabilities granted by the container runtime !
