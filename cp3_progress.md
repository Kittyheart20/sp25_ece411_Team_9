In this report, we have implemented branching and memory instructions (load, store, and auipc), extending the functionality of our cpu model. 
We did this by introuducing a separate cache for data memory, appropriately arbitrating between the two caches to send requests to sram.

**Bugs**
- Differentiating between instruction and data memory
- Apply changes when flushing takes place and memory is accessed
- Memory read and write at the same time

**Contributions** \
Alex: \ I helped implement flushing and branching, as well as interface between instruction and data memory. 
Erin: \ I helped implement some of branching and some of memory as well as debugging
Sujin: 
