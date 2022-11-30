class Cache:
    tag_array = [-1 for i in range(64)]
    last_used_line = [-1 for j in range(32)]
    valid_dirty = [0 for k in range(64)]

    clk_cnt = 0
    miss_cnt = 0
    hit_cnt = 0

    def seek(self, addr, write=False):
        addr_set = addr % 32
        addr_tag = addr >> 5
        if self.tag_array[addr_set * 2] == addr_tag \
                or self.tag_array[addr_set * 2 + 1] == addr_tag:
            self.hit_cnt += 1
            where = int(self.tag_array[addr_set * 2] != addr_tag)
            self.clk_cnt += 4
            self.last_used_line[addr_set] = where
            if write:
                self.valid_dirty[addr_set * 2 + where] = 3
        else:
            self.miss_cnt += 1
            where = 0 if self.last_used_line[addr_set] == 1 else 1
            if self.last_used_line[addr_set] == -1:
                where = 0
            if self.valid_dirty[addr_set * 2 + where] == 3:
                self.clk_cnt += 100
            self.tag_array[addr_set * 2 + where] = addr_tag
            self.last_used_line[addr_set] = where
            self.valid_dirty[addr_set * 2 + where] = 2
            self.clk_cnt += 106


M = 64
N = 60
K = 32

a_begin_mem = 0  # 8 bits
b_begin_mem = M * K  # 16 bits - we should muliply index by 2
c_begin_mem = 2 * K * N + b_begin_mem  # 32 bits - multiply by 4

pa = a_begin_mem
pb = b_begin_mem
pc = c_begin_mem
cache = Cache()

for y in range(M):
    for x in range(N):
        pb = b_begin_mem
        cache.clk_cnt += 2
        for k in range(K):
            cache.seek((pa + k) >> 4)
            cache.seek((pb + 2 * x) >> 4)
            cache.clk_cnt += 5
            pb += 2 * N
        cache.seek((pc + 4 * x) >> 4, write=True)
    pa += K
    pc += 4 * N
    cache.clk_cnt += 2

print("Clock rate: ", cache.clk_cnt)
print("Cache hit rate: ", cache.hit_cnt / (cache.miss_cnt + cache.hit_cnt))
