#!/bin/sh
grep = ~/.oci/config | tr "=" " " | while read key value; do
  echo $key=\"$value\"
done > terraform.tfvars
