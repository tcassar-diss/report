# 3rd Year Thesis Report Structure

Suggested 'catchy' thesis title: `SentinelBoot`. The bootloader 'watches' over
what is booted and warns against it.

## Abstract

SentinelBoot is a demonstrative thesis to improve boot flow safety through both
memory safe principles and the Rust programming language supported by its
ownership, borrowing, and lifetime constraints; additionally, SentinelBoot uses
public-key cryptography to verify the kernel's hash, accelerated by the RISC-V
vector cryptography extension, before booting.

## Introduction

### Context

System software such as bootloaders are predominantly written in C in recent
years the headache of memory safety vulnerabilities has driven development away
from these unsafe languages; however, the nature of system software's high
performance requirements alternatives such as Java or Python have not been
viable. With the recent introduction of Rust it has become possible to phase out
C by putting tighter constraints on the source code.

### Problem

System software is one of the final frontiers which has not taken advantage of
memory safe languages due to performance overheads the Rust programming language
presents itself as a viable option.

### Motivation of the thesis

Memory safety is a persistent issue: a huge number of security bugs are caused
by memory errors and continue to arise during development in unsafe languages
such as C/C++, for example Apple’s goto fail bug. While there is significant
focus on preventing memory safety issues through means such as static code
analysis, MISRA standardisation, and address sanitisation, these means can only
go so far, and primarily focus on low-level dedicated microcontrollers. While it
can be reasoned whether unsafe code passes these checks, as the number of unsafe
lines increases it becomes more challenging to reason about the safety.
Therefore, problems begin to arise in being able to definitively reason about
the memory safety of larger Linux/SoC systems which interact with these
microcontrollers.

It is very difficult to reason about the safety of a system if the process which
initialises it is unsafe and susceptible to exploitation. As such, this thesis
will focus on the earliest stages of the bootflow before an OS/kernel is loaded.
RISC-V will be chosen as the target architecture, its open source nature allows
for supporting an OSS community. The thesis will form a demonstration of
minimising unsafe code lines without affecting functionality.

### Aims and objectives

- Using a minimal number of unsafe lines of code be able to
  - cryptographically verify a kernel at runtime
  - cryptographically verify a kernel at runtime using vector cryptography
  - boot Linux produced by a standard toolchain
  - communicate current operations through a serial console
  - produce a resulting binary which is of a sensible size proportional to the
    subset of features
  - produce a project structure which employs good practices for scalability
    and maintainability

### Evaluation strategy

Resulting binary will be inspected to determine the composition and the
relative sizes of crates and libraries which form it comparing to similar OSS
implementations to ensure ability to operate under the same constrained
conditions.

Binary will be compared against established OSS bootloaders to determine
booting overhead particularly with verification further the data will be
analysed to determine standard deviation in results (performed both in emulation
and on hardware) to ensure ability to perform its task within viable time
difference.

Finally to determine the overhead from hashing by varying the size of the kernel
to be verified by compiling in modules.

### Success criteria

- Successfully boots Linux
- Resulting binary is < 700kB (approximate size of u-boot)
- Resulting binary is able to execute in < 3 seconds
- Successfully able to execute on both hardware and under emulation

### Outline

The background research will outline the required concepts to motivate the
development work and related work. The methodology will be split into three
sections describing and discussing the development work to transition from
machine code to unsafe Rust, unsafe Rust to safe Rust, and booting a verified
digitally signed kernel. The evaluation will assess to what extent SentinelBoot
achieves the success criteria. Finally, the contributions are summarised and
final remarks given on the weaknesses within SentinelBoot and future work to
improve upon them, with an ending reflection on the development work.

## Background research

### Memory Safety Principles

- Explain what memory safety is as a principle

- Overview key aspects of memory safety (1 sentence per bullet point)
  - Validating memory accesses. Mention result of invalid accesses such as
    undefined behaviour, segfaults, and data leaks.
  - Memory leak prevention. DoS style resource usage. Improperly deallocated
    memory can leak cryptographic keys etc.
    - Mention locks, mutexes, and atomic operations to define shared resource
      behaviour
  - Null pointers - mentioning they can lead to crashes or undefined behaviour.
  - Dangling pointers - mentioning they can lead to crashes or undefined
    behaviour.
  - Mention memory integrity protection measures including ROM, MPK, ASLR, Stack
    Canaries, and address sanitisation.

- Briefly explain common vulnerabilities (around 2 sentences each with an
  accompanying diagram) including buffer overflows, use-after-frees, and data
  races.

### Rust

- A little overview of the syntax of Rust vs C (1-2 sentences + side-by-side
  code snippet of Fibonacci sequence to demonstrate) commenting on how the
  syntax is similar but note the additional control specified within Rust such
  as mutable and non-mutable borrows as well as fixed size array parameters.

