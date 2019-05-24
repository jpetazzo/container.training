## Differences with wek8s

- We have `cluster-admin` (=`root`) privileges on our clusters

  (we can read/write everything)

- This is typical when working on "personal" clusters

  (used by a single person, or a very small team)

- But *not* when working on production clusters

- On wek8s clusters, we can't access most *global* resources

  (resources that don't belong to namespaces; e.g. nodes)
