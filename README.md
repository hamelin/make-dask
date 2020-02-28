# `make-dask`: A GNU Make module to run code over a Dask compute cluster

The included Makefile involves a certain number of macros (`call`-able variables) and rules in order to set up a Dask
cluster as a pre-requisite to running Make recipes. It does not make your computations Dask-aware -- this remains the
programmer's job. However, it will set up a Dask scheduler and a set of workers that will divide between each other the
Dask-aware computations run through a Makefile. By setting the `MAKEFILES` environment variable as explained below, one
makes the `dask` Makefile target available from any local project, enabling the setup of a suitable compute cluster just
at the time the compute is required.

## Installation and setup

Copy the file `dask.mk` anywhere one can access it; cloning this repository fits the bill.

File `dask.mk` can be directly included in any project requiring the setup of a Dask cluster. If it is not in the
project's local directory or in one of GNU Make's
[Makefile search directories](https://www.gnu.org/software/make/manual/html_node/Include.html#Include), you may need to
invoke Make with the `-I` option to indicate where to find it.

#### Lazy coder's setup

In order to have access to the features of `dask.mk` anywhere, edit your shell's configuration file (`$HOME/.profile`,
`$HOME/.bashrc`, `$HOME/.zshrc`, `$HOME/.tcshrc`... whatever your shell configures itself from on start-up) to include a
definition of the `MAKEFILES` environment variable. This variable drives GNU Make to try and include (as if using
directive `-include`) any of the whitespace-separated paths as Makefiles prior to reading the ones for the project or
added on the command line. By adding the full path to `dask.mk` to this variable, you get Dask cluster setup
functionality in all of your projects.

#### Default configuration

By default, the compute cluster set up by this Makefile involves a scheduler (of course) and a single worker process
sporting 4 worker threads. See [below](#clusterconfig) for how to customize the cluster, including workers started on
remote (SSH-accessible) nodes.

## Typical usage

### Cluster setup

When `dask.mk` is included to a project's Makefile, its main feature consists in the `dask` target. Making the `dask`
target sets up a cluster composed of a scheduler on the node running GNU Make, as well as all of the configured worker
processes. Note that the worker and scheduler processes are all run in the background, so that `dask` can be used as a
[normal or order-only](https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html#Prerequisite-Types)
prerequisite. This target is made idempotent-ish by associating the execution of these runtime processes with a real
file (containing the process's PID).  Thus, separate invocations of Make with a Dask prerequisite will stick to a single
running instance of the cluster.

Remark that the scheduler and workers can be brought up separately, using targets `dask-scheduler` and `dask-workers`.
Furthermore, should a worker process die and its nanny be hopeless at bringing it back up, remaking the `dask` or
`dask-workers` targets will restart the missing worker without affecting the rest of the cluster.

### Bringing the cluster down

Make target `dask-kill` to bring down a running cluster (for instance, to start it in another process). Targets
`dask-kill-scheduler` and `dask-kill-workers` allow killing only one of the two components of the cluster. Individual
worker can be torn down by making target `dask-kill-worker-<name>`, where `<name>` is substituted with the [worker's
name](#clusterconfig).

### Checking the cluster's status

Target `dask-status` brings up a quick status of the scheduler and worker. It merely checks whether the associated
processes are up or down, truly.

### Checking and tracking the scheduler's and workers' logs

Targets `dask-check` and `dask-track` can be used to check the tail end of the logs, either quickly or continuously
following (as in `tail -f`), respectively.

Under the hood, the log files are queried using the `tail` command; further arguments can be provided by setting the
`dask-tail-args` variable from the command line.  In addition, specific logs can be either checked or tracked:
[name](#clusterconfig) the component for which to track logs by setting variable `dask-logs`. Example:

```
make dask-track dask-logs="scheduler worker-02@"
```

### Cleaning up leftover artifacts

Should one's computer crash while running the Dask cluster, the files used by `dask.mk` to track whether cluster
component are running become wrong: if one runs `make dask`, Make will suggest nothing needs be done. In order to clear
this burden of artifacts, make target `dask-reset`. To also get rid of previous log files, make target `dask-clean`.
Remark that if a cluster is running when such targets are made, it will be brought down (`dask-kill` is a prerequisite).


## <a name="clusterconfig"></a>Cluster configuration


## Examples

TBD
