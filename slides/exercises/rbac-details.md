# Exercise — RBAC

We want to:

- Create two namespaces for users `alice` and `bob`

- Give each user full access to their own namespace

- Give each user read-only access to the other's namespace

- Let `alice` view the nodes of the cluster as well

---

## Initial setup

- Create two namespaces named `alice` and `bob`

- Check that if we impersonate Alice, we can't access her namespace yet:
  ```bash
  kubectl --as alice get pods --namespace alice
  ```

---

## Access for Alice

- Grant Alice full access to her own namespace

  (you can use a pre-existing Cluster Role)

- Check that Alice can create stuff in her namespace:
  ```bash
  kubectl --as alice create deployment hello --image nginx --namespace alice
  ```

- But that she can't create stuff in Bob's namespace:
  ```bash
  kubectl --as alice create deployment hello --image nginx --namespace bob
  ```

---

## Access for Bob

- Similarly, grant Bob full access to his own namespace

- Check that Bob can create stuff in his namespace:
  ```bash
  kubectl --as bob create deployment hello --image nginx --namespace bob
  ```

- But that he can't create stuff in Alice's namespace:
  ```bash
  kubectl --as bob create deployment hello --image nginx --namespace alice
  ```

---

## Read-only access

- Now, give Alice read-only access to Bob's namespace

- Check that Alice can view Bob's stuff:
  ```bash
  kubectl --as alice get pods --namespace bob
  ```

- But that she can't touch this:
  ```bash
  kubectl --as alice delete pods --namespace bob --all
  ```

- Likewise, give Bob read-only access to Alice's namespace

---

## Nodes

- Give Alice read-only access to the cluster nodes

  (this will require creating a custom Cluster Role)

- Check that Alice can view the nodes:
  ```bash
  kubectl --as alice get nodes
  ```

- But that Bob cannot:
  ```bash
  kubectl --as bob get nodes
  ```

- And that Alice can't update nodes:
  ```bash
  kubectl --as alice label nodes --all hello=world
  ```
