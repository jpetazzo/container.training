# Executing batch jobs

- Deployments are great for stateless web apps

  (as well as workers that keep running forever)

- Pods are great for one-off execution that we don't care about

  (because they don't get automatically restarted if something goes wrong)

- Jobs are great for "long" background work

  ("long" being at least minutes or hours)

- CronJobs are great to schedule Jobs at regular intervals

  (just like the classic UNIX `cron` daemon with its `crontab` files)

---

## Creating a Job

- A Job will create a Pod

- If the Pod fails, the Job will create another one

- The Job will keep trying until:

  - either a Pod succeeds,

  - or we hit the *backoff limit* of the Job (default=6)

.lab[

- Create a Job that has a 50% chance of success:
  ```bash
    kubectl create job flipcoin --image=alpine -- sh -c 'exit $(($RANDOM%2))' 
  ```

]

---

## Our Job in action

- Our Job will create a Pod named `flipcoin-xxxxx`

- If the Pod succeeds, the Job stops

- If the Pod fails, the Job creates another Pod

.lab[

- Check the status of the Pod(s) created by the Job:
  ```bash
  kubectl get pods --selector=job-name=flipcoin
  ```

]

---

class: extra-details

## More advanced jobs

- We can specify a number of "completions" (default=1)

- This indicates how many times the Job must be executed

- We can specify the "parallelism" (default=1)

- This indicates how many Pods should be running in parallel

- These options cannot be specified with `kubectl create job`

  (we have to write our own YAML manifest to use them)

---

## Scheduling periodic background work

- A Cron Job is a Job that will be executed at specific intervals

  (the name comes from the traditional cronjobs executed by the UNIX crond)

- It requires a *schedule*, represented as five space-separated fields:

  - minute [0,59]
  - hour [0,23]
  - day of the month [1,31]
  - month of the year [1,12]
  - day of the week ([0,6] with 0=Sunday)

- `*` means "all valid values"; `/N` means "every N"

- Example: `*/3 * * * *` means "every three minutes"

- The website https://crontab.guru/ can help to create cron schedules!

---

## Creating a Cron Job

- Let's create a simple job to be executed every three minutes

- Careful: make sure that the job terminates!

  (The Cron Job will not hold if a previous job is still running)

.lab[

- Create the Cron Job:
  ```bash
    kubectl create cronjob every3mins --schedule="*/3 * * * *" \
            --image=alpine -- sleep 10
  ```

- Check the resource that was created:
  ```bash
  kubectl get cronjobs
  ```

]

---

## Cron Jobs in action

- At the specified schedule, the Cron Job will create a Job

- The Job will create a Pod

- The Job will make sure that the Pod completes

  (re-creating another one if it fails, for instance if its node fails)

.lab[

- Check the Jobs that are created:
  ```bash
  kubectl get jobs
  ```

]

(It will take a few minutes before the first job is scheduled.)

---

class: extra-details

## Setting a time limit

- It is possible to set a time limit (or deadline) for a job

- This is done with the field `spec.activeDeadlineSeconds`

  (by default, it is unlimited)

- When the job is older than this time limit, all its pods are terminated

- Note that there can also be a `spec.activeDeadlineSeconds` field in pods!

- They can be set independently, and have different effects:

  - the deadline of the job will stop the entire job

  - the deadline of the pod will only stop an individual pod

???

:EN:- Running batch and cron jobs
:FR:- Tâches périodiques *(cron)* et traitement par lots *(batch)*
