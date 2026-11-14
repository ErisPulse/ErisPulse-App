// 消息文本解析：bytes repr / OneBot 段 JSON / CQ 码混排 / 纯文本 → 消息部件。
// 对齐 Dashboard transcript.js 的 _trFormatMessageText 管线。

import 'dart:convert';

sealed class MsgPart {
  const MsgPart();
}

class MsgText extends MsgPart {
  const MsgText(this.text);
  final String text;
}

class MsgImage extends MsgPart {
  const MsgImage.network(this.url) : dataUri = null;
  const MsgImage.inline(this.dataUri) : url = null;

  /// http(s) 图源
  final String? url;

  /// base64 data URI 图源
  final String? dataUri;
}

class MsgPlaceholder extends MsgPart {
  const MsgPlaceholder(this.label);
  final String label;
}

class MsgAt extends MsgPart {
  const MsgAt(this.qq);
  final String qq;
}

class MsgReply extends MsgPart {
  const MsgReply(this.quoted);
  final String quoted;
}

class MsgLink extends MsgPart {
  const MsgLink(this.url, this.label);
  final String url;
  final String label;
}

class MsgCard extends MsgPart {
  const MsgCard(this.title, this.desc);
  final String title;
  final String desc;
}

/// 主入口：任意形态消息文本 → 部件序列
List<MsgPart> parseMessageParts(String? raw) {
  final text = raw ?? '';
  if (text.isEmpty) return const [];
  if (_looksLikeBytesRepr(text)) return _renderBytesRepr(text);
  final segs = _tryParseSegments(text);
  if (segs != null) {
    return [for (final seg in segs) ..._renderSegment(seg)];
  }
  if (text.contains('[CQ:')) return _renderCq(text);
  return [MsgText(text)];
}

// ── bytes repr ──

const _bytesMagic = [
  [r'\x89PNG', '图片'],
  [r'\xff\xd8', '图片'],
  ['JFIF', '图片'],
  ['GIF8', '图片'],
  ['RIFF', '视频'],
  ['OggS', '音频'],
  ['ftyp', '视频'],
  ['ID3', '音频'],
  [r'PK\x03\x04', '文件'],
];

bool _looksLikeBytesRepr(String text) {
  final t = text.trim();
  if (t.length < 4) return false;
  final q = t[1];
  if (t[0] != 'b' || (q != "'" && q != '"')) return false;
  if (t.contains(r'\\') || t.contains('\\')) return true;
  return _bytesMagic.any((m) => t.contains(m[0]));
}

List<MsgPart> _renderBytesRepr(String text) {
  var label = '二进制数据';
  for (final m in _bytesMagic) {
    if (text.contains(m[0])) {
      label = m[1];
      break;
    }
  }
  final parts = <MsgPart>[MsgPlaceholder(label)];
  final url = _extractUrl(text);
  if (url != null) parts.add(MsgLink(url, url));
  return parts;
}

String? _extractUrl(String text) {
  final m = RegExp(r'''https?://[^\s"'\\<>]+''').firstMatch(text);
  if (m == null) return null;
  return m[0]!.replaceAll(RegExp(r'[)\]}>,.!?' r'"' r']+$'), '');
}

// ── OneBot 段 JSON ──

List<Map<String, dynamic>>? _tryParseSegments(String text) {
  final t = text.trim();
  if (!t.startsWith('[')) return null;
  dynamic arr;
  try {
    arr = jsonDecode(t);
  } catch (_) {
    return null;
  }
  if (arr is! List || arr.isEmpty) return null;
  final segs = <Map<String, dynamic>>[];
  for (final seg in arr) {
    if (seg is! Map || seg['type'] is! String) return null;
    segs.add(Map<String, dynamic>.from(seg));
  }
  return segs;
}

// ── CQ 码 ──

List<MsgPart> _renderCq(String text) {
  final re = RegExp(r'\[CQ:([^\],\s]+)((?:,[^\]]*)?)\]');
  final parts = <MsgPart>[];
  var last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) parts.add(MsgText(text.substring(last, m.start)));
    parts.addAll(
      _renderSegment({'type': m[1], 'data': _cqParams(m[2] ?? '')}),
    );
    last = m.end;
  }
  if (last < text.length) parts.add(MsgText(text.substring(last)));
  return parts;
}

String _cqUnescape(String s) => s
    .replaceAll('&#44;', ',')
    .replaceAll('&#91;', '[')
    .replaceAll('&#93;', ']')
    .replaceAll('&amp;', '&');

Map<String, String> _cqParams(String raw) {
  final data = <String, String>{};
  for (final p in raw.split(',')) {
    if (p.isEmpty) continue;
    final eq = p.indexOf('=');
    if (eq < 0) continue;
    data[p.substring(0, eq).trim()] = _cqUnescape(p.substring(eq + 1));
  }
  return data;
}

