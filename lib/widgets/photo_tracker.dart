import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../logic/date_utils.dart';
import '../logic/format.dart';
import '../logic/logic.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'common.dart';

List<String> anglesFor(String area) => area == 'skin'
    ? const ['face-front', 'face-left', 'face-right']
    : const ['hair-front', 'hair-left', 'hair-right', 'hair-crown'];

/// Theo dõi ảnh theo thời gian: thêm ảnh theo góc cố định và so sánh 2 thời điểm.
class PhotoTracker extends StatefulWidget {
  final String area; // 'skin' | 'hair'
  const PhotoTracker({super.key, required this.area});
  @override
  State<PhotoTracker> createState() => _PhotoTrackerState();
}

class _PhotoTrackerState extends State<PhotoTracker> {
  late String angle = anglesFor(widget.area).first;
  String? leftId;
  String? rightId;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final d = st.data;
    final supported = st.storage.photosSupported;
    final photos = d.photos.where((p) => p.area == widget.area && p.angle == angle).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Mặc định so sánh ảnh đầu tiên và mới nhất
    PhotoRecord? byId(String? id) {
      for (final p in photos) {
        if (p.id == id) return p;
      }
      return null;
    }

    final left = byId(leftId) ?? (photos.length >= 2 ? photos.first : null);
    final right = byId(rightId) ?? (photos.isNotEmpty ? photos.last : null);

