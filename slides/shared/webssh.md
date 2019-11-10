## WebSSH

- The virtual machines are also accessible via WebSSH

- This can be useful if:

  - you can't install an SSH client on your machine

  - SSH connections are blocked (by firewall or local policy)

- To use WebSSH, connect to the IP address of the remote VM on port 1080

  (each machine runs a WebSSH server)

- Then provide the login and password indicated on your card

---

## Good to know

- WebSSH uses WebSocket

- If you're having connections issues, try to disable your HTTP proxy

  (many HTTP proxies can't handle WebSocket properly)

- Most keyboard shortcuts should work, except Ctrl-W

  (as it is hardwired by the browser to "close this tab")
