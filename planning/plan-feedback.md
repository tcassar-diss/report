# Feedback

## Screencast/viva
- Make things as user friendly as possible
- Third Year student level
- Be honest with answering questions

### Latex
- File per chapter
- Ashpell, vim grammar rules, mother

## Report
- Core part is the design: has to start max. 1/3 of the way through the report
- Background should be **minimal**
- Add a conclusion

### General Feedback
- Start with overview, then zoom in
- Make nice diagram, then look at each step individually
- Design
    - Not massive amount on low level details
- Implementation
    - Can be heavy technical details wise

- Discussing graphs
    - Observations
    - Explanations
    - Conclusions

- Implementation: write number of LoC

## Questions
> Whitelist generation: Present as an evaluation tool? Or as a whitelist gen tool.
- (from pierre) could present early result as motivation
- nice to show that we knew that things would be good from the get go

- Present them as different tools;
    - No existing tools which do these things
    - Explain why `strace` 

- Static analysis
    - Procedural linkage table
    - List function from libc called by analysis table
- Otherwise write new tool and integrate as part of `addrfilter`

> Iteration Cycle and Present BPF Challenges?
- (from pierre) kernel level programming: difficult, fewer debug/profiling tools
- (from pierre) ebpf: very restricted constrained environment
- (from pierre) well placed in introduction

> CLI in design section?
- Important: how parameterisable is your tool? Less important is how to set them
- Focus should be on _reproducibility_: what does someone need to know if they
were to reimplement your code?


---
## Minutes 01/04/2025

- Things should flow: style written probably okay
- Design
    - 





