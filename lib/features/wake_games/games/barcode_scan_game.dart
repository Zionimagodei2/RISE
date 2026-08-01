class BarcodeScanGame { const BarcodeScanGame(); bool validate(Object input) => input is String && input.trim().length >= 8; }
