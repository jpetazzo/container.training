## State

- Terraform keeps track of the *state*

- Resources created by Terraform are added to the state

- When we run Terraform, it will:

  - *refresh* the state (check if resources have changed since last time it ran)

  - generate a *plan* (decide which actions need to be taken)

  - ask confirmation (this can be skipped)

  - *apply* that plan

---

## Remote state

- By default, the state is stored in `terraform.tfstate`

- This is a JSON file (feel free to inspect it!)

- The state can also be stored in a central place

  (e.g. cloud object store, Consul, etcd...)

- This is more convenient when working as a team

- It also requires *locking*

  (to prevent concurrent modifications)

---

## Working with remote state

- This is beyond the scope of this workshop

- Note that if a Terraform configuration defines e.g. an S3 bucket to store its state...

  ...that configuration cannot create that S3 bucket!

- The bucket must be created beforehand

  (Terraform won't be able to run until the bucket is available)

---

## Manipulating state

`terraform state list`

`terraform state show google_container_cluster.mycluster`

`terraform state rm`

`terraform import`
