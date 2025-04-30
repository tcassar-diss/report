# Plan (again)

- Objectives of **plan 2**
  - Narrative: always explaining **why** `addrfilter` is a good idea

---

## Title Pages

- Title page
  - BPF
  - Gopher
  - Cilium project
  - Linux Penguin
  - Heereboys-generated logo
- Declaration
- Acknowledgements
- ToC
- List of Acronyms and Abbreviations
- List of Tables
- List of Figures
- Abstract (200 words)

## Introduction (1000 words)

> **SECTION PURPOSE**: Convince the reader that addrfilter is needed
>
> - What does `addrfilter` do?
> - Why is `addrfilter` needed?
> - Preliminary findings: how well does `addrfilter` perform versus alternatives
>   - Provide table of results
> - How was `addrfilter` implemented?

### What is `addrfilter`

- Security tooling built for Linux based on a **novel approach**
- Will kill an application if it makes a **system call** it isn't allowed to
  make.
- Novel approach: fine-grained filtering based on **process address space**

### Why is syscall filtering needed?

- Bring up that state of the art is `seccomp`!
- Seccomp defines one global filter for an application.
- Applications are getting constantly bigger in terms of LoCs (SYSFILTER)

  - => (legitimately) needs access to more system calls
  - => seccomp filters must be more permissive, therefore less restrictive

- TODO: find real world exploit

### Does `addrfilter` work?

- Addrfilter shows promising results
  - Redis sees a 37.0% privilege reduction (forward ref. evaluation section),
    nginx sees 23.7%, whereas seccomp only shows X% and Y% respectively.
  - Results of a worst-case stress test showed a 40% reduction in throughput in a
    Redis microbenchmark, with seccomp showing a Z% reduction. (Mean slowdown over
    the whole suite was A%).
- Depending on what you're doing, its probably the sensible choice over
  `seccomp`.
- Designed for **compartmentalised systems**; compartmentalisation breaks the
  process into individual segments called compartments. If an attacker compromises
  an application, they are confined to the compartment they compromised.

- Redis sees a 37.0% privilege reduction (forward ref. evaluation section),
  nginx sees 23.7%, whereas seccomp only shows X% and Y% respectively.
- Results of a worst-case stress test showed a 40% reduction in throughput in a
  Redis microbenchmark, with seccomp showing a Z% reduction. (Mean slowdown over
  the whole suite was A%).

### How does `addrfilter` work?

- High level
- Reference core idea of syscall filtering
- Bring in **process address spaces**: `addrfilter` defines a syscall whitelist
  for shared libraries!
- Results in smaller, more precise filters and therefore a **more secure**
  application!
- (Because different libraries tend to serve isolated purposes, `addrfilter`
  can enforce syscall policies more precisely).

### Bridge to background

- `addrfilter` is a complex systems security project which required an in-depth
  understanding of the Linux Kernel to implement.
- The next section summarises the **key background knowledge needed** to
  understand the need for, design of, and evaluation strategy behind `addrfilter`.
- Key topics include BPF, seccomp, memory layout, and syscall dispatch.

## Background (1500) words

> **SECTION PURPOSE**: Introduce the reader to concepts they need to understand
> to understand `addrfilter`; show that existing solutions are outdated

TODO: replan on rewrite!

- Syscalls
- Compartmentalisation and why its relevant
- BPF
- Seccomp

### Bridge to design

- We‚Äôve now seen why syscall filtering is necessary, how it‚Äôs currently done, and where existing solutions fall short.
- These limitations directly informed the design goals of `addrfilter`.
- The next section explains how these challenges were addressed through a focused, minimalistic, and precise design.

## Design (1500 words)

> **SECTION PURPOSE**: Justify requirements, argue that `addrfilter` is the
> simplest product which will fulfil these requirements.

- System security project; each loc => increased attack surface, increased
  maintenance
- Care was taken to design the **simplest possible application** which would
  achieve the objective: filter syscalls by address space.
