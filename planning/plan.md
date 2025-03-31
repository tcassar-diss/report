# Fine-Grained Linux System Call Filtering

## Todos for Report
1. More benchmarks
2. Run with a Java program!
    - Hadn't thought about JIT; could be a problem
    - If it is a problem, will talk about in future works
    - Hopefully the address space won't be moving around with JIT
3. Related works
    - Snowball from bank of papers in Zotero
4. After reading up on performance engineering, realised I am actually tracing
   not profling - need to rename?

## Abstract

TODO: Write after introduction written

## Introduction

### Context
- What is syscall filtering
    - Used to secure programs in multi-tenant environments and sandbox
    applications [BSIDE](https://dl.acm.org/doi/pdf/10.1145/3652892.3700761)
    - Security measure for detecting compromise of applications
    - Breaches in confidentiality and data integrity can be mitigated by
    killing processes which trip the filter 
    - Program making syscall not in its source code => dangerous
    misbehaviour; probable indication of compromise

- What is compartmentalisation?
    - Growing body of research which advocates that we cannot continue to see an
    application as a single unit of trust [SoK](https://arxiv.org/abs/2410.08434).
    - Instead, should be decomposing software into "compartments" each with the
      least privilege they need to run.
    - General principle; comes in many forms e.g. restricting memory accesses
    (Intel MPKs, Cheri capabilities/ARM Morello)

### Motivating the Problem
- Modern cyberattacks increasingly target critical infrastructure, exploiting 
weaknesses in system software to escalate privileges or exfiltrate sensitive
data. 

- Applications are large and getting larger => attack surface gets larger and
larger.
- e.g. `/bin/true` - zero LoC when first introduced; 2.9k LoC (assembly) on Ubuntu 24.04.2 LTS
    - (from sysfilter paper)

- As applications grow, the set of syscalls they are legitimately allowed to
make also increases.
- Attackers have more syscalls to exploit without risking tripping a syscall
filter.

- Syscall filtering is a commonly used security practice; sometimes developers
  are unaware that they are using it (e.g. Docker container not running with
`--privileged` flag)
- Being able to generate smaller lists for large applications will make it
harder for attackers to damage systems (in terms of confidentiality,
availability) if they have an RCE exploit.
- System call filtering is an application of the _principle of least privilege_
  [Saltzer and
Schroeder](https://ieeexplore.ieee.org/abstract/document/1451869); this work
proposes to push things further and apply syscall filtering on a finer
granularity.

- An example problem
    - One can imagine a program which legitimately uses dangerous syscalls
    within its main program.
    - e.g. Bash scripts: almost always spawn subprocesses via `execve`
    - Bash script legitimately needs access to `execve`, but in a lot of
    cases, the application being called doesn't.
    - As it stands, an attacker compromising the application would have access
    to `execve`!

### Aims and Objectives
1. Allow a user to define a set of system call filters which map dynamically linked shared libraries to a set of allowed system calls by implementing whitelist generation tooling.
2. Implement a mechanism which can:
    - Determine which software component a system call has come from
    - Detect what type of system call has been called (i.e. syscall number)
    - Take (user-configurable) action if any part of the application makes a
    system call which isn't on the whitelist
3. Provide a user-friendly command line interface which can
    - Accept (and parse) a set of system call whitelists
    - Launch an application with the whitelists enabled, or apply the provided
      filters to an already running application
    - Allow the user to configure what to do when a system call trips the
    filter: warn, kill only the affected process, or kill all forks of the
    original process
4. Comment on the efficacy of the solution in terms of security (evaluation and
   analysis) and performance overheads when compared to no system call filter
   and the state of the art (`seccomp`)

### Solution
- Approach the idea of system call filtering from a **software
compartmentalisation perspective**
    - Decompose the application into smaller units of trust **based on the
    process's address space**
    - Give each region its a bespoke narrow system call filter.

![](../diagrams/intro/address-space-decomp.pdf "Address Space Decomposition")

- Proposed research: create a "_spatial_" filter which accounts for where
 in a process's address space a system call originated.
- Create tooling which will enable the generation of whitelists per software
unit e.g. as per the diagram above. In this context, **shared libraries** were
chosen as units of software.

- Create `addrfilter`: an application which is able to detect a compartment
which has made a syscall which isn't on it's whitelist and take action
accordingly. This could be killing the process or warning the user (config
dependant)

### Challenges
- Identifying which software component has made a given system call.
- Identifying an allowed set of system calls for each software component in an
- Providing a good UX
    - Easy to use, informative CLI
- Working with eBPF is a challenge in itself
    - No documentation, lots of kernel code reading
- Edge cases
    - JIT compilation
    - Maintaining performance when stressed


### Evaluation Strategy
- Need to evaluate **costs** and **benefits** of the approach
- Calculating benefits will be done by **quantifying privilege reduction** 
    - Define a metric which will quantify privilege level of an
    application
    - Compare privilege of unfiltered/seccomp/proposed
    - Will require analysis tooling to identify which libraries make which
    syscalls 
- Calculating costs will be done by looking at slowdown across a broad range of
  benchmarks
    - Compare unfiltered, seccomp, proposed ### Success Criteria The user should be able to define an allowed set of system calls for each file-backed region of a process's address space
- If a region makes a syscall not in its whitelist, the program should warn the
  user, kill the process, or kill all monitored processes (user configuration
dependant)
- The solution should demonstrate a level of privilege reduction compared to a
blanket system call filter for both large (e.g. `nginx`) and small (e.g. a C
`hello world`) reduction in privilege for dynamically linked binaries 
- The applications running protected under the solution should still be performant

- `addrfilter` was implemented and shows promising results
    - 38.2% privilege reduction in `redis`, 23.7% in `nginx`; two representative
      server workloads
    - Saw no significant slowdown in non-intensive applications, and in the
    worst case, ~30% slowdown in Redis benchmark (stressful)
    - More than acceptable worst case overhead for such a level of privilege
    reduction.

## Background

### What is the kernel
 - Userspace (untrusted) software
 - Kernelspace trusted
 - Why is the separation needed?
 - What is a world switch (user/kernel)

### What is a system call
- Secure gate to allow switch from insecure to secure mode
 Syscalls (almost always) via libc
- `libc` provides a `syscall()` function to avoid inline asm
- `libc` also provides lots of wrapper functions e.g. `open`

#### What happens during a world switch
- Software interrupt
- Saving/restoring registers
- Sanitising syscall arguments
- Architecturally expensive (e.g. cannot be mitigated)
    - Cache pollution
    - Pipeline flush
    - TLB flush

### What is compartmentalisation
- Defensive security design measure
- Very broad concept: can refer to hardware-enforced isolation strategies e.g.
CHERI, MPX; can refer more broadly to design in which attackers who take over a
compartment in some way are confined to it.
- Could also refer to tab sandboxing in Chrome: processes enforce isolation by
design; prevents tabs from accessing each others' data.

### Security basics (for project)
- Whitelists and Blacklists (will have been mentioned above)
- What is privilege
- What is privilege reduction, principle of least privilege

### eBPF
- What problem does BPF solve
    - Efficient, sandboxed code execution **in kernel**
- Verification
    - Limited expressivity, guaranteed safe code

- Common uses
    - Patching vulnerabilities e.g. drop malicious packets
    - Tracing/profiling
- Trend towards being more capable
    - Possible to write "bpf helper functions"; worry that it breaks formal
    verification (if implemented incorrectly)

#### eBPF basics
- What is a tracepoint
    - When does it run (depends on tracepoint - key point is _event driven_)
    - How is it loaded (by root user, bpf syscall)

- What is a map
    - `BPF_MAP_TYPE_ARRAY`
    - `BPF_MAP_TYPE_HASH`

- What is a ringbuffer

### Traditional filtering mechanisms
- `seccomp`: broad range application filter
- Used very often
    - Docker "_built in_" filter
- Pain to configure
    - Happens via `prctl` syscall

### Processes
- Processes provide strong "_inter-application_" isolation

#### Address Space 
- Statically vs Dynamically linked executables
- Understanding `/proc/pid/maps`: human-parsable representation of a process's
virtual address space 
- What does the address space look like under the hood
    - `vma_struct` red black tree
    - `file` struct

#### Process's stack
- Each process has its own stack
- Relevant parts of stack frame
    - RP added on a function call; can therefore use stack to "_trace a path_"
    through the code

## Design

### Requirements
1. Users should be able to configure a whitelist that defines allowed syscalls
   for each shared library mapped into a process’s address space. This process
   should be automated through either dynamic or static analysis.
2. If a process violates this whitelist, the system should either terminate 
   the process or issue a warning, based on user configuration.
3. If a system call happens and is not in the whitelist of it's invoking shared
   library, the process should be killed before the kernel starts to process the
   system call(or the user should be warned, config dependant.)
4. The program should apply the same filter to any forked processes of the
   original process being filtered. The configuring user should be given the
option to have all forks killed if any process trips the filter.
5. In case of failures in the filtering mechanism (e.g stack walking fails),
   **availability** should be prioritised (e.g. warn userspace, don't kill
   process)
6. The filtering program should offer meaningful privilege reduction at an
   acceptable amount of application slowdown. QUESTION: how to quantify this?

### Threat Model
- Attacker has compromised the protected process and has an RCE exploit.
- The attacker decides to run malicious code on the system which uses system 
  calls.
- There is some form of compartmentalisation in place which prevents the
attacker from jumping to part of the address space where the syscall they want
to use is available. This could be based on Intel MPK, Cheri capabilities, etc.
- The attacker has taken over a single compartment of the application and is
trying to escalate privilege
- The attacker does not have root access

### Solution Architecture

### User configuration
- launch vs attach
- profile flag
- warn, killall mode
- provide a whitelist

### Userspace setup
- Load whitelist
- Load libc address space of parent process (when launching a new process) or
provided PID (attatching)
- Insert relevant PID into follow map

### Kernelspace, setup
- Compile with/without `PROFILE` macro defined for profiling symbols
- Compile with/without `VERBOSE` for verbose mode

### Kernelspace, on syscall invocation
- Using `raw_tp/sys_enter` called for each syscall
- Record counts of event

1. Get PID of process which triggered the system call
2. Check to see if filter should be applied
    - Fork following: if ppid in filter map, add pid to filter map and trace
3. Find syscall site
    - Walk stack until first non-libc return pointer is found and use this as
    syscall invocation site
4. Walk `vma_struct` red black tree to find which shared library made the
   system call
5. Retrieve the relevant whitelist for the given shared libary
6. Check to see if the syscall is in the whitelist
7. (depending on config) warn, kill the process (sync) or kill all processes
   being followed (sync kill for compromised process, async for others)
8. If stack walking/vma_struct rb walking fails, then system calls should be
   allowed to happen as false positives are unacceptable in production.

## Implementation

### Frontend: Go
- CLI to allow for ergonomic loading
    - Benefit over seccomp: seccomp is a pain
- Load libc to addresses map (by parsing `/proc/PID/maps` in userspace)
- Parse whitelist and load to whitelists map 
- Contains code to listen to profiling ringbuffer (if enabled)
- Contains code to listen to the warn ringbuffer and either warns or kills all
forked processes as configured

### BPF/Go integration: `cilium/ebpf`
- `bpf2go` is a Go tool (part of cilium/ebpf) that generates Go bindings for 
   compiled BPF programs.
- Handles compilation of C to BPF bytecode and autogenerates structs and
  handlers for maps in Go.
- Supports BPF CO-RE (Compile Once, Run Anywhere), making deployment across
  different kernel versions easier.

### BPF Maps
- Maps are used by BPF programs to store data. They are also accessible from
userspace by appropriately privileged users (by default, just root)
- Maps can be used to persist data between BPF program runs, and can be used for
  communicating with userspace. Unordered. 
- Not always thread safe - concurrent writes need to be explicitly guarded against
e.g. with a mutex, `__sync_fetch_and_add`, etc, (dependant on map type).

### BPF Ringbuffers
- Used for message passing to/from userspace
- Thread safe

### BPF tracepoint
1. Finding PID, PPID, checking filter
    - `task` struct, `parent` struct
    - read `tgid` instead of `pid` as threads conceptually different in
    kernelspace
    - if PID not in filter map, return
2. Fork following
    - If PPID in filter map, then add PID to filter map
3. Find syscall site
    - Use `bpf_get_stack` helper to pull user stackframes return pointers
    - Loop over return addresses: continue if in libc range (stored in libc
    map)
    - Mark the first non-libc return address as the syscall invocation site
    - Warn userspace if stack ends before non-libc address is found
4. Associate invocation site with shared library file
    - Use `bpf_find_vma` helper to find the `vma_struct` associated with the
    pointer found in the last step
    - Access `fpath` struct via `vma_struct` to get the filename associated
    with shared library
5. Use the filename as a key to pull the whitelist for the given shared
   library
6. Pull syscall number (`n`) from the `task` struct, and check the `n`th bit of
   the whitelist bitmap. 0 <=> block, 1 <=> allow; bitmap chosen as efficient
   and fast.
7. If allow, return with no further action from tracepoint
8. If block
    - Warn: write syscall number, shared libary filename to warn ringbuf
    - Kill: use `bpf_send_signal` to send a KILL to the calling process
    - KillAll: write syscall number, shared libary, to warn ringbuf

    (userspace knows which flag it has been called with, and responds to info
    in warn ringbuffer accordingly)

- Profiling:
    - `PROFILE` defined => record profiling info
    - Use `profile_buf` ringbuffer; after each of the steps outlined above,
    get timestamp using `bpf_ktime_get_ns()` helper: gets kernel time
    (nanoseconds since boot; monotonic, no leap seconds, etc)
    - Report to userspace: can build graphs showing time for each stage

## Evaluation

- Broad evaluation questions to answer
    1. What degree of privilege reduction does this system provide
    2. How much cost does fine-grained system call filtering cost in terms of
       application slowdown?

### Evaluating privilege reduction

#### Methodology
- Develop analysis tooling to identify which libraries make which syscalls
- Use a custom metric based on literature to quantify privilege level of each
compartment: define the privilege level of the application as the level of the
most privileged compartment
- Compare this to no filter baseline, and to an application-wide seccomp filter
  (with privilege calculated in the same way)

#### About the metric

- Motivation
    - Can't just go with raw syscall counts as not all syscalls equally
    dangerous
    - Some syscalls completely safe e.g. `getpid`; some are extremely risky e.g.
      `execve`. This difference needs to be accounted for

    - Number of syscall invocations should be independent of privilege level
        - Doesn't matter that a syscall happened n times; only care about do we
          allow it or not.
    
    - Needs to be backed by literature and not involve assigning an arbitrary
    "danger score" to a syscall

- Proposed metric
    - Identify a set of "dangerous" system calls from "literature"
    - Assign these a score of 1; else, score of 0.
    - Danger of compartment = sum (score_i) for i in syscall numbers

#### Presentation of results

- Aggregate results from benchmark into one plot
    - Bar chart plotting privilege level of applications
    - X-axis: benchmarked application; y-axis: privilege score
    - Each application tested has two bars side by side: max privilege with
    seccomp, max privilege with addrfilter
    - Plot a horizontal line at privilege level for unfiltered application
        - With no filter, any application can make any syscall so it doesn't
        make sense to plot many times over

- Analysis of plot
    - General trend: addrfilter gives less privilege while allowing for normal
    running of application
    - Qualify by saying
        - Benchmarks run overnight with no false positives (:todo:)

- Zoom in on interesting examples
    - Plot with highest privilege reduction level
    - Plot with lowest privilege reduction level
    - Plot with ~same privilege level
    ...
    - and explian why
        - Statically linked executable -> few (probably 3) shared libraries
        - Benchmark uses extremely broad array of syscalls
        - etc... 

#### Preventing real-world CVEs
- (If time allows)
- Find a CVE, generate seccomp list w/ a static analyser; reason that it could
have been prevented with `addrfilter`

#### Summary
- Avg reduction vs baseline
- Avg reduction vs seccomp

### Evaluating performance cost

#### Methodology
- For a broad range of benchmarks
    - Run benchmark on `addrfilter`:
        - No verbose mode
        - No profile mode
    - Record benchmark statistics (specific to each benchmark) 
    - Repeat $n$ times for reliability.
    - Preceed entire thing with warm up runs (unless benchmark specifies
    otherwise)

- Repeat with
    - No syscall filtering mechanism attached
    - Seccomp filter attached (state-of-the-art comparison)

#### Benchmarks
- Broad range intended to test every aspect of system
- I/O heavy benchmark `fio`
- Redis - system call intensive with a small key size; o/w memory intensive
- Nginx - representative server application; adding modules -> used to stress
vma walking portion of `addrfilter`
- CPU Intensive: Whetstone 

#### Plot for each benchmark
- Relevant metrics for each benchmark - cluster no filter, seccomp, 
- Talk about relevant setup details
    - e.g. Nginx, redis: client and server run on same machine s.th. not network
      bound
    - Key config settings e.g. redis key size, whetstone iterations, etc
    - Report any changes from quickstart guides etc

- Analysis: why do the plots look like this
- e.g. redis: <40% slowdown is a lot - why?
    - System call intensive with small key sizes

### Profiling
- Benchmarks run with `PROFILE` macro defined, `--profile` flag passed in
- Plot: show stack walking is the bottleneck
    - Hypothesis (I haven't measured yet):
    - Stack walking will always be bottleneck
    - Pulling 32 frames => exactly 32 loads from memory
    - To navigate 32 `vma_structs` would require a red-black tree of 2^32-1
    nodes; this won't happen, so stack will probably always be slower
    (will measure and reason about this properly)

- Shows that
    - No opportunities for optimisation without significant engineering effort
    - Would have to implement a mechanism to bypass the stack walking stage
        - Track where libc entered; would require modification of libc (very
        broad interface) and therefore lots of work

### Limitations
(not sure if this belongs in this section)
- Incompatible with Docker
    - Stack debacle...
    - Reporting stack as being [RP, 0, ..., 0]; not correct
    - GDB saw full stack when launched in container
    - GDB saw full stack when launched outside container and attached to process
      (via pid; required `--pid=host` when launching container)
    - More research needed to identify problem source

## Related Works
- SysPart: temporal filtering of syscalls
- Eternal War in Memory SoK
- Work on automating syscall whitelist generation
- C2C: excluding dead code (based on config) from `seccomp` filter
- SysFilter: very useful for motivation that binaries are getting bigger
    - e.g. `/bin/true` 0 LoC -> 2.3k in ubuntu 
- Talk about differences from emulation work
    - Proposed research is security focused; not about emulation.

#### Future Work
- Function level system call filtering
- Providing spatial system call filtering mechanism for **statically linked**
binaries
    - Gaining popularity: e.g. Go, Rust
    - Harder to statically analyse: larger binaries => more runtime
    - Cannot break up by address space (or rather no meaningful privilege
    reduction: go binaries feature the following)
    - For instance, go build will only have one file mapped in its address
    space: /home/"$USER"/tmp/[PACKAGE NAME]

- Static analysis for per-library whitelist generation
- Further investigation into Docker and `bpf_get_stack` incomatibility
    - Given widespread docker use, a good idea
