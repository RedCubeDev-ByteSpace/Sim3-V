

void __atomic_thread_fence(int memory_order) {
    // A full memory fence instruction for x86/x64
    __asm__ volatile ("mfence" ::: "memory");
}
