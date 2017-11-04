## Getting task information for a given node

- You can see all the tasks assigned to a node with `docker node ps`

- It shows the *desired state* and *current state* of each task

- `docker node ps` shows info about the current node

- `docker node ps <node_name_or_id>` shows info for another node

- `docker node ps -f <filter_expression>` allows to select which tasks to show

  ```bash
  # Show only tasks that are supposed to be running
  docker node ps -f desired-state=running
  # Show only tasks whose name contains the string "front"
  docker node ps -f name=front
  ```
