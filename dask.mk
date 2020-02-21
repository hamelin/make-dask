# Relevant files for the cluster state and logs.
pid-file = $(addsuffix .pid,$(1))
log-file = $(addsuffix .log,$(1))


# Running daemons in the background as recipe for a target, some transient
# crumb being used as target.
define dask-run
(\
	rm -f $(call pid-file,$(1));\
	date "+*** Starting $(strip $(1)) at %Y-%m-%d %H:%M:%S ***" >>$(call log-file,$(1));\
	$(2) >>$(call log-file,$(1)) 2>&1 &\
	echo $$! >$(call pid-file,$(1));\
	wait;\
	rm -f $(call pid-file,$(1))\
) &
endef

# Scheduler parameters.
dask-scheduler-host = localhost
dask-scheduler-port = 8786
dask-scheduler-address = $(dask-scheduler-host):$(dask-scheduler-port)

# Worker default parameters
dask-worker-port-base = 18700
dask-workers-sanitized = $(strip $(dask-workers))
dask-threads-per-worker = 1

dask-spawn = scheduler $(addprefix worker-,$(dask-workers-sanitized))

# Usage of SSH for remote worker setup.
dask-forwardings = -L $(1):localhost:$(strip $(1)) -R $(dask-scheduler-port):$(dask-scheduler-address) 
dask-ssh-command = ssh
dask-ssh = $(dask-ssh-command) $(call dask-forwardings,$(3)) $(1) sh -c "$(strip $(2))"
dask-local = $(2)


# Main rules for setting up the scheduler and workers.
.PHONY: dask
dask: dask-scheduler dask-workers

.PHONY: dask-scheduler
dask-scheduler: $(call pid-file,scheduler)

$(call pid-file,scheduler):
	$(call dask-run,scheduler,dask-scheduler --host $(dask-scheduler-host) --port $(dask-scheduler-port))
	sleep 2  # Make sure schduler is online before running workers.

.PHONY: dask-workers
dask-workers: $(call pid-file,$(addprefix worker-,$(dask-workers-sanitized)))

.PHONY: dask-worker-%
dask-worker-%: $(call pid-file,worker-%)

$(call pid-file,worker-%): dask-name-host = $(subst @, ,$*)
$(call pid-file,worker-%): dask-name = $(word 1,$(dask-name-host))
$(call pid-file,worker-%): dask-host = $(word 2,$(dask-name-host))
$(call pid-file,worker-%): dask-port = $(shell echo $(dask-workers-sanitized) | sed 's/ /\n/g' | awk '($$1 == "$*"){print $(dask-worker-port-base) + NR; exit}')
$(call pid-file,worker-%): | $(call pid-file,scheduler)
	$(call dask-run,\
		worker-$*,\
		$(call $(if $(dask-host),dask-ssh,dask-local),\
			$(dask-host),\
			dask-worker --nprocs 1 --nthreads $(dask-threads-per-worker) --name $* --listen-address tcp://localhost:$(dask-port) $(dask-scheduler-address),\
			$(dask-port)))


# Killing cluster components.
.PHONY: dask-kill
dask-kill: dask-kill-workers dask-kill-scheduler

.PHONY: dask-kill-%
dask-kill-%:
	$(if $(wildcard $(call pid-file,$*)),kill $$(cat $(call pid-file,$*)); sleep 2,@true)

.PHONY: dask-kill-workers
dask-kill-workers: $(addprefix dask-kill-worker-,$(dask-workers-sanitized))


# Tool: maximum load suggestible when running multi-process Make.
.PHONY: dask-suggest-load
dask-suggest-load:
	@awk 'BEGIN{n=0} /^processor[ \t]+: [0-9]+/{n+=1} END{print n+0}' /proc/cpuinfo


# Tool: check status of various spawned daemons.
.PHONY: dask-status
dask-status: .dask-status
	@awk -F, '{printf("%s -- %s\n", $$1,$$2 ? "up" : "down")}' .dask-status

.PHONY: .dask-status
.dask-status: $(addprefix .dask-status-,$(dask-spawn))
	@cat $+ >$@
	@rm -f $+

.dask-status-%:
	@(echo -n $*, ; cat $(call pid-file,$*) 2>/dev/null || echo) >$@


# Tools for checking and tracking logs.
.PHONY: dask-check
dask-check: dask-tail-logs

.PHONY: dask-track
dask-track: dask-tail-args = -f
dask-track: dask-tail-logs

.PHONY: dask-tail-logs
dask-tail-logs: .dask-status
	tail $(dask-tail-args) $(call log-file,$(or $(dask-logs),$(shell awk -F, '{if($$2) print $$1}' .dask-status)))


# Clean-up
.PHONY: dask-clean
dask-clean: dask-kill
	rm -f $(call pid-file,$(dask-spawn)) $(call log-file,$(dask-spawn)) .dask-status*
