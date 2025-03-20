# Fine-Grained Linux System Call Filtering

## Todos for Report
1. More benchmarks
2. Run with a Java program!
    - Hadn't thought about JIT; could be a problem
    - If it is a problem, will talk about in future works
    - Hopefully the address space won't be moving around with JIT
3. Related works
    - Snowball from bank of papers in Zotero

## Abstract

`addrfilter` is a fine-grained system call filtering mechanism for Linux. Unlike `seccomp`, which applies a global system call filter application, `addrfilter` maps shared libraries to specific sets of allowed system calls. This fine-grained control provides privilege reduction when compared to `seccomp`, restricting what attackers are able to do with a remote code execution exploit.

## Introduction

### Context
- What is syscall filtering
    - Security measure for detecting compromise of applications
    - Breaches in confidentiality and data integrity can be mitigated by
    killing processes which trip the filter 
    - Program making syscall not in its source code => dangerous
    misbehaviour; probable indication of compromise

### Problem
- Applications are large: set of syscalls an application makes grows with
 LoC => traditional seccomp filters become less effective
- Attackers have more syscalls to exploit without risking tripping a syscall
filter

### Motivation
- Applications are large; `seccomp` doesn't adhere to principle of least
  privilege.
- Syscall filtering is a commonly used security practice; sometimes developers
  are unaware that they are using it (e.g. Docker container not running with
`--privileged` flag)
- Being able to generate smaller lists for large applications will make it
harder for attackers to damage systems (in terms of confidentiality,
availability) if they have an RCE exploit.

### Timeliness

_Reword the following (para 1 from PhD proposal)_

In an increasingly politically unstable world, software security is more critical than ever. Recent
successful cyberattacks on critical infrastructure and private data leaks show that our level of cyber
resilience is not where it needs to be: at the time when cyberattacks have become an instrument
of war, we need more robust software. Systems software (e.g. operating systems) are the backbone
of computer systems security, however they have historically been built using unsafe programming
languages, opening the possibility for exploits against which existing standard countermeasures are
insufficient. The recent push towards safe systems programming languages (e.g. Rust) and formal
verification of systems software will improve the status quo, but will take decades to be fully adopted,
and is unlikely to entirely eliminate vulnerabilities.

### Aims and Objectives
1. Allow a user to define a set of system call filters which map dynamically linked shared libraries to a set of allowed system calls.
2. Implement a mechanism which can:
    - Determine which library a system call has come from
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

### Solution
- Is it possible to create smaller, more specific filters for an application?
    - SysPart: "_temporal_" filter for setup/steady state phases of server
    applications
- Proposed research: create a "_spacial_" filter which accounts for where
 in a process's address space a system call originated.
- Conceptually nice way to break up an application: apply a bespoke filter
 to each file-backed portion of the process's virtual address space.

### Challenges

- Generating a per-library whitelists
- Identifying system call invocation sites
    - 'rp' will point to 'libc' wrapper: not meaninful
- Avoiding TOCTOU issues
    - Map return pointer with files in address space synchronously; otherwise
    address space, backing files, can all change
    - Kill an erroneous process before the system call happens
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
- If a region makes a syscall not in it's whitelist, the program should warn the
  user, kill the process, or kill all monitored processes (user configuration
dependant)
- The PoC should demonstrate a level of privilege reduction compared to a
blanket system call filter for both large (e.g. `nginx`) and small (e.g. a C
`hello world`) reduction in privilege for dynamically linked binaries 
- The applications running protected under the PoC should still be performant

## Background

### What is the kernel
 - Userspace (untrusted) software
 - Kernelspace trusted
 - Why is the separation needed?
 - What is a context switch

### What is a system call
- Secure gate to allow switch from insecure to secure mode

#### Making a system call
- A bit about ABI
    - `syscall` is a 0-ary x86 instruction
    - Need to place instructions in relevant registers
    - => need to write inline assembly to trigger a syscall yourself

