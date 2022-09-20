

# External References && kubectl Aliases

Class Slides:    https://2022-09-nr1.container.training/
    
Kubectl Cheat Sheet:    https://kubernetes.io/docs/reference/kubectl/cheatsheet/

Kubernetes API Object and kubectl Explorers

-   https://github.com/GerrySeidman/Kubernetes-Explorer

Gerry Kubernetes Storage Converence Talks

-   Vault '20:     https://www.usenix.org/conference/vault20/presentation/seidman
- Data and Dev '21:  https://www.youtube.com/watch?v=k_8rWPwJ_38

Gerry Seidman’s Info

- gerry.seidman@ardanlabs.com
- https://www.linkedin.com/in/gerryseidman/


---

## Kubectl Aliases

```bash
alias k='kubectl'
alias kg='kubectl get'
alias kl='kubectl logs'
alias ka='kubectl apply -f'
alias kd='kubectl delete'
alias kdf='kubectl delete -f'
alias kb='kubectl describe'
alias kex='kubectl explain'
alias ke='kubectl edit'
# alias kx='kubectl exec -it $1 -- /bin/sh'
```
Note the below is only because of a quirk in how the lab VMs were installed:
```bash
echo 'kubectl exec -it $1 -- /bin/sh'  >kx
chmod +x kx
sudo mv kx /usr/local/bin/kx
```
