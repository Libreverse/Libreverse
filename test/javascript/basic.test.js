describe('Basic Jest functionality', () => {
  test('basic test works', () => {
    expect(1 + 1).toBe(2);
  });
  
  test('async test works', async () => {
    const result = await Promise.resolve(42);
    expect(result).toBe(42);
  });
}); 