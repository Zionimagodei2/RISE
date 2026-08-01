class MemoryGridGame { const MemoryGridGame(); bool validate(Object input) => input is List<int> && input.join(',') == '1,3,5,8'; }
