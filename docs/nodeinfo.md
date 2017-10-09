class: node-info

## Getting task information for a given node

- You can see all the tasks assigned to a node with `docker node ps`

- It shows the *desired state* and *current state* of each task

- `docker node ps` shows info about the current node

- `docker node ps <node_name_or_id>` shows info for another node

- `docker node ps -a` includes stopped and failed tasks