- (2 paragraphs) Comment on the memory safety of the two languages
  - C is infamously memory unsafe but allows developers to do what they want and
    not fight the compiler (trading for debugging efforts) ultimately part of
    C's success
  - Mention Rust is really two languages a safe and an unsafe one
    - Using solely unsafe is no different, safety wise, to writing C
    - Using solely safe vastly reduces the probability of common memory
      vulnerabilities
    - Explain the key principles of Rust: ownership, borrowing, and lifetimes
      - Ownership is the idea that a piece of memory has an owner and can only
        have one owner at a time
      - Borrowing is the idea that multiple pieces of code can have access to a
        memory location but only one can have mutable (edit) access at a single
        moment
      - Lifetimes is the idea a piece of memory has a fixed lifetime either
        static for the whole of runtime or constrained to specific scopes
        allowing Rust to avoid using a garbage collector.
  - Mention Rust can often feel like 'fighting' the compiler and brings a lot of
    development process into the up front design rather than a more agile
    approach which C allows (this difference in approach will be linked back to
    in the reflection)

- Present small code snippets of C and Rust demonstrating how to achieve common
  vulnerabilities commenting on the clear points where the Rust programming
  language is trying to prevent such behaviour (side-by-side code snippet +
  sentence of comparison per bullet point)
  - Buffer overflow
  - Function pointer overflow

### RISC-V

RISC and CISC are both fundamental CPU architectures. RISC adheres to the
principle of simplicity and regularity in its instruction set design; CISC, in
contrast, focuses on providing a diverse and feature-rich set of complex
instructions.

RISC-V is an open-source Instruction Set Architecture (ISA), based on RISC
principles utilising extensions such as vector and multiplication operations.
RISC-V has gained adoption in industry/academia due to x86_64/ARM requiring
licenses and royalty payments.

(An example very simple assembly program snipped such as multiplying two numbers
for both to show many simple instructions vs one large complex instruction)

### Bootflow and its safety

- (2 sentences total) Briefly explain what a first-stage bootloader is
  - One of two standards locates it in the MBR
  - Examples BIOS, coreboot, and libreboot
  - Load second-stage bootloader
- (2 sentences total) Briefly explain what a second-stage bootloader is
  - Load operating system, setup hardware state, and transfer execution to it
  - Can include functionality including choosing which operating system or
    booting into safe mode
  - Examples GNU GRUB, BOOTMGR
- (1 sentence + diagram) Provide an overview of the Linux boot process
  - BIOS -> First-stage bootloader -> Second-stage bootloader -> Kernel -> Init
- (1 sentence) Comment on the fact coreboot is 94% C, MBR is 99.4% assembly, GNU
  GRUB is 91.9% C (taken from GitHub)

### Memory safety exploits

- Build upon previous memory safety sections, now more context is given, to
  discuss relevant exploits building a chain of vulnerabilities from CPU to
  system software (reinforces the point about safe is useless if no chain of
  safety so all areas of software need to be targeted)
  - (2 sentences + diagram) Look at and briefly explain CPU memory exploits
    essentially discuss the Meltdown and ZenBleed CPU exploit.
  - (2 sentences) Look at and briefly explain BIOS level exploits including
    difficulty to detect and treat mentioning the NSA's DEITYBOUNCE and LoJax
  - (1 sentence) Mention due to the very small size of MBR they're not often
    targeted and usually only exploited by social engineering to modify it once
    booted
  - (2 sentences) Look at and briefly explain second-stage bootloader exploits
    including a CVE in GRUB which allowed secure boot protection bypass
- (1 sentence) Explain software is difficult to trust due to scope of attack
  surface and explain how Rust is viable to reduce the area which is ultimately
  beneficial to all

### Existing codebases

A fairly small chapter about 2 paragraphs long briefly explaining what u-boot
and TF-A are and what they do.

