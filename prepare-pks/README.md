# Instructions for preparing a PKS Kubernetes Cluster

## pre-reqs

* ingress controller (nginx or nsxt)
* gangway (or similar for kubeconfig files)

## Create users

This example will create 50 random users in UAAC and corresponding Kubernetes users and rbac.

```bash
$ cd users
$ ./random-users.sh 50
...
...
$ ./create.sh
...
...
```

This will install helm tiller for each:

```bash
$ ./helm.sh
...
...
```

This will clean up:

```bash
$ ./delete.sh
...
...
```
