class SequenceTapGame { const SequenceTapGame(); bool validate(Object input) => input is List<int> && input.length >= 4 && input.every((value) => value >= 0); }
