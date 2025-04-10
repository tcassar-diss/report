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
> - How was `addrfilter` implemented?
> - How well does `addrfilter` perform versus alternatives

## Background

> **SECTION PURPOSE**: Introduce the reader to concepts they need to understand
> to understand `addrfilter`; show that existing solutions are outdated

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
