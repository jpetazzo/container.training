# API server internals

- Understanding the internals of the API server is useful.red[¹]:

  - when extending the Kubernetes API server (CRDs, webhooks...)

  - when running Kubernetes at scale

- Let's dive into a bit of code!

.footnote[.red[¹]And by *useful*, we mean *strongly recommended or else...*]

---

## The main handler

- The API server parses its configuration, and builds a `GenericAPIServer`

- ... which contains an `APIServerHandler` ([src](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/server/handler.go#L37
))

- ... which contains a couple of `http.Handler` fields

- Requests go through:

  - `FullhandlerChain` (a series of HTTP filters, see next slide)

  - `Director` (switches the request to `GoRestfulContainer` or `NonGoRestfulMux`)

- `GoRestfulContainer`  is for "normal" APIs; integrates nicely with OpenAPI

- `NonGoRestfulMux` is for everything else (e.g. proxy, delegation)

---

## The chain of handlers

- API requests go through a complex chain of filters ([src](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/server/config.go#L671))

  (note when reading that code: requests start at the bottom and go up)

- This is where authentication, authorization, and admission happen

  (as well as a few other things!)

- Let's review an arbitrary selection of some of these handlers!

*In the following slides, the handlers are in chronological order.*

*Note: handlers are nested; so they can act at the beginning and end of a request.*

---

## `WithPanicRecovery`

- Reminder about Go: there is no exception handling in Go; instead:

  - functions typically return a composite `(SomeType, error)` type

  - when things go really bad, the code can call `panic()`

  - `panic()` can be caught with `recover()`
    <br/>
    (but this is almost never used like an exception handler!)

- The API server code is not supposed to `panic()`

- But just in case, we have that handler to prevent (some) crashes

---

## `WithRequestInfo` ([src](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/endpoints/request/requestinfo.go#L163))


- Parse out essential information:

  API group, version, namespace, resource, subresource, verb ...

- WithRequestInfo: parse out API group+version, Namespace, resource, subresource ...

- Maps HTTP verbs (GET, PUT, ...) to Kubernetes verbs (list, get, watch, ...)

---

class: extra-details

## HTTP verb mapping

- POST → create

- PUT → update

- PATCH → patch

- DELETE
  <br/> → delete (if a resource name is specified)
  <br/> → deletecollection (otherwise)

- GET, HEAD
  <br/> → get (if a resource name is specified)
  <br/> → list (otherwise)
  <br/> → watch (if the `?watch=true` option is specified)

---

## `WithWaitGroup`

- When we shutdown, tells clients (with in-flight requests) to retry

  - only for "short" requests

  - for long running requests, the client needs to do more

- Long running requests include `watch` verb, `proxy` sub-resource

(See also `WithTimeoutForNonLongRunningRequests`)

---

## AuthN and AuthZ

- `WithAuthentication`:
  the request goes through a *chain* of authenticators
  ([src](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/endpoints/filters/authentication.go#L38))

- WithAudit

- WithImpersonation: used for e.g. `kubectl ... --as another.user`

- WithPriorityAndFairness or WithMaxInFlightLimit

  (`system:masters` can bypass these)

- WithAuthorization

---

## After all these handlers ...

- We get to the "director" mentioned above

- Api Groups get installed into the "gorestfulhandler"
  ([src](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/server/genericapiserver.go#L423))

- REST-ish resources are managed by various handlers
  (in [this directory](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/endpoints/handlers/))

- These files show us the code path for each type of request

---

class: extra-details

## Request code path

- [create.go](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/endpoints/handlers/create.go):
  decode to HubGroupVersion; admission; mutating admission; store

- [delete.go](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/endpoints/handlers/delete.go):
  validating admission only; deletion

- [get.go](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/endpoints/handlers/get.go) (get, list):
  directly fetch from rest storage abstraction

- [patch.go](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/endpoints/handlers/patch.go):
  admission; mutating admission; patch

- [update.go](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/endpoints/handlers/update.go):
  decode to HubGroupVersion; admission; mutating admission; store

- [watch.go](https://github.com/kubernetes/apiserver/blob/release-1.19/pkg/endpoints/handlers/watch.go):
  similar to get.go, but with watch logic

(HubGroupVersion = in-memory, "canonical" version.)

???

:EN:- Kubernetes API server internals
:FR:- Fonctionnement interne du serveur API
