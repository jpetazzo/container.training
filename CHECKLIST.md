Checklist to use when delivering a workshop
Authored by Jérôme; additions by Bridget

- [ ] Create event-named branch (such as `conferenceYYYY`) in the [main repo](https://github.com/jpetazzo/container.training/)
  - [ ] Create file `slides/_redirects` containing a link to the desired tutorial: `/ /kube-halfday.yml.html 200`
  - [ ] Push local branch to GitHub and merge into main repo
  - [ ] [Netlify setup](https://app.netlify.com/sites/container-training/settings/domain): create subdomain for event-named branch
- [ ] Add link to event-named branch to [container.training front page](https://github.com/jpetazzo/container.training/blob/master/slides/index.html)
- [ ] Update the slides that says which versions we are using for [kube](https://github.com/jpetazzo/container.training/blob/master/slides/kube/versions-k8s.md) or [swarm](https://github.com/jpetazzo/container.training/blob/master/slides/swarm/versions.md) workshops
- [ ] Update the version of Compose and Machine in [settings](https://github.com/jpetazzo/container.training/tree/master/prepare-vms/settings)
- [ ] (optional) Create chatroom
- [ ] (optional) Set chatroom in YML ([kube half-day example](https://github.com/jpetazzo/container.training/blob/master/slides/kube-halfday.yml#L6-L8)) and deploy
- [ ] (optional) Put chat link on [container.training front page](https://github.com/jpetazzo/container.training/blob/master/slides/index.html)
- [ ] How many VMs do we need? Check with event organizers ahead of time
- [ ] Provision VMs (slightly more than we think we'll need)
- [ ] Change password on presenter's VMs (to forestall any hijinx)
- [ ] Onsite: walk the room to count seats, check power supplies, lectern, A/V setup
- [ ] Print cards
- [ ] Cut cards
- [ ] Last-minute merge from master
- [ ] Check that all looks good
- [ ] DELIVER!
- [ ] Shut down VMs
- [ ] Update index.html to remove chat link and move session to past things