- Caveat: needs to be performant!

- Approach taken was to
  - Formalise a **threat model**
  - Use the threat model to inform **requirements**
  - Design the simplest possible application that will fulfil requirements
    while being performant.

### Threat Model

- Attacker has an RCE via the filtered application
- Attacker doesn't have root privileges (`SYS_CAP_ADMIN`)
- System has a form of compartmentalisation implemented (otherwise attacker can
  use RoP to jump to a part of the address space where their syscall is allowed;
  thus, reducing `addrfilter` to a slower `seccomp `filter)

### Main Requirements

1. `addrfilter` should detect when an application makes a disallowed syscall and
   take _"appropriate action"_.
2. The user should be able to configure the _"appropriate action"_ to be either
   killing the process, warning, or killing all filtered processes.
3. `addrfilter` should take a **default deny** approach to filtering, with the
   user able to **explicitly allow** which system calls be made (whitelists).
4. The user should be able to specify whitelists for each shared library, defined
   as any file-backed region of a processes VMA.
5. `addrfilter` should significantly reduce the set of dangerous system calls
   that an attacker compromising a compartment has access to in a way that does not
   detrimentally impact application performance.

The evaluation section shows that redis sees a 37.0% privilege reduction
compared to seccomp, at an average slowdown of ~20%.

### Corollary Requirements

These requirements are not alone by themselves. Developers don't readily know
which system calls their application makes, let alone which syscall compartments
make. Therefore, there is an important corollary requirement: **whitelist
generation**.

6. `addrfilter` should provide automated tooling to generate precise
   per-compartment whitelists.

Furthermore, there are no standard metrics which quantify the idea of
system call privilege, so to be able to reason about privilege reduction, this
also needs defining.

7. A metric needs to be defined and justified which enables reasoning about the
   privilege some set of system calls affords an attacker.
8. Automated tooling needs to be developed which will give the developer
   information about the extent of privilege reduction they could see from using
   addrfilter.

While care will be taken to use a broad, applicable range of benchmarks in the
evaluation phase, whether `addrfilter` is suitable will always depend on the
developer's **actual** use case. Therefor, it's important to provide some key
indicators of slowdown.

8. Provide a metric which gives a rough indication of performance penalties.
   This isn't intended to be used as a ground truth, but merely as an indication
   about whether `addrfilter` is right for the given use case.

Having now codified the threat model and requirements, we propose an overview of
the design. The design is able to fulfil all the main requirements: tooling from
the corollary requirements will be discussed after the design of `addrfilter`.

### Design overview

TODO: diagram

- Core sections

  - Frontend: CLI, attaches the filter to running apps; warns user, kills other
    processes in follow map.
  - BPF Maps/ringbufs: used for communication between userspace and the
    kernelspace filtering program
  - Backend: the **tracepoint** is run on each system call. This is the
    filtering machinery

- Main tracepoint flow
  - Flowchart: main function from tracepoint

```c
SEC("raw_tp/sys_enter")
int addrfilter(struct bpf_raw_tracepoint_args *ctx) {
  record_stat(TP_ENTERED);

  u64 rp = 0;
  pid_t pid;

  struct task_struct *task;
  u64 syscall_nr = ctx->args[1];

  task = bpf_get_current_task_btf();
  if (!task) {
    record_stat(GET_CUR_TASK_FAILED);
    return 1;
  }

  if (bpf_probe_read(&pid, sizeof(pid), &task->tgid) != 0) {
    record_stat(PID_READ_FAILED);
    CALL_PROF_DISCARD(prof);
    return false;
  }

  if (!apply_filter(task, pid)) {
    record_stat(IGNORE_PID);
    CALL_PROF_DISCARD(prof);
    return 0;
  }

  if (find_syscall_site(ctx, &rp, pid) != 0) {
    return -1;
  }

  struct memory_filename mem_filename = {};
  if (assign_filename(task, rp, &mem_filename) != 0) {
    return -1;
  }

  struct syscall_whitelist *whitelist;
  whitelist = (struct syscall_whitelist *)bpf_map_lookup_elem(
      &path_whitelist_map, &mem_filename.d_iname);

  if (!whitelist) {
    record_stat(WHITELIST_MISSING);
    return 0;
  }

  if (check_whitelist_field(whitelist, syscall_nr) == 1) {
    return 0;
  }

  record_stat(SYSCALL_BLOCKED);

  filter(pid);

  return 0;
}
```