- U-boot is an open-source bootloader commonly used in embedded systems. Mention
  (rust-osdev's) bootloader which is an experimental Rust x86 bootloader to show
  lack of Rust support for RISC-V.
- TF-A is an open-source bootloader and firmware framework designed for
  Arm-based systems designed to initiate a secure boot process, ensuring that
  only authenticated and trusted code is executed during system startup.

## Methodology

### Threat Model

- Explain the use case as a secure boot implementation for remote kernels e.g.
  over the air updates
- Explain the concept of man-in-the-middle attacks and its relevance here.
  Discussing how the digital signature verification mitigates this attack
  vector.
- Explain the vulnerability presented by social engineering to manipulate the
  end user to point to the incorrect malicious server nullifying this protection
- Mention about hardware root of trust and the limitations it has by
  requiring modern hardware and not having support on RISC-V for technologies
  such as TPM

### Starting point

- Overview the tutorials and resources used to create the project starting
  point, citing any relevant

### CI/CD

A fairly small chapter about 1 paragraph long briefly the benefits of CI/CD in
the development process to enforce standards and ensure old features are not
broken.

### 'Tools of the trade'

- Explain QEMU is a highly customisable emulator allowing binary translation to
  the host's ISA from a range of different hardware targets
  - QEMU can emulate its own hardware including network cards, serial ports,
    and CAN interfaces.
  - Used to emulate a full RISC-V system allowing for much faster development
    cycles
- Explain why a Raspberry Pi is used. As a rig controller for the VisionFive 2
  RISC-V board. The Raspberry Pi is connected to the VF2 board with ethernet,
  serial (UART), and through a relay.
- Provide an overview of what Docker is. An open-source containerisation
  platform used to create a consistent build environment for the bootloader
  across the multiple machines which build it including MacOS, Arch Linux, and
  Raspbian.

## Methodology - assembly to Rust

For the key `- {part}` sections it is fairly hard to write them in this form so
they're likely briefer than the final result this is largely as the single
sentence 'explains' are complex and require detailed explanations and diagrams.

### Explaining Rust switch

- Outline linking allows forming a single executable binary and allows boot
  assembly to be linked in
  - Explain the linking process and how an LD script formats the binary with
    sections, stack, and heap addresses
- Describe the initial assembly where execution starts how it sets up the HARTs,
  control and status registers, and initialises BSS.
- Describe how the trap vector is set, return address is set, parking loop, and
  jump to unsafe rust function
- Discuss U-boot running in supervisor mode so the need for two sets of assembly
  instructions to reach Rust one machine mode and one supervisor mode
  - Explain why this decision was made to prevent the need to write another
    driver to perform tftp (ethernet) this will be one of the large points
    mentioned in reflection/future work

### GDB, JTAG, and OpenOCD

- Briefly explain what GDB is and its role in the development process. Offers
  memory examination tools, allowing the examination of the contents of
  different memory locations and processor control including stepping.
- Briefly explain what JTAG is a hardware interface standard primarily used for
  testing and debugging integrated circuits. Allowing for the halt of the
  execution of a processor, inspecting the memory contents, setting breakpoints,
  and stepping through code instructions providing invaluable insights into the
  system's behaviour.
- OpenOCD open-source tool serves as a bridge between the development
  environment and the hardware, enabling interaction with and control of on-chip
  debugging and programming features
- Walk through debugging transition with the three technologies.

## Methodology - unsafe Rust to safe Rust

### Explain serial driver

- Brief mentioning of common standards including 115200n8 and what the frames
  look like
- Look at the MMIO registers, their meanings, and initialisation
- Explanation of MUTEX wrapper around MMIO drivers
- Debugging serial driver for real hardware poor documentation made it difficult
  to decipher the difference between the two and what was wrong had to change
  the board to one with better documentation

### Explain global memory allocation

- Explain writing a global allocator
  - Two mutable borrows to the same object problem e.g. doubly linked list
- Explain how alloc and dealloc were performed with allocation flags
  - Explain the decision to zero dealloced regions to prevent data leaks
    including the flush before kernel execution
- Explain doubly linked list advantage of being able to amalgamate allocations
- Explain the Rust `unsafe impl GlobalAlloc for`

### Explain Unsafe Rust to Safe Rust Switch

- Provide an overview of drivers, board specific values, and memory allocators
  are initialised
- Explain now drivers and allocation are initialised we have no need to stay in
  unsafe branched to by assembly so - largely symbolic - branch to safe Rust.

## Methodology - booting Linux

### Ghidra

- Explain what it is.
  - It includes a disassembler, decompiler, and a variety of analysis tools.
- Explain how it was possible to monitor the processor through the kernel boot
  identifying assembly instructions using GDB which either sent the process to
  an infinite loop or were illegal
- Working with Ghidra it was possible to identify which check failed and
  implement the fix

### Booting the Linux Kernel

- Explain the kernel booting requirements a0 and a1 to contain the address of
  the device tree binary (DTB) in memory and the hartid respectively
- Explain a DTB is a data structure used in the boot process and serves as a
  description of the hardware components present in the system. DTB is a
  compiled data structure originating from a Device Tree Source file. Explain
  because of this the additional flags were compiled into the kernel to prevent
  the need to implement a DTB decompiler and DTS compiler.

### Kernel hashing

- Explain using SHA256 (and why SHA256) to hash the kernel
- Explain how using public key cryptography and the hash we can verify a digital
  signature verifying the authenticity of the kernel and its origin

### Vector Cryptography

- Explain what it is and make parallels to other SIMD architectures
- A brief overview of the assembly code required and a brief overview of SHA256
- Explain its relevance and in place replacement to the serial version
- Working around no assembler/compiler support for vector cryptography but using
  pre-assembled instructions
- Debugging incorrect serial hash implementation while also debugging the vector
  cryptography implementation

## Evaluation

### Boot Time

- Evaluate the time taken for hardware end to end booting directly with u-boot
  as a baseline
  - Compare this figure with a minimal kernel using SentinelBoot to measure
    overhead
  - Compare this figure with a three different size kernels using SentinelBoot
    to measure hashing overhead
- Reason about hardware end to end booting directly with u-boot and the effects
  of varied kernel sizes compared to SentinelBoot
  - How does SentinelBoot scale with kernel sizes and where does this stem from
- Evaluate the time taken for QEMU end to end booting directly with u-boot as a
  baseline
  - Compare this figure with a minimal kernel using SentinelBoot to measure
    overhead
  - Compare this figure with a minimal kernel using SentinelBoot to measure
    vector cryptography overhead
  - Compare this figure with a three different size kernels using SentinelBoot
    to measure hashing overhead
  - Compare this figure with a three different size kernels using SentinelBoot
    to measure vector cryptography hashing overhead
- Reason about QEMU end to end booting directly with u-boot and the effects of
  varied kernel sizes compared to SentinelBoot
  - How does SentinelBoot scale with kernel sizes and where does this stem from
  - How does the vectorised version of QEMU affect runtime speeds is this
    comparable and if not why not
- Reason and predict about vector cryptography performance on real hardware with
  a potential benchmark of a serial program and a vectorised program running on
  hardware

### Size

- Perform a brief analysis and evaluation of the generated binary comparing its
  size with other relevant bootloaders and determine the constitution of the
  binary.

### Compile Time

- Perform a brief analysis and evaluation of the compile time and what is
  responsible for the time taken. (Due to Rusts static analysis checks it has a
  bit of a bad reputation for compile times.)

### Security

- Perform an analysis and evaluation of the security offered by the bootloader
  and determine the viability of varied attacks such as MITM and social
  engineering

### Memory Safety

- Perform an analysis and evaluation of the bootloader source code and reason
  about the unsafe line count and the general principles employed to improve
  memory safety including mutexes, locks, null pointers, and memory allocation

## Summary and conclusions

### Boot Time Summary

- Summarise the hardware end to end booting is it within the range of the
  success criteria and how well was it done? What future work would improve it?
- Summarise the QEMU end to end booting is it within the range of the success
  criteria and how well was it done? What future work would improve it?

### Size Summary

- Reason about the constitution of the binary is it within the range of the
  success criteria? and potential to minimise it through future work improving
  software structure

### Compile Time Summary

- Summarise the compile time analysis of the binary is it within the range of
  the success criteria? and potential to minimise it through future work
  improving software structure

### Security Summary

- Summarise about security vulnerabilities in the code base and from the model
  is it acceptable? and what future work that could refine or minimise these
  problems

### Memory Safety Summary

- Summarise the memory safety including mutexes, locks, null pointers, and
  memory allocation in the code base and from the design is it acceptable? and
  what future work that could refine or minimise these problems

### General summary

- Express to what degree was SentinelBoot a success from both a technical and
  educational front. Answering the following questions: Were success criteria
  met? What is the scale of future work? Is SentinelBoot scalable and well
  developed?

## Reflection

- What I would've done differently
  - Add similar to support such as writing a serial driver for a much more well
    defined board with good documentation and open source support such as a
    raspberry pi before diving into SentinelBoot development
  - Given up with the VisionFive 2 earlier and switched the HiFive Unmatched
    which had a JTAG port for debugging the serial console rather than debugging
    through documentation and reasoning
- If I had more time I would've implemented the ethernet driver to allow tftp
  directly with no u-boot intermediate but as one driver had already been
  written it was not beneficial
- Largest goal of SentinelBoot was to learn and I did with RISC-V assembly,
  Linux booting, binary analysis, Rust, and drivers.
- Lots of difficult new concepts involved within SentinelBoot including DTB,
  JTAG, and UART. These concepts are very ingrained in projects and often not
  talked about that extensively so tutorials/blogs are much harder to come by.
- Discuss the difficulties of the Rust programming language in this style of
  project. This includes shared references, lifetimes, and error handling which
  make the upfront requirements much harder which for already difficult concepts
  slows down agile/fail-fast development.
