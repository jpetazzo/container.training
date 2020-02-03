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

# Alternative: sops / git crypt

- You can work a VCS level (ie totally abstracted from kubernetess)

- sops (https://github.com/mozilla/sops), VCS agnostic, encrypt portion of files

- git-crypt that work with git to transparently encrypt (some) files in git