- Syscalls (almost always) via libc
- `libc` provides a `syscall()` function to avoid inline asm
- `libc` also provides lots of wrapper functions e.g. `open`

### What is compartmentalisation
- Defensive security design measure
- Very broad concept: can refer to hardware-enforced isolation strategies e.g.
CHERI, MPX; can refer more broadly to design in which attackers who take over a
compartment in some way are confined to it.

### Security basics (for project)
- What is privilege
- What is privilege reduction, principle of least privilege
- What is TOCTOU (influences design)
- Confidentiality, Integrity, Availability

### eBPF
- What problem does BPF solve
- Verification; limited expressivity

- Common uses
- Trend towards being more capable

#### eBPF basics
- What is a tracepoint
    - When does it run
    - How is it loaded

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
- Understanding `/proc/pid/maps`
- What does the address space look like under the hood
    - `vma_struct` red black tree
    - `file` struct

#### Process's stack
- Each process has its own stack
- Relevant parts of stack frame
    - RPs: used to unwind the stack
    - RP added on a function call; can therefore use stack to "_trace a path_"
    through the code

## Design

### Requirements
1. User should be able to configure a whitelist which provides a set of allowed
   syscall numbers for each shared library mapped in a process's address space
   suspected malicious processes or just warn that the filter has been tripped.
2. Provide an easy to use CLI for the user, with options to attach the filter to
   an already running PID or to launch an executable with the filter enabled
3. If a system call happens and is not in the whitelist of it's invoking shared
   library, the process should be killed before the syscall starts (or the user
should be warned, config dependant.)
4. The program should apply the same filter to any forked processes of the
   original process being filtered. The configuring user should be given the
option to have all forks killed if any process trips the filter.

### Assumptions
- `libc` address space will not change (addressed in future works)
- `libc` mapping is contiguous in process address space
- Attacker does not already have root access

#### Threat Model
- Attacker has compromised the protected process and has an (R)CE exploit.
- The attacker decides to run code on the system which uses system calls.

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
4. Walk `vma_struct` red black tree to find which shared library the syscall
   was invoked from
5. Retrieve the relevant whitelist for the given shared libary
6. Check to see if the syscall is in the whitelist
7. (depending on config) warn, kill the process (sync) or kill all processes
   being followed (sync kill for compromised process, async for others)

## Implementation

### Frontend: Go
- CLI to allow for ergonomic loading
    - Benefit over seccomp: seccomp is a pain
- Load libc to addresses map (by parsing `/proc/PID/maps` in userspace)
- Parse whitelist and load to whitelists map 
- Contains code to listen to profiling ringbuffer (if enabled)
- Contains code to listen to the warn ringbuffer and either warns or kills all
forked processes as configured

### BPF/Go integration: `go2bpf`
- `bpf2go` is a pure go library which makes it easy to interop go with bpf
- Supports BPF CORE (compile once, run anywhere)
- Handles compilation of C to BPF bytecode and autogenerates structs and
handlers for maps in Go.

### BPF Maps
- Maps are used by BPF programs to store data. They are also accessible from
userspace by appropriately privileged users (by default, just root)
- Maps can be used to persist data between BPF program runs, and can be used for
  communicating with userspace. Unordered, not syncable. 
- Not thread safe - concurrent writes need to be explicitly guarded against
e.g. with a mutex, `__sync_fetch_and_add`, etc,.

### BPF Ringbuffers
- Used for message passing to/from userspace
- Thread safe

### BPF tracepoint
1. Finding PID, PPID, checking filter
    - `task` struct, `parent` struct
    - read `tgid` instead of `pid` as threads conceptually different in
    kernelspace
    - if PID not in fiter map, return
2. Fork following
    - If PPID in apply list, then add PID to apply list
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
   the whitelist bitmap. 0 <=> block, 1 <=> allow
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
- Providing spacial system call filtering mechanism for **statically linked**
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
   ```
