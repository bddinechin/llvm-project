long add(long a, long b) {
  return a + b;
}

long sum_to_n(long n) {
  long total = 0;
  for (long i = 1; i <= n; i++)
    total += i;
  return total;
}

long clamp(long x, long lo, long hi) {
  if (x < lo) return lo;
  if (x > hi) return hi;
  return x;
}
