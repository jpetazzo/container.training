# Exercise — BuildKit cache mounts

We want to make our builds faster by leveraging BuildKit cache mounts.

Of course, if we don't make any changes to the code, the build should be instantaneous. Therefore, to benchmark our changes, we will make trivial changes to the code (e.g. change the message in a "print" statement) and measure (e.g. with `time`) how long it takes to rebuild the image.
