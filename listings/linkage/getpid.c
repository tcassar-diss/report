#include "getpid.h"

#include <unistd.h>

// use two functions to make the stack a bit deeper;
// no functional difference, just another step of verification.

pid_t internal() { return getpid(); }

pid_t wrap_getpid() { return internal(); }
