## Encryption at rest

- Swarm data is always encrypted

- A Swarm cluster can be "locked"

- When a cluster is "locked", the encryption key is protected with a passphrase

- Starting or restarting a locked manager requires the passphrase

- This protects against:

  - theft (stealing a physical machine, a disk, a backup tape...)

  - unauthorized access (to e.g. a remote or virtual volume)

  - some vulnerabilities (like path traversal)

---

## Locking a Swarm cluster

- This is achieved through the `docker swarm update` command

.lab[

- Lock our cluster:
  ```bash
  docker swarm update --autolock=true
  ```

]

This will display the unlock key. Copy-paste it somewhere safe.

---

## Locked state

- If we restart a manager, it will now be locked

.lab[

- Restart the local Engine:
  ```bash
  sudo systemctl restart docker
  ```

]

Note: if you are doing the workshop on your own, using nodes
that you [provisioned yourself](https://@@GITREPO@@/tree/master/prepare-machine) or with [Play-With-Docker](https://play-with-docker.com/), you might have to use a different method to restart the Engine.

---

## Checking that our node is locked

- Manager commands (requiring access to crypted data) will fail

- Other commands are OK

.lab[

- Try a few basic commands:
  ```bash
  docker ps
  docker run alpine echo ♥
  docker node ls
  ```

<!-- ```wait Swarm is encrypted``` -->

]

(The last command should fail, and it will tell you how to unlock this node.)

---

## Checking node state in scripts

- The state of the node shows up in the output of `docker info`

.lab[

- Check the output of `docker info`:
  ```bash
  docker info
  ```

- Can't see it? Too verbose? Grep to the rescue!
  ```bash
  docker info | grep ^Swarm
  ```

]

---

## Unlocking a node

- You will need the secret token that we obtained when enabling auto-lock earlier

.lab[

- Unlock the node:
  ```bash
  docker swarm unlock
  ```

- Copy-paste the secret token that we got earlier

- Check that manager commands now work correctly:
  ```bash
  docker node ls
  ```

]

---

## Managing the secret key

- If the key is compromised, you can change it and re-encrypt with a new key:
  ```bash
  docker swarm unlock-key --rotate
  ```

- If you lost the key, you can get it as long as you have at least one unlocked node:
  ```bash
  docker swarm unlock-key -q
  ```

Note: if you rotate the key while some nodes are locked, without saving the previous key, those nodes won't be able to rejoin.

Note: if somebody steals both your disks and your key, .strike[you're doomed! Doooooomed!]
<br/>you can block the compromised node with `docker node demote` and `docker node rm`.

---

## Unlocking the cluster permanently

- If you want to remove the secret key, disable auto-lock

.lab[

- Permanently unlock the cluster:
  ```bash
  docker swarm update --autolock=false
  ```

]

Note: if some nodes are in locked state at that moment (or if they are offline/restarting
while you disabled autolock), they still need the previous unlock key to get back online.

For more information about locking, you can check the [upcoming documentation](https://github.com/docker/docker.github.io/pull/694).
