## A reminder about *scope*

- Out of the box, Docker API access is "all or nothing"

- When someone has access to the Docker API, they can access *everything*

- If your developers are using the Docker API to deploy on the dev cluster ...

  ... and the dev cluster is the same as the prod cluster ...

  ... it means that your devs have access to your production data, passwords, etc.

- This can easily be avoided

---

## Fine-grained API access control

A few solutions, by increasing order of flexibility:

- Use separate clusters for different security perimeters

  (And different credentials for each cluster)

--

- Add an extra layer of abstraction (sudo scripts, hooks, or full-blown PAAS)

--

- Enable [authorization plugins]

  - each API request is vetted by your plugin(s)

  - by default, the *subject name* in the client TLS certificate is used as user name

  - example: [user and permission management] in [UCP]

[authorization plugins]: https://docs.docker.com/engine/extend/plugins_authorization/
[UCP]: https://docs.docker.com/datacenter/ucp/2.1/guides/
[user and permission management]: https://docs.docker.com/datacenter/ucp/2.1/guides/admin/manage-users/