### Design Tradeoffs

- `libc` is fixed
  - Assume that `libc` does not change
  - Wouldn't be difficult to remove this assumption, but adds complexity
  - In the real world, the libc address hardly ever changes during program
    execution, although it is technically possible
  - To account for this, a new tracepoint would be made and hooked into
    mmap/munmap.
  - The tracepoint would then check the args to mmap/munmap and update any
    changes to the libc address space map
- `addrfilter` was designed to keep the libc address space in a map in case
  this functionality was needed later; at the moment, libc is loaded before
  the tracepoint using information from /proc/pid/maps. This was done as in
  testing, libc never changed so for simplicity, this feature wasn't built

The next section discusses how this design is implemented in reproducible
detail.

## Implementation (1500 words)

> **SECTION PURPOSE**: Give the reader a detailed enough decription of the
> system for reimplementation.

Unlike the design phase, implementing addrfilter was not done in discrete
stages. A key design choice was to use eBPF - a challenging programming language
to develop in due to its highly restrictive nature. The lack of accessible
documentation for eBPF added to these challenges and necessitated a more
iterative approach to implementation.

As such, this section is not structured in chronological order: it starts with
an outline

### Technologies used

- BPF
  - Ability to write kernel code in a formally verified, safe environment
  - Doesn't require patching the kernel: improves development speed, transparent
    uptake for developers
- Go
  - Need for concurrency support in userspace (reading ringbufs)
  - No need for fine hardware control in userspace; do need access to
    simple iteration, good interfacing with bpf
  - `context.Context` pattern suited to handling long-lived tasks such as
    filtering
  - Go is not normally thought of as a systems programming language; however,
    the Go service won't be doing anything systems level: only interfacing with
    systems level things. We profiled:
- Cilum `ebpf-go`
  - Autogeneration of go code for BPF data structures (maps, ringbufs, enums,
    etc, bpf-vm bytecode itself)
  - Compilation of `.bpf.c` code during go build process
  - Provides clean, idiomatic API for loading program etc
  - Tradeoff is **smaller ecosystem**, less powerful than C toolchains e.g.
    libbpf; design phase doesn't flag the need for any abilities that ebpf-go
    lacks

### Filtering Program

### Speculating about performance

## Evaluation 2500 words

> **SECTION PURPOSE**: Show how well `addrfilter` achieves its goals; show it's
> value vs seccomp, and talk about where to use each solution
>
> - Security goals
> - Performance goals
> - Syscall frequency: indicator of slowdown

### Bridge to Related Works

- Demonstrated that `addrfilter` is an effective solution for syscall filtering
  in its own right.
- `addrfilter` is also a timely and relevant contribution to ongoing research in
  syscall filtering and software compartmentalisation.
- The next section places `addrfilter` within this broader context, showing how
  it advances the state of the art in both novelty and utility.

## Related Works (1500 words)

### The state of **system call filtering**

#### Works motivating system call filtering

- Early approaches involved user-mode techniques; e.g. tracing `/proc`.
- **Janus**: early (1999) influential hybrid scheme, leveraged `ptrace`
  (addrfilter also leverages ptrace to an extent (`pt_regs`))
- Systrace: userspace/kernelspace hybrid syscall filter; gave the user a lot of
  control over policies, including features like UID-specific allow lists.

#### The challenge: building whitelists

