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
- Abstract

## Introduction

> **SECTION PURPOSE**: Convince the reader that addrfilter is needed
>
> - What does `addrfilter` do?
> - Why is `addrfilter` needed?
> - Preliminary findings: how well does `addrfilter` perform versus alternatives
> - How was `addrfilter` implemented?

### What is `addrfilter`

- Security tooling built for Linux based on a **novel approach**
- Will kill an application if it makes a **system call** it isn't allowed to
  make.
- Novel approach: fine-grained filtering based on **process address space**

### Why is syscall filtering needed?

- Bring up that state of the art is `seccomp`!
- Seccomp defines one global filter for an application.
- Applications are getting constantly bigger in terms of LoCs

  - => (legitimately) needs access to more system calls
  - => seccomp filters must be more permissive, therefore less restrictive

- TODO: find real world exploit

### Does `addrfilter` work?

- Yes. Depending on what you're doing, its probably the sensible choice over
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

## Background

> **SECTION PURPOSE**: Introduce the reader to concepts they need to understand
> to understand `addrfilter`; show that existing solutions are outdated

TODO: replan on rewrite!

- Syscalls
- Compartmentalisation and why its relevant
- BPF
- Seccomp

### Bridge to design

- We’ve now seen why syscall filtering is necessary, how it’s currently done, and where existing solutions fall short.
- These limitations directly informed the design goals of `addrfilter`.
- The next section explains how these challenges were addressed through a focused, minimalistic, and precise design.

## Design

> **SECTION PURPOSE**: Justify requirements, argue that `addrfilter` is the
> simplest product which will fulfil these requirements.

## Implementation

> **SECTION PURPOSE**: Give the reader a detailed enough decription of the
> system for reimplementation.

## Evaluation

> **SECTION PURPOSE**: Show how well `addrfilter` achieves its goals; show it's
> value vs seccomp, and talk about where to use each solution
>
> - Security goals
> - Performance goals
> - Syscall frequency: indicator of slowdown

## Related Works

> **SECTION PURPOSE**: Argue that `addrfilter` is **novel**; show where it fits
> within state of the art.

## Conclusion

**SECTION PURPOSE**: Talk about what `addrfilter` has achieved and what still
needs doing.
