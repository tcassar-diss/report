# Minutes 13/03/2025

## Work done over last week

- [ ] Read [Benchmarking Crimes](https://gernot-heiser.org/benchmarking-crimes.html)
- [ ] Rethought benchmarking approach (see below)
- [ ] Static Analysis Attempts:
    - [ ] `bside`: played around with...
    - no trivial way to get per-lib whitelists
    - any other SAs to recommend?

- [ ] Ran more benchmarks
  - [ ] Redid SQLite benchmark to be more fair
  - [ ] Stressed system by running nginx on
    - More threads
    - Loaded as many modules as possible to grow VMA space
  - [ ] HAProxy
  - [ ] NPB Benchmark
  - [ ] fio 

## Static Analysis Feasibility

- How to pull narrow whitelists for libs?
    - Could use `bside/shared_interface.py` to pull .so whitelists?
    - Doesn't help: {shared interface} INTERSECT {whitelist} doesn't work...
    would go back to general seccomp filter?


1. Can you get the full list of syscalls for a library
    - Lots of symbolic execution

    - Confine, bside, sysfilter
    - Look at sysfilter: works well on dynamic executable

2. Take 6 hours or so to investigate what can do with bside;
   
- Angr by itself identifies ~90% of syscalls
    
---
### Benchmarking Crimes

- Selective benchmarking
  - Choose from wide range of benchmarks
    - Caveat: don't include irrelevant benchmarks as they can only weaken evaluation
      - i.e. any performance degradation is bad

  - Compare against state of the art alternative
    - Compare against `seccomp`, not native system!
    - Will make numbers better anyway

  - Push to the point of degradation
    - `nginx`, more threads (stresses `ringbuf` lock) and more entries in `vma`
       tree

  - Report all numbers with statistical significance
    - Run everything (with different data) 3(?) times, report with standard 
      deviation at minimum

- Userland system call filtering system...

---
## Producing a good benchmark
- Compare to nothing, `seccomp`, `addrfilter`, and report results of 
  benchmarks
- Don't talk about overheads: instead talk about slowdown
  - Dishonest to discuss overheads: only fair if CPU usage was 100% in both 
    cases
  - Report numbers with CPU utilisation <======= ::ASK PIERRE: seems like a mild pain; really necessary?

- Not the case here... don't bother with cpu usage!

## Notes from meeting

- Where to go this week
    - Better benchmarks? (boring but feels like best value for money)
    
---
## Writing the report

### Report

- Write detailed outline before next week

- More detailed => more help!
- Once written, Pierre can "browse" but not a detailed pass

- Bring to tuesday of week after

- Sections
    - Abstract
        - Condensed version of Introduction
    - Introduction
        - Key to report
        - Reader must be convinced that reading report is worth the time
        - Halo effect: good first impression <=> good mark
        - Superset of Blackboard:
            - *Blackboard
            - Contextualise things
            - **Research problem**: (very important to get right)
                - Syscall filtering is very useful
                - Compartmentalisation is very useful
                - Typical syscall filtering is not compartmentalisation aware
                  and sees the program as a monolithic unit of trust
                - This is too coarse grained
            - Motivate the work - why is research problem important
            - Challenges
                - Why are research problems difficult to solve
            - Timeliness(/importance) of work: this is a current problem in the field
            - Solution (your contribution)
            - (Outline)
    - (Motivation)
    - (Background) (amount of backgd info that reader needs to understand report)
    - Design
    - Implementation
    - Evaluation
    - Related Works (sometimes same as background, often different)
        - Work that has tried to answer the same questions
        - Talk about how different and novel your work is.

- Be careful about claims made early in the report
    - Each claim needs to be backed up!

- Spend 3hrs or so on this part...

### Screencast

### Q&A
- Reuse slides from screencast


