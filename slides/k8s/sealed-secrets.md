# sealed-secrets

- https://github.com/bitnami-labs/sealed-secrets

- has a server side (standard kubernetes deployment) and a client side *kubeseal* binary

- server-side start by generating a key pair, keep the private, expose the public.

- To create a sealed-secret, you only need access to public key

- You can enforce access with RBAC rules of kubernetes

---

## sealed-secrets how to

- adding a secret: *kubeseal* will cipher it with the public key

- server side controller will re-create original secret, when the ciphered one are added to the cluster

- it "safe" to add those secret to your source tree

- since version 0.9 key rotation are enable by default, so remember to backup private keys regularly.
  </br> (or you won't be able to decrypt all you keys, in a case of *disaster recovery*)


---

## First "sealed-secret"


.exercise[
- Install *kubeseal*
  ```bash
  wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.9.7/kubeseal-linux-amd64 -O kubeseal
  sudo install -m 755 kubeseal /usr/local/bin/kubeseal
  ```

- Install controller
  ```bash
  helm install -n kube-system stable/sealed-secrets sealed-secrets-controller
  ```

- Create a secret you don't want to leak
  ```bash
  kubectl create secret generic --from-literal=foo=bar my-secret -o yaml --dry-run \
    | kubeseal > mysecret.yaml
  kubectl apply -f mysecret.yaml
  ```
]

---

## Alternative: sops / git crypt

- You can work a VCS level (ie totally abstracted from kubernetess)

- sops (https://github.com/mozilla/sops), VCS agnostic, encrypt portion of files

- git-crypt that work with git to transparently encrypt (some) files in git

---

## Other alternative

- You can delegate secret management to another component like *hashicorp vault*

- Can work in multiple ways:

   - encrypt secret from API-server (instead of the much secure *base64*)
   - encrypt secret before sending it in kubernetes (avoid git in plain text)
   - manager secret entirely in vault and expose to the container via volume