    return SectionCard(
      title: 'Ảnh theo dõi',
      icon: Icons.photo_library_outlined,
      trailing: supported
          ? FilledButton.tonalIcon(
              onPressed: () => _addPhoto(context),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Thêm ảnh'),
            )
          : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const InfoBanner(
          'Ảnh chỉ để theo dõi trực quan, không dùng để chẩn đoán. Chụp cùng góc, cùng vị trí và ánh sáng tương tự để dễ so sánh. '
          'Ảnh được lưu trong bộ nhớ riêng của ứng dụng trên máy, không gửi đi đâu.',
          tone: Tone.info,
          icon: Icons.lock_outline,
        ),
        if (!supported)
          const InfoBanner('Bản web không hỗ trợ lưu ảnh. Hãy dùng app trên Android/iOS/desktop.', tone: Tone.warn)
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final a in anglesFor(widget.area))
                  ButtonSegment(value: a, label: Text(photoAngleLabel[a]!.split('– ').last)),
              ],
              selected: {angle},
              onSelectionChanged: (s) => setState(() {
                angle = s.first;
                leftId = null;
                rightId = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (photos.isEmpty)
            EmptyState(
              icon: Icons.photo_camera_outlined,
              title: 'Chưa có ảnh góc ${photoAngleLabel[angle]!.toLowerCase()}',
              message: 'Gợi ý: chụp mỗi 2–4 tuần để so sánh sau 4, 8, 12 tuần.',
            )
          else ...[
            if (left != null && right != null && left.id != right.id) ...[
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _PhotoBox(record: left, onTap: () => _choose(context, photos, true))),
                const SizedBox(width: 8),
                Expanded(child: _PhotoBox(record: right, onTap: () => _choose(context, photos, false))),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Cách nhau ${daysBetween(left.date, right.date)} ngày (~${fmtNum(daysBetween(left.date, right.date) / 7)} tuần). Nhấn vào ảnh để chọn ảnh khác.',
                  style: mutedStyle(context),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                for (final w in const [4, 8, 12])
                  ActionChip(
                    label: Text('$w tuần trước'),
                    onPressed: () {
                      final target = shiftDate(right.date, -w * 7);
                      PhotoRecord? best;
                      for (final p in photos) {
                        if (p.id == right.id) continue;
                        if (best == null ||
                            daysBetween(p.date, target).abs() < daysBetween(best.date, target).abs()) {
                          best = p;
                        }
                      }
                      if (best != null) setState(() => leftId = best!.id);
                    },
                  ),
              ]),
            ] else if (right != null)
              _PhotoBox(record: right, onTap: () {}),
            const SizedBox(height: 12),
            Text('Tất cả ảnh góc này (${photos.length})', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in photos.reversed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _openPhoto(context, p),
                        child: SizedBox(width: 80, child: _Thumb(record: p, size: 80)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ]),
    );
  }

  Future<void> _choose(BuildContext context, List<PhotoRecord> photos, bool isLeft) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(shrinkWrap: true, children: [
        for (final p in photos.reversed)
          ListTile(
            leading: SizedBox(width: 48, height: 48, child: _Thumb(record: p, size: 48)),
            title: Text(fmtDate(p.date)),
            subtitle: p.note.isEmpty ? null : Text(p.note),
            onTap: () => Navigator.pop(ctx, p.id),
          ),
      ]),
    );
    if (id == null) return;
    setState(() {
      if (isLeft) {
        leftId = id;
      } else {
        rightId = id;
      }
    });
  }

  Future<void> _openPhoto(BuildContext context, PhotoRecord p) async {
    final st = AppScope.read(context);
    final f = st.storage.photoFile(p.fileName);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${photoAngleLabel[p.angle]} · ${fmtDate(p.date)}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (f != null && f.existsSync())
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(f, fit: BoxFit.contain))
            else
              const Text('Không tìm thấy file ảnh.'),
            if (p.lighting.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Ánh sáng: ${p.lighting}')),
            if (p.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Ghi chú: ${p.note}')),
          ]),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              final ok = await confirmDialog(ctx, title: 'Xóa ảnh?', message: 'Ảnh sẽ bị xóa vĩnh viễn khỏi máy.', confirmText: 'Xóa', danger: true);
              if (!ok) return;
              await st.storage.deletePhoto(p.fileName);
              st.update((dd) => dd.photos.removeWhere((e) => e.id == p.id));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Xóa'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> _addPhoto(BuildContext context) async {
    final st = AppScope.read(context);
    var a = angle;
    var date = todayStr();
    final lighting = TextEditingController();
    final note = TextEditingController();
    final canCamera = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text('Thêm ảnh theo dõi', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: a,
                decoration: const InputDecoration(labelText: 'Góc chụp'),
                items: [for (final x in anglesFor(widget.area)) DropdownMenuItem(value: x, child: Text(photoAngleLabel[x]!))],
                onChanged: (v) => setS(() => a = v ?? a),
              ),
              const SizedBox(height: 12),
              DateButton(label: 'Ngày chụp', value: date, last: todayStr(), onChanged: (v) => setS(() => date = v)),
              const SizedBox(height: 12),
              TextField(
                controller: lighting,
                decoration: const InputDecoration(labelText: 'Ánh sáng (tùy chọn)', hintText: 'VD: cạnh cửa sổ, buổi sáng'),
              ),
              const SizedBox(height: 12),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)')),
              const SizedBox(height: 16),
              Row(children: [
                if (canCamera)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, ImageSource.camera),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Chụp ảnh'),
                    ),
                  ),
                if (canCamera) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn từ thư viện'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
    if (source == null) return;

    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final id = uid('ph');
      final fileName = '$id.jpg';
      await st.storage.savePhotoBytes(bytes, fileName);
      st.update((dd) => dd.photos.add(PhotoRecord(
            id: id,
            date: date,
            area: widget.area,
            angle: a,
            fileName: fileName,
            lighting: lighting.text.trim(),
            note: note.text.trim(),
          )));
      if (mounted) setState(() => angle = a);
      if (context.mounted) showSnack(context, 'Đã lưu ảnh');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Không thêm được ảnh: $e', error: true);
    }
  }
}

class _Thumb extends StatelessWidget {
  final PhotoRecord record;
  final double size;
  const _Thumb({required this.record, required this.size});
  @override
  Widget build(BuildContext context) {
    final f = AppScope.read(context).storage.photoFile(record.fileName);
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size * (size >= 80 ? 0.85 : 1),
          child: f != null && f.existsSync()
              ? Image.file(f, fit: BoxFit.cover, cacheWidth: (size * 3).round())
              : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.broken_image)),
        ),
      ),
      if (size >= 80) Text(fmtDayMonth(record.date), style: const TextStyle(fontSize: 11)),
    ]);
  }
}

class _PhotoBox extends StatelessWidget {
  final PhotoRecord record;
  final VoidCallback onTap;
  const _PhotoBox({required this.record, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final f = AppScope.read(context).storage.photoFile(record.fileName);
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: f != null && f.existsSync()
                ? Image.file(f, fit: BoxFit.cover)
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.broken_image))),
          ),
        ),
        const SizedBox(height: 4),
        Text(fmtDate(record.date), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