// ── 段渲染 ──

List<MsgPart> _renderSegment(Map<String, dynamic> seg) {
  final type = seg['type']?.toString() ?? '';
  final data = seg['data'] is Map
      ? Map<String, dynamic>.from(seg['data'] as Map)
      : <String, dynamic>{};
  switch (type) {
    case 'text':
      return [MsgText(data['text']?.toString() ?? '')];
    case 'image':
      return [_imgPart(data['url']?.toString() ?? data['file']?.toString())];
    case 'record':
    case 'voice':
      return const [MsgPlaceholder('语音')];
    case 'video':
      return const [MsgPlaceholder('视频')];
    case 'file':
      final name =
          (data['name'] ?? data['file_name'] ?? data['file'])?.toString() ?? '';
      return [MsgPlaceholder(name.isEmpty ? '文件' : '文件 $name')];
    case 'at':
      return [MsgAt(data['qq']?.toString() ?? '')];
    case 'face':
      return const [MsgPlaceholder('表情')];
    case 'reply':
      var quoted = '';
      final content = data['content'] ?? data['message'];
      if (content is List) {
        for (final c in content) {
          if (c is Map && c['type'] == 'text') {
            final d = c['data'];
            if (d is Map && d['text'] != null) quoted += d['text'].toString();
          }
        }
      } else if (content is String) {
        quoted = content;
      }
      return [MsgReply(quoted)];
    case 'forward':
    case 'node':
      return const [MsgPlaceholder('合并转发')];
    case 'json':
    case 'xml':
      return [_cardPart(data['data'])];
    case 'share':
      final url = data['url']?.toString();
      return [
        const MsgPlaceholder('链接'),
        if (url != null && url.startsWith(RegExp(r'https?://')))
          MsgLink(url, data['title']?.toString() ?? url),
      ];
    case 'location':
      return [
        const MsgPlaceholder('位置'),
        if (data['title'] != null) MsgText(data['title'].toString()),
      ];
    case 'music':
      return [
        const MsgPlaceholder('音乐'),
        if (data['title'] != null) MsgText(data['title'].toString()),
      ];
    case 'contact':
      return const [MsgPlaceholder('联系人卡片')];
    case 'rps':
      return const [MsgPlaceholder('猜拳')];
    case 'dice':
      return const [MsgPlaceholder('骰子')];
    case 'shake':
      return const [MsgPlaceholder('窗口抖动')];
    case 'poke':
      return const [MsgPlaceholder('戳一戳')];
    case 'anonymous':
      return const [MsgPlaceholder('匿名消息')];
    default:
      return [MsgPlaceholder(type.isEmpty ? '未知消息' : type)];
  }
}

MsgPart _imgPart(String? raw) {
  final u = raw?.trim() ?? '';
  if (u.toLowerCase().startsWith('base64://')) {
    final dataUri = _base64ToDataUri(u);
    if (dataUri != null) return MsgImage.inline(dataUri);
  } else if (u.startsWith(RegExp(r'https?://', caseSensitive: false))) {
    return MsgImage.network(u);
  } else if (u.toLowerCase().startsWith('data:image/')) {
    return MsgImage.inline(u);
  }
  return const MsgPlaceholder('图片');
}

/// base64:// → data URI（头部魔数推断 MIME，非图片返回 null）
String? _base64ToDataUri(String u) {
  final b64 = u.substring(9).replaceAll(RegExp(r'\s+'), '');
  if (b64.isEmpty) return null;
  var probe = b64.substring(0, b64.length >= 32 ? 32 : b64.length);
  probe = probe.substring(0, probe.length - (probe.length % 4));
  String head;
  try {
    head = utf8.decode(base64Decode(probe), allowMalformed: true);
  } catch (_) {
    return null;
  }
  String mime;
  if (head.startsWith('\u0089PNG')) {
    mime = 'image/png';
  } else if (head.startsWith('ÿØ')) {
    mime = 'image/jpeg';
  } else if (head.startsWith('GIF8')) {
    mime = 'image/gif';
  } else if (head.startsWith('RIFF') &&
      head.length > 8 &&
      head.indexOf('WEBP') == 8) {
    mime = 'image/webp';
  } else if (head.startsWith('BM')) {
    mime = 'image/bmp';
  } else {
    return null;
  }
  return 'data:$mime;base64,$b64';
}

MsgPart _cardPart(dynamic raw) {
  var title = '';
  var desc = '';
  dynamic obj = raw;
  if (raw is String) {
    try {
      obj = jsonDecode(raw);
    } catch (_) {
      obj = null;
    }
  }
  if (obj is Map) {
    title = (obj['title'] ?? obj['prompt'] ?? '').toString();
    desc = (obj['desc'] ?? obj['text'] ?? '').toString();
  }
  return MsgCard(title, desc);
}
