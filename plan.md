# Fine-Grained Linux System Call Filtering

## Abstract

## Introduction

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
- Very broad concept: can refer to harre-enforced isolation strategies e.g.
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
- `seccomp`
- Problem: too broad! Not designed with compartmentalisation in mind. Violates
principle of least privilege. 

### Processes
- Processes provide strong "_inter-application_" isolation

#### Address Space 
- Statically vs Dynamically linked executables
- Understanding `/proc/pid/maps`
- What does the address space look like under the hood
    - `vma_struct` red black tree
    - `file` struct

#### Process's stack
- What is an RP
- Stack frames

## Motivation
- Traditional system call filters are too broad
- Applications are large; `seccomp` doesn't adhere to principle of least
  privilege.
- Opportunity to secure applications by:
    - Defining system call permissions in terms of multiple filters
    - Have the scope of each filter limited to calls originating from a
    specified part of the process's address space

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
