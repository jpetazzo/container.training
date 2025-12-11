## Connecting to our lab environment

- We need an SSH client

- On Linux, OS X, FreeBSD... you are probably all set; just use `ssh`

- On Windows, get one of these:

  - [putty](https://putty.software/)
  - Microsoft [Win32 OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH)
  - [Git BASH](https://git-for-windows.github.io/)
  - [MobaXterm](http://mobaxterm.mobatek.net/)

- On Android, [JuiceSSH](https://juicessh.com/)
  ([Play Store](https://play.google.com/store/apps/details?id=com.sonelli.juicessh))
  works pretty well

---

## Testing the connection

- Your instructor will tell you where to find the IP address, login, and password

.lab[

- Connect to your lab environment with your SSH client:
  ```bash
  ssh `user`@`A.B.C.D`
  ssh -p `32323` `user`@`A.B.C.D`
  ```

  (Make sure to replace the highlighted values with the ones provided to you!)

<!--
```bash
for N in $(awk '/\Wnode/{print $2}' /etc/hosts); do
  ssh -o StrictHostKeyChecking=no $N true
done
```

```bash
### FIXME find a way to reset the cluster, maybe?
```
-->

]

You should see a prompt looking like this:
```
[A.B.C.D] (...) user@machine ~
$
```

---

## Checking the lab environment

In Docker classes, run `docker version`.

The output should look like this:

.small[
```bash
Client:
 Version:           29.1.1
 API version:       1.52
 Go version:        go1.25.4 X:nodwarf5
 Git commit:        0aedba58c2
 Built:             Fri Nov 28 14:28:26 2025
 OS/Arch:           linux/amd64
 Context:           default

Server:
 Engine:
  Version:          29.1.1
  API version:      1.52 (minimum version 1.44)
  Go version:       go1.25.4 X:nodwarf5
  Git commit:       9a84135d52
  Built:            Fri Nov 28 14:28:26 2025
  OS/Arch:          linux/amd64
  Experimental:     false
  ...
```
]

---

## Checking the lab environment

In Kubernetes classes, run `kubectl get nodes`.

The output should look like this:

```bash
$ k get nodes
NAME    STATUS   ROLES           AGE    VERSION
node1   Ready    control-plane   7d6h   v1.34.0
node2   Ready    <none>          7d6h   v1.34.0
node3   Ready    <none>          7d6h   v1.34.0
node4   Ready    <none>          7d6h   v1.34.0
```

---

## If it doesn't work...

Ask an instructor or assistant to help you!

---

## `tailhist`

- The shell history of the instructor is available online in real time

- The instructor will share a special URL with you

  (typically, the instructor's lab address on port 1088 or 30088)

- Open that URL in your browser and you should see the history

- The history is updated in real time

  (using a WebSocket connection)

- It should be green when the WebSocket is connected

  (if it turns red, reloading the page should fix it)

---

## Terminals

Once in a while, the instructions will say:
<br/>"Open a new terminal."

There are multiple ways to do this:

- create a new window or tab on your machine, and SSH into the VM;

- use screen or tmux on the VM and open a new window from there.

You are welcome to use the method that you feel the most comfortable with.

---

## Tmux cheat sheet (basic)

[Tmux](https://en.wikipedia.org/wiki/Tmux) is a terminal multiplexer like `screen`.

*You don't have to use it or even know about it to follow along.
<br/>
But some of us like to use it to switch between terminals.
<br/>
It has been preinstalled on your workshop nodes.*

- You can start a new session with `tmux`
  <br/>
  (or resume or share an existing session with `tmux attach`)

- Then use these keyboard shortcuts:

  - Ctrl-b c → creates a new window
  - Ctrl-b n → go to next window
  - Ctrl-b p → go to previous window
  - Ctrl-b " → split window top/bottom
  - Ctrl-b % → split window left/right
  - Ctrl-b arrows → navigate within split windows

---

## Tmux cheat sheet (advanced)

- Ctrl-b d → detach session
  <br/>
  (resume it later with `tmux attach`)

- Ctrl-b Alt-1 → rearrange windows in columns

- Ctrl-b Alt-2 → rearrange windows in rows

- Ctrl-b , → rename window

- Ctrl-b Ctrl-o → cycle pane position (e.g. switch top/bottom)

- Ctrl-b PageUp → enter scrollback mode
  <br/>
  (use PageUp/PageDown to scroll; Ctrl-c or Enter to exit scrollback)