- Gold standard: static analysis

  - SysFilter
  - BSide
  - SA issue with addrfilter: no tooling exists atm; lots of engineering effort
    to do. Not as simple as taking the intersection of main binary syscalls and
    shared library syscalls!

- Dynamic analysis:
  - Not a gold standard
  - Unsuitable for a production use case
  - However, **good enough** to prove the efficacy of `addrfilter` (orthogonal)
  - Used in papers in well-renowned conferences (e.g. made up part of SysPart)

#### Novel Syscall Filtering Implementations

- Syspart: a different take on a "fine grained" approach

  - Idea is that server applications exhibit different set of syscalls on
    startup vs during steady state
  - Syspart builds on other works TODO: list...

- SysXCHG: dynamically swap syscall lists based on `execve`; restrict privileges
  of child processes!

- Optimus (2024): further isolate containers from hosts by introducing a runtime
  filtering policy (use this to reference limitations)

- A lot of work looking at application of principle of least privilege;
  - Work doesn't link itself to **software compartmentalisation**, but
    addrfilter does

#### Software Compartmentalisation

- Software: application of principle of least privilege (Saltzer JH, Schroeder MD)
- Backends
  - CHERI capabilities (Arm Morello, CheriBSD)
  - IntelMPKs
- Applications

  - Containing memory saftey issues (Tolerating Malicious Device Drivers in Linux)
  - Sandboxing untrusted third parties (SoK: Lessons Learned from Android Security)
  - Sandboxing unsafe part of languages (Intra-Unikernel Isolation with Intel
    Memory Protection Keys)
  - Thwarting supply-chain attacks (BreakApp) and side-channels (Mitigating
    Information Leakage Vulnerabilities) ,

- Intersection with applications of syscall filtering; therefore, sensible to describe
  syscall filtering as part of the wider paradigm.
- Furthermore, describing as part of the paradigm makes connections to previous
  works easier to see; combining syscall filtering with something like CheriBSD
  allows for the design of systems like addrfilter.

#### Justifying that addrfilter is novel

- Seen the state of the art in syscall filtering: no one has explicitly
  restricted by address space
- Addrfilter is relevant: obvious trend in the literature to look at tightening
  syscall lists (SysXCHG, SysPart)
- Addrfilter has a unique place in explicitly bridging the gap between software
  compartmentalisation and system call filtering, providing something new to the
  research community.

#### Addrfilter's limitations

- Optimus argues for the importance of filtering as relating to containers
  - Specifically poised to look at breakouts
- Docker: container market share of 87% (https://6sense.com/tech/containerization/docker-market-share)
  - Containers run by default with a (very permissive) seccomp filter enabled;
  - Containers are an extremely favourable deployment mechanism for production
    code; as of time of writing, addrfilter doesn't support filtering from
    code run in containers

> **SECTION PURPOSE**: Argue that `addrfilter` is **novel**; show where it fits
> within state of the art.

## Conclusion (500 words)

**SECTION PURPOSE**: Talk about what `addrfilter` has achieved and what still
needs doing.

- Shown that `addrfilter` is
  - Novel
  - Relevant
  - Functional
  - Performant
- Shown via rigorous evaluation strategy
  - Range of benchmarks looking at different aspects of system performance
  - Compared to a base system as well as seccomp
  - Stress-tested `addrfilter` to find usecases where it isn't appropriate.
- Categorised the types of systems and applications where `addrfilter` is most
  appropriate
- Provided automated tooling to support the uptake of `addrfilter` with little
  effort among developers.
- Avenues for future work:
  - Reducing the cost of finding the syscall site
  - Static analysis tooling for whitelist generation
  - Expanding compatibility with other kernels and CPU architectures.
    (e.g. `pt_regs` on Arm: bad idea!)
    -Takeaway - Dynamic application, system with compartmentalisation primitives,
    high-security/low syscall-rate application => favour `addrfilter` over `seccomp`
