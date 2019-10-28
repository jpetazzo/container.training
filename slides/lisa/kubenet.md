class: title

Adding more nodes

---

## What do we need to do?

- More machines!

- Can we "just" start kubelet on these machines?

--

- We need to update the kubeconfig file used by kubelet

- It currently uses `localhost:8080` for the API server

- We need to change that!

---

## What we will do

- Get more nodes

- Generate a new kubeconfig file

  (pointing to the node running the API server)

- Start more kubelets

- Scale up our deployment

---

class: pic

![Demo time!](images/demo-with-kht.png)
