## Related Works (1500 words)

> **SECTION PURPOSE**: Argue that `addrfilter` is **novel**; show where it fits within state of the art.

### The state of **system call filtering**

#### Works motivating system call filtering

- Early approaches involved user-mode techniques; e.g. tracing `/proc`.
- **Janus**: early (1999) influential hybrid scheme, leveraged `ptrace`
  - addrfilter also leverages ptrace to an extent (`pt_regs`)
- Systrace: userspace/kernelspace hybrid syscall filter; gave the user a lot of control over policies, including features like UID-specific allow lists.
- Widespread adoption motivates automated tooling: e.g., `seccomp` used by Chromium `(Google [19])`, OpenSSH `(OpenSSH [36])`, Qemu `(Qemu [39])`, Docker `(Docker [16]/gVisor [20])`, Android `(Lawrence [27])`, Desktop (Flatpak `[15]`, Firejail `[13]`).

#### The challenge: building whitelists

- Gold standard: static analysis
  - Early example: `(Wagner & Dean [47] - static analysis for intrusion detection)`
  - SysFilter `(DeMarinis '20 [11])` - Binary focus, unwinding info, use-define chains, wrapper issues.
  - B-Side `(Th�venon '24 [This paper])` - Binary focus, symbolic exec, wrapper heuristic.
  - Chestnut `(Canella '21 [6])` - Binary focus, simpler analysis than B-Side, limited wrapper handling.
  - Confine `(Ghavamnia '20 [16])` - Automated policy generation for containers via static analysis.
  - Pailoor et al. `(Pailoor '20 [37])` - Automated policy synthesis via static analysis/program synthesis.
  - Saphire `(Bulekov '21 [4])` - Static analysis for PHP allowlists.
  - C2C `(Ghavamnia '22 [18])` - Configuration-driven static analysis for filtering.
  - SA issue with addrfilter: no tooling exists atm; lots of engineering effort to do. Not as simple as taking the intersection of main binary syscalls and shared library syscalls!
- Dynamic analysis:
  - Not a gold standard (coverage issues leading to false negatives).
  - Examples: `(strace)`, `(Mutz '06 [34] - anomalous detection)`, `(Wan '17/'19 [48, 49, 50] - mining sandboxes for containers)`, `(Hofmeyr '98 [22] - sequence-based detection)`, `(Warrender '99 [51] - alternative models)`.
  - Unsuitable for a production use case for generating _complete_ whitelists.
  - However, **good enough** to prove the efficacy of `addrfilter` (orthogonal work for evaluation).
  - Used in papers in well-renowned conferences (e.g. made up part of SysPart `(Rajagopalan '23 [40])`, used for validation in SysFilter `[11]`, B-Side `[This paper]`, Chestnut `[6]`).

#### Novel Syscall Filtering Implementations & Finer Grained Control

- Syspart `(Rajagopalan '23 [40])`: a different take on a "fine grained" approach - _temporal_ specialization.
  - Idea is that server applications exhibit different set of syscalls on startup vs during steady state.
  - Syspart builds on other works like Temporal Specialization `(Ghavamnia '20 [17])`.
- SysXCHG: dynamically swap syscall lists based on `execve`; restrict privileges of child processes!
- Optimus (2024): further isolate containers from hosts by introducing a runtime filtering policy (use this to reference limitations).
- Focus on eBPF for implementation/programmability:
  - `addrfilter` uses eBPF.
  - Jia et al. `(Jia '23 [24])` - Programmable System Call Security with eBPF. (Compare/contrast _how_ eBPF is used).
- Alternative dimensions - Syscall Flow Integrity:
  - SFIP `(Canella '22 [5])` - Coarse-grained syscall flow integrity.
  - BASTION `(Jelesnianski '23 [23])` - Control-flow integrity related to syscalls.
- A lot of work looking at application of principle of least privilege;
  - Work doesn't always link itself to **software compartmentalisation**, but addrfilter does.

#### Software Compartmentalisation

- Software: application of principle of least privilege `(Saltzer JH, Schroeder MD - original PoLP paper)`.
- Backends
  - CHERI capabilities (Arm Morello, CheriBSD)
  - Intel MPKs/PKU
    - Jenny `(Schrammel '22 [44])` - Securing syscalls specifically for PKU systems.
- Applications
  - Containing memory safety issues (Tolerating Malicious Device Drivers in Linux)
  - Sandboxing untrusted third parties (SoK: Lessons Learned from Android Security `[1] in your dissertation references`)
  - Sandboxing unsafe part of languages (Intra-Unikernel Isolation with Intel Memory Protection Keys `[35] in your dissertation references`)
  - Thwarting supply-chain attacks (BreakApp) and side-channels (Mitigating Information Leakage Vulnerabilities) ,
- Intersection with applications of syscall filtering; therefore, sensible to describe syscall filtering as part of the wider paradigm.
- Furthermore, describing as part of the paradigm makes connections to previous works easier to see; combining syscall filtering with something like CheriBSD allows for the design of systems like addrfilter.

#### Justifying that addrfilter is novel

- Seen the state of the art in syscall filtering:
  - Static/dynamic whitelist generation `(SysFilter [11], B-Side [This paper], Chestnut [6], Confine [16])`.
  - Temporal/event-based dynamic policies `(SysPart [40], Ghavamnia [17], SysXCHG)`.
  - Container focus `(Confine [16], Optimus)`.
  - Flow integrity `(SFIP [5])`.
  - **Gap**: No one has explicitly restricted by _address space compartments_ (shared libraries/VMA regions) as the primary filtering dimension.
- Addrfilter is relevant: obvious trend in the literature to look at tightening syscall lists (SysXCHG, SysPart, Confine `[16]`, etc.).
- Addrfilter has a unique place in explicitly bridging the gap between **software compartmentalisation** (spatial isolation) and **system call filtering**, providing something new to the research community.

#### Addrfilter's limitations

- Optimus argues for the importance of filtering as relating to containers
  - Specifically poised to look at breakouts.
- Docker: container market share of 87% `(https://6sense.com/tech/containerization/docker-market-share)`
  - Containers run by default with a (very permissive) seccomp filter enabled `(Docker [16])`.
  - Containers are an extremely favourable deployment mechanism for production code; as of time of writing, addrfilter doesn't support filtering from code run in containers. (Contrast with container-focused work like Confine `[16]`).
- Reliance on dynamic analysis for _evaluation_ whitelist generation (though justified).
- Potential soundness issues inherited from binary analysis tools `(Angr [2, 45])` or wrapper heuristics (as discussed in B-Side `[This paper, Section 4.6]`).



---

You need a proper conclusion chapter that will:
- recontextualise and remotivate the researhc problem tackled
- brieflly summarise your solution and its evaluation
- optionally present some of the limitations of the current prototype
- optionally include some critical reflection
- and list avenues for future works
