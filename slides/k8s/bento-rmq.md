# Bento & RabbitMQ

- In some of the previous runs, messages were dropped

  (we start with 1000 messages in `cities` and have e.g. 955 in `mayors`)

- This is caused by various errors during processing

  (e.g. too many timeouts; Bento being shutdown halfway through...)

- ...And by the fact that we are using a Redis queue

  (which doesn't offer delivery guarantees or acknowledgements)

- Can we get something better?

---

## The problem

- Some inputs (like `redis_list`) don't support *acknowledgements*

- When a message is pulled from the queue, it is deleted immediately

- If the message is lost for any reason, it is lost permanently

---

## The solution

- Some inputs (like `amqp_0_9`) support acknowledgements

- When a message is pulled from the queue:

  - it is not visible anymore to other consumers

  - it needs to be explicitly acknowledged

- The acknowledgement is done by Bento when the message reaches the output

- The acknowledgement deletes the message

- No acknowledgement after a while? Consumer crashes/disconnects?

  Message gets requeued automatically!

---

## `amqp_0_9`

- Protocol used by RabbitMQ

- Very simplified behavior:

  - messages are published to an [*exchange*][amqp-exchanges]

  - messages have a *routing key*

  - the exchange routes the message to one (or zero or more) queues
    </br>(possibly using the routing key or message headers to decide which queue(s))

  - [*consumers*][amqp-consumers] subscribe to queues to receive messages

[amqp-exchanges]: https://www.rabbitmq.com/tutorials/amqp-concepts#exchanges
[amqp-consumers]: https://www.rabbitmq.com/tutorials/amqp-concepts#consumers

---

## Using the default exchange

- There is a default exchange (called `""` - empty string)

- The routing key indicates the name of the queue to deliver to

- The queue needs to exist (we need to create it beforehand)

---

class: extra-details

## Defining custom exchanges

- Create an exchange

  - exchange types: direct, fanout, topic, headers

  - durability: persisted to disk to survive server restart or not?

- Create a binding

  - which exchange?

  - which routing key? (for direct exchanges)

  - which queue?

---

## RabbitMQ on Kubernetes

- RabbitMQ can be deployed on Kubernetes:

  - directly (creating e.g. a StatefulSet)

  - with the RabbitMQ operator

- We're going to do the latter!

- The operator includes the "topology operator"

  (to configure queues, exchanges, and bindings through custom resources)

---

## Installing the RabbitMQ operator

- Let's install it with this Helm chart:

  ```bash
  helm upgrade --install --repo https://charts.bitnami.com/bitnami \
      --namespace rabbitmq-system --create-namespace \
      rabbitmq-cluster-operator rabbitmq-cluster-operator
  ```

---

## Deploying a simple RabbitMQ cluster

- Let's use the YAML manifests in that directory:

  https://github.com/jpetazzo/beyond-load-balancers/tree/main/rabbitmq

- This creates:

  - a `RabbitmqCluster` called `mq`

  - a `Secret` called `mq-default-user` containing access credentials

  - a durable `Queue` named `q1` 

(We can ignore the `Exchange` and the `Binding`, we won't use them.)

---

## 🏗️ Let's build something!

Let's replace the `cities` Redis list with our RabbitMQ queue.

(See next slide for steps and hints!)

---

## Steps

1. Edit the Bento configuration for our "CSV importer".

   (replace the `redis_list` output with `amqp_0_9`)

2. Run that pipeline and confirm that messages show up in RabbitMQ.

3. Edit the Bento configuration for the Ollama consumer.

   (replace the `redis_list` input with `amqp_0_9`)

4. Trigger a scale up of the Ollama consumer.

5. Update the KEDA Scaler to use RabbitMQ instead of Redis.

---

## 1️⃣ Sending messages to RabbitMQ

- Edit our Bento configuration (the one feeding the CSV file to Redis)

- We want the following `output` section:
  ```yaml
    output:
      amqp_0_9:
        exchange: ""
        key: q1
        mandatory: true
        urls:
         - "${AMQP_URL}"
  ```

- Then export the AMQP_URL environment variable using `connection_string` from Secret `mq-default-user`

💡 Yes, we can directly use environment variables in Bento configuration!

---

## 2️⃣ Testing our AMQP output

- Run the Bento pipeline

- To check that our messages made it:
  ```bash
  kubectl exec mq-server-0 -- rabbitmqctl list_queues
  ```

- We can also use Prometheus metrics, e.g. `rabbitmq_queue_messages`

---

## 3️⃣ Receiving messages from RabbitMQ

- Edit our other Bento configuration (the one in the Ollama consumer Pod)

- We want the following `input` section:
  ```yaml
    input:
      amqp_0_9:
        urls:
          - `amqp://...:5672/`
        queue: q1
  ```

---

## 4️⃣ Triggering Ollama scale up

- If the autoscaler is configured to scale to zero, disable it

  (easiest solution: delete the ScaledObject)

- Then manually scale the Deployment to e.g. 4 Pods

- Check that messages are processed and show up in the output
 
  (it should still be a Redis list at this point)

---

## 5️⃣ Autoscaling on RabbitMQ

- We need to update our ScaledObject

- Check the [RabbitMQ Queue Scaler][keda-rabbitmq]

- Multiple ways to pass the AMQP URL:

  - hardcode it (easier solution for testing!)

  - use `...fromEnv` and set environment variables in target pod

  - create and use a TriggerAuthentication

💡 Since we have the AMQP URL in a Secret, TriggerAuthentication works great!

[keda-rabbitmq]: https://keda.sh/docs/latest/scalers/rabbitmq-queue/
