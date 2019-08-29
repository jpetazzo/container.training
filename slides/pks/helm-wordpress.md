## Why wordpress its 2019?!?!

I know ... funny right :)

---

## Helm install notes

- You'll notice a helpful message after running `helm install` that looks something like this:

```
NOTES:
1. Get the WordPress URL:

  echo "WordPress URL: http://127.0.0.1:8080/"
  echo "WordPress Admin URL: http://127.0.0.1:8080/admin"
  kubectl port-forward --namespace user1 svc/wp-wordpress 8080:80

2. Login with the following credentials to see your blog

  echo Username: user
  echo Password: $(kubectl get secret --namespace user1 wp-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)
```

--

Helm charts generally have a `NOTES.txt` template that is rendered out and displayed after helm commands are run.  Pretty neat.

---

## What did helm install ?

- Run `kubectl get all` to check what resources helm installed

.exercise[
  - Run `kubectl get all`:
  ```bash
  kubectl get all
  ```

]
---

## What did helm install ?

```
NAME                                 READY   STATUS      RESTARTS   AGE
pod/wp-mariadb-0                     1/1     Running     0          11m
pod/wp-wordpress-6cb9cfc94-chbr6     1/1     Running     0          11m

NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/wp-mariadb     ClusterIP   10.100.200.87    <none>        3306/TCP         11m
service/wp-wordpress   ClusterIP   10.100.200.131   <none>        80/TCP,443/TCP   11m

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/wp-wordpress    1/1     1            1           11m

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/tiller-deploy-6487f7bfd8   1         1         1       2d6h
replicaset.apps/tiller-deploy-75ccf68856   0         0         0       2d6h
replicaset.apps/wp-wordpress-6cb9cfc94     1         1         1       11m

NAME                          READY   AGE
statefulset.apps/wp-mariadb   1/1     11m

```

---

## Check if wordpress is working

- Using the notes provided from helm check you can access your wordpress and login as `user`

.exercise[
  - run the commands provided by the helm summary:
  ```bash
  echo Username: user
  echo Password: $(kubectl get secret --namespace user1 wp-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)

  kubectl port-forward --namespace user1 svc/wp-wordpress 8080:80
  ```
]

--

Yay? you have a 2003 era blog

---

## Helm Chart Values

Settings values on the command line is okay for a demonstration, but we should really be creating a `~/workshop/values.yaml` file for our chart. Let's do that now.

> the values file is a bit long to copy/paste from here, so lets wget it.

.exercise[
  - Download the values.yaml file and edit it, changing the URL prefix to be `<username>-wp`:
  ```bash
    wget -O ~/workshop/values.yaml \
      https://raw.githubusercontent.com/paulczar/container.training/pks/slides/pks/wp/values.yaml

    vim ~/workshop/values.yaml

    helm upgrade wp stable/wordpress -f ~/workshop/values.yaml

  ```
]

---