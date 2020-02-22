# Exercise — ConfigMaps

- In this exercise, we will use a ConfigMap to store static assets

- While there are some circumstances where this can be useful ...

- ... It is generally **not** a good idea!

- Once you've read that warning, check the next slide for instructions :)

---

## Exercise — ConfigMaps

This will use the wordsmith app.

We want to store the static files (served by `web`) in a ConfigMap.

1. Transform the `static` directory into a ConfigMap.

   (https://github.com/jpetazzo/wordsmith/tree/master/web/static)

2. Find out where that `static` directory is located in `web`.

   (for instance, by using `kubectl exec` to investigate)

3. Update the definition of the `web` Deployment to use the ConfigMap.

   (note: fonts and images will be broken; that's OK)

4. Make a minor change in the ConfigMap (e.g. change the text color)
