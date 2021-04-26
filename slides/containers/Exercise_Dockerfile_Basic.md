# Exercise — writing Dockerfiles

Let's write Dockerfiles for an existing application!

1. Check out the code repository

2. Read all the instructions

3. Write Dockerfiles

4. Build and test them individually

<!--
5. Test them together with the provided Compose file
-->

---

## Code repository

Clone the repository available at:

https://github.com/jpetazzo/wordsmith

It should look like this:
```
├── LICENSE
├── README
├── db/
│   └── words.sql
├── web/
│   ├── dispatcher.go
│   └── static/
└── words/
    ├── pom.xml
    └── src/
```

---

## Instructions

The repository contains instructions in English and French.
<br/>
For now, we only care about the first part (about writing Dockerfiles).
<br/>
Place each Dockerfile in its own directory, like this:
```
├── LICENSE
├── README
├── db/
│   ├── `Dockerfile`
│   └── words.sql
├── web/
│   ├── `Dockerfile`
│   ├── dispatcher.go
│   └── static/
└── words/
    ├── `Dockerfile`
    ├── pom.xml
    └── src/
```

---

## Build and test

Build and run each Dockerfile individually.

For `db`, we should be able to see some messages confirming that the data set
was loaded successfully (some `INSERT` lines in the container output).

For `web` and `words`, we should be able to see some message looking like
"server started successfully".

That's all we care about for now!

Bonus question: make sure that each container stops correctly when hitting Ctrl-C.

???

## Test with a Compose file

Place the following Compose file at the root of the repository:


```yaml
version: "3"
services:
  db:
    build: db
  words:
    build: words
  web:
    build: web
    ports:
    - 8888:80
```

Test the whole app by bringin up the stack and connecting to port 8888.
