class PromptPayQrGenerator {
  /// Generates the raw PromptPay payload string for a given ID and amount.
  /// [id] can be a phone number (09xxxxxxxx) or ID number.
  /// [amount] is the payment amount in THB.
  static String generate(String id, double amount) {
    // 1. Prepare formatting for ID
    String targetId = id.replaceAll('-', '').replaceAll(' ', '');
    // If phone number starts with 0, convert to 66 format segment
    if (targetId.length == 10 && targetId.startsWith('0')) {
      targetId = '0066${targetId.substring(1)}';
    }

    // 2. Build segments (EMVCo format)
    // Payload Format Indicator
    String payload = _tag('00', '01');
    // Point of Initiation Method (12 = Dynamic, 11 = Static)
    payload += _tag('01', '12');

    // Merchant Account Information (PromptPay)
    String merchantInfo = _tag('00', 'A000000677010111'); // AID
    // PromptPay ID (Phone/BotID)
    // Tag 01 for Mobile Number, Tag 02 for Tax ID / Bill Payment
    // My logic: If it's a phone-like number (starts with 0066 or 0), use 01
    String idTag = (targetId.startsWith('0066') || (targetId.length == 10 && targetId.startsWith('0'))) 
        ? '01' 
        : '02';
    merchantInfo += _tag(idTag, targetId);
    
    payload += _tag('29', merchantInfo);

    // Country Code (TH)
    payload += _tag('58', 'TH');
    // Currency (764 = THB)
    payload += _tag('53', '764');
    // Amount
    payload += _tag('54', amount.toStringAsFixed(2));

    // 3. CRC calculation (Last tag 63)
    payload += '6304';
    payload += _calculateCrc(payload).toRadixString(16).toUpperCase().padLeft(4, '0');

    return payload;
  }

  static String _tag(String tag, String value) {
    return tag + value.length.toString().padLeft(2, '0') + value;
  }

  /// CRC-16/CCITT-FALSE
  static int _calculateCrc(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      int char = data.codeUnitAt(i);
      crc ^= (char << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }
}
