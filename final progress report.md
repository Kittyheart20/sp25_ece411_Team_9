In this cp, we did several advanced features. We completed the C extension, a next line prefetcher, and a post commit store buffer with write coalescing, 
a hybrid predictor using gselect and a two level predictor. 

**Bugs**
- Updating PC value based on the branch prediction result and whether the instruction is from RV32C extension
- Deciding between memory cache or store buffer for memory access
- Resolving merge conflicts between new feature branches
- Block preemption (issuing a different instruction amid of the other) while implementing split lsq

**Contributions**\
Alex: \
Erin: \
Sujin: I improved reservation station with the parameterizable depth and efficient age-old instruction issuing. 
For new features, I worked on the C-extension and split lsq.
