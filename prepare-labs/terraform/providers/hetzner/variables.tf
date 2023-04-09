/*
$ hcloud server-type list | grep shared
1    cx11    1       shared      2.0 GB     20 GB    local
3    cx21    2       shared      4.0 GB     40 GB    local
5    cx31    2       shared      8.0 GB     80 GB    local
7    cx41    4       shared      16.0 GB    160 GB   local
9    cx51    8       shared      32.0 GB    240 GB   local
22   cpx11   2       shared      2.0 GB     40 GB    local
23   cpx21   3       shared      4.0 GB     80 GB    local
24   cpx31   4       shared      8.0 GB     160 GB   local
25   cpx41   8       shared      16.0 GB    240 GB   local
26   cpx51   16      shared      32.0 GB    360 GB   local
*/
variable "node_sizes" {
  type = map(any)
  default = {
    S = "cx11"
    M = "cx21"
    L = "cx31"
  }
}

/*
$ hcloud location list
ID   NAME   DESCRIPTION             NETWORK ZONE   COUNTRY   CITY
1    fsn1   Falkenstein DC Park 1   eu-central     DE        Falkenstein
2    nbg1   Nuremberg DC Park 1     eu-central     DE        Nuremberg
3    hel1   Helsinki DC Park 1      eu-central     FI        Helsinki
4    ash    Ashburn, VA             us-east        US        Ashburn, VA
5    hil    Hillsboro, OR           us-west        US        Hillsboro, OR
*/
variable "location" {
  type    = string
  default = "hel1"
}
