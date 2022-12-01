class Cache:
    tag_array = [-1 for i in range(64)]
    last_used_line = [-1 for j in range(32)]
    # valid_dirty[i] contains two bits - valid = [i][1], dirty = [i][0]
    valid_dirty = [0 for k in range(64)]

    clk_cnt = 0
    miss_cnt = 0
    hit_cnt = 0

    # method that seeks for cache-line
    def seek(self, addr, write=False):
        # set & tag
        addr_set = addr % 32
        addr_tag = addr >> 5
        # we need time to send the address and command
        self.clk_cnt += 2
        # looking for tag
        if self.tag_array[addr_set * 2] == addr_tag \
                or self.tag_array[addr_set * 2 + 1] == addr_tag:
            self.hit_cnt += 1
            where = int(self.tag_array[addr_set * 2] != addr_tag)
            self.clk_cnt += 4
            self.last_used_line[addr_set] = where
            if write:
                self.valid_dirty[addr_set * 2 + where] = 3

            # time to send the responce
            if write:
                self.clk_cnt += 2
            self.clk_cnt += 2
        else:
            # we missed, so we go to the memory
            self.miss_cnt += 1
            where = 0 if self.last_used_line[addr_set] == 1 else 1
            if self.last_used_line[addr_set] == -1:
                where = 0
            if self.valid_dirty[addr_set * 2 + where] == 3:
                self.clk_cnt += 100
            self.tag_array[addr_set * 2 + where] = addr_tag
            self.last_used_line[addr_set] = where
            self.valid_dirty[addr_set * 2 + where] = 2
            # time from cpu command to mem responce
            self.clk_cnt += 106
            # time to responde whole cache-line into cache
            self.clk_cnt += 8
            # time to responde to cpu
            self.clk_cnt += 2


M = 64
N = 60
K = 32

# setting the indexes of array's beginnings in memory
a_begin_mem = 0  # 8 bits
b_begin_mem = M * K  # 16 bits - we should multiply index by 2
c_begin_mem = 2 * K * N + b_begin_mem  # 32 bits - multiply by 4

# initializing pointers
pa = a_begin_mem
pb = b_begin_mem
pc = c_begin_mem
cache = Cache()

for y in range(M):
    for x in range(N):
        pb = b_begin_mem
        for k in range(K):
            # when multiplying, we should pick pa[k] and pb[x] from memory
            cache.seek((pa + k) >> 4)
            cache.seek((pb + 2 * x) >> 4)
            cache.clk_cnt += 5
            pb += 2 * N
        cache.seek((pc + 4 * x) >> 4, write=True)
    pa += K
    pc += 4 * N


print("Misses: ", cache.miss_cnt)
print("Hits: ", cache.hit_cnt)
print("Clocks: ", cache.clk_cnt)
print("Cache hit rate: ", cache.hit_cnt / (cache.miss_cnt + cache.hit_cnt))