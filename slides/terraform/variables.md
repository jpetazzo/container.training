## Variables

- At this point, we are probably:

  - duplicating a lot of information (e.g. zone, number of nodes...)

  - hard-coding a lot of things as well (ditto!)

- Let's see how we can do better!

---

## [Input variables](https://www.terraform.io/language/values/variables)

Declaring an input variable:
```tf
variable "location" {
  type    = string
  default = "europe-north1-a"
}
```

Using an input variable:
```tf
resource "google_container_cluster" "mycluster" {
  location = var.location
  ...
}
```

---

## Setting variables

Input variables can be set with:

- environment variables (`export TFVAR_location=us-west1`)

- a file named `terraform.tfvars` (`location = "us-west1"`)

- a file named `terraform.tfvars.json`

- files named `*.auto.tfvars` and `*.auto.tfvars.json`

- command-line literal values (`-var location=us-west1`)

- command-line file names (`-var-file carbon-neutral.tfvars`)

The latter taking precedence over the former.

---

## [Local values](https://www.terraform.io/language/values/locals)

Declaring and setting a local value:
```tf
locals {
  location = var.location != null ? var.location : "europe-north1-a"
  region   = replace(local.location, "/-[a-z]$/", "")
}
```

We can have multiple `locals` blocks.

Using a local value:
```tf
resource "google_container_cluster" "mycluster" {
  location = local.location
  ...
}
```
