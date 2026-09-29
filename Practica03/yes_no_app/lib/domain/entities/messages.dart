enum FromWho {
  origin,
  destiny
}

String formatMessageTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool isToday(String date) {
  final parts = date.split('/');
  if (parts.length != 3) return false;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return false;

  final messageDate = DateTime(year, month, day);
  final now = DateTime.now();
  return messageDate != null &&
      messageDate.year == now.year &&
      messageDate.month == now.month &&
      messageDate.day == now.day;
}

class Message {
  final String text;
  final String? imageUrl;
  final FromWho fromWho;
  final String time;
  final String date;

  Message({
    required this.text, 
    this.imageUrl, 
    required this.fromWho,
    required this.time,
    required this.date
  });
}