import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'app_lang.dart';
import 'issues_store.dart';
import 'location_picker_screen.dart';
import 'main.dart'; // عشان AppColors

const Color _textPrimary = Color(0xFF0F172A);
const Color _blue = Color(0xFF0051D5);
const Color _errorRed = Color(0xFFBA1A1A);

String _tr(bool isAr, String ar, String en) => isAr ? ar : en;

// ======================================================================
// شاشة 6: تسجيل مشكلة — للمواطن
// ======================================================================
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  static const int _maxChars = 500;
  static const int _minChars = 10;

  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  IssueType? _type;

  // الموقع على الخريطة / GPS (اختياري لو المواطن كتب العنوان)
  LatLng? _picked;
  bool _locating = false;

  // الصور (بتتصغّر أول ما تتاخد عشان تتحفظ بسرعة)
  static const int _maxPhotos = 3;
  final List<Uint8List> _photos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _soon(bool isAr, String ar, String en) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_tr(isAr, ar, en))));
  }

  void _submit() {
    // لو في خانة ناقصة بتظهر رسالة حمرا تحتها ومبيتبعتش حاجة
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // حد أقصى لعدد البلاغات في اليوم للمواطن الواحد
    if (hasReachedDailyLimit) {
      _soon(
        appLang.value == 'ar',
        'وصلت للحد الأقصى ($maxIssuesPerDay بلاغات في اليوم). جرّب بكرة.',
        'Daily limit reached ($maxIssuesPerDay reports per day). Try tomorrow.',
      );
      return;
    }

    final photos = _photos.map(base64Encode).toList();
    final totalSize = photos.fold<int>(0, (sum, p) => sum + p.length);

    // حد أمان: مستند Firebase مبيستحملش أكتر من 1 ميجا
    if (totalSize > 700000) {
      _soon(
        appLang.value == 'ar',
        'الصور حجمها كبير، شيل صورة وجرّب تاني',
        'Photos are too large, remove one and try again',
      );
      return;
    }

    final typedLocation = _locationController.text.trim();

    addIssue(
      type: _type!,
      description: _descController.text.trim(),
      // لو المواطن حدد على الخريطة من غير ما يكتب عنوان
      location: typedLocation.isNotEmpty
          ? typedLocation
          : _tr(appLang.value == 'ar', 'موقع محدد على الخريطة',
              'Location pinned on the map'),
      photos: photos,
      lat: _picked?.latitude,
      lng: _picked?.longitude,
    );

    // يرجع لشاشة "مشاكلي" ومعاه true (يعني اتبعتت)
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final isAr = lang == 'ar';
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(isAr),
                    _buildHeader(isAr),
                    _buildFormCard(isAr),
                    const SizedBox(height: 16),
                    _buildSecureFooter(isAr),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- الشريط العلوي: رجوع + "بلاغ مدني جديد" ----------
  Widget _buildTopBar(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Tooltip(
            message: _tr(isAr, 'الرجوع إلى مشاكلي', 'Back to my issues'),
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              shadowColor: const Color(0x1A0F2942),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    // في العربي السهم بيشاور يمين (ده "رجوع" في الاتجاه من اليمين للشمال)
                    isAr ? Icons.arrow_forward : Icons.arrow_back,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tintSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _tr(isAr, 'بلاغ مدني جديد', 'New city report'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isAr) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr(isAr, 'سجّل مشكلة', 'Report an issue'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _tr(
                isAr,
                'أبلغ البلدية عن أي ملاحظة في حيك ليتم التعامل معها ومتابعتها فوراً',
                'Tell the city about anything in your area so it can be handled and followed up right away'),
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.slateSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- الكارت اللي فيه كل الخانات ----------
  Widget _buildFormCard(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F2942),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeField(isAr),
            const SizedBox(height: 20),
            _buildDescriptionField(isAr),
            const SizedBox(height: 20),
            _buildPhotoSection(isAr),
            const SizedBox(height: 20),
            _buildLocationSection(isAr),
            const SizedBox(height: 24),
            _buildSubmitButton(isAr),
          ],
        ),
      ),
    );
  }

  // شكل الخانات: خلفية فاتحة، حواف دايرية، وإطار كحلي لما تضغط عليها
  InputDecoration _fieldDecoration({
    String? hint,
    Widget? prefixIcon,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: color == Colors.transparent
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.slateSecondary),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.containerLow,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(Colors.transparent, 0),
      enabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(AppColors.navy, 1.2),
      errorBorder: border(_errorRed, 1),
      focusedErrorBorder: border(_errorRed, 1.5),
    );
  }

  Widget _label(String text, {bool isRequired = false, String? hintText}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _errorRed,
            ),
          ),
        ],
        if (hintText != null) ...[
          const SizedBox(width: 6),
          Text(
            hintText,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slateSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // ---------- 1) نوع المشكلة ----------
  Widget _buildTypeField(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(_tr(isAr, 'نوع المشكلة', 'Issue type'), isRequired: true),
        const SizedBox(height: 6),
        DropdownButtonFormField<IssueType>(
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.slateSecondary),
          decoration: _fieldDecoration(
            prefixIcon:
                const Icon(Icons.category_outlined, color: AppColors.navy),
          ),
          hint: Text(
            _tr(isAr, 'اختر تصنيف المشكلة...', 'Choose a category...'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slateSecondary,
            ),
          ),
          items: [
            for (final t in IssueType.values)
              DropdownMenuItem<IssueType>(
                value: t,
                child: Text(
                  issueTypeLabel(t, isAr),
                  style: const TextStyle(fontSize: 14, color: _textPrimary),
                ),
              ),
          ],
          onChanged: (value) => setState(() => _type = value),
          validator: (value) => value == null
              ? _tr(isAr, 'اختر نوع المشكلة', 'Please choose the issue type')
              : null,
        ),
      ],
    );
  }

  // ---------- 2) وصف المشكلة ----------
  Widget _buildDescriptionField(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(_tr(isAr, 'وصف المشكلة', 'Description'), isRequired: true),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.containerLow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _tr(isAr, 'دقيق ومختصر', 'Short and clear'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slateSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descController,
          maxLines: 4,
          maxLength: _maxChars,
          onChanged: (_) => setState(() {}), // عشان عدّاد الحروف يتحدث
          style: const TextStyle(fontSize: 14, color: _textPrimary),
          decoration: _fieldDecoration(
            hint: _tr(
                isAr,
                'اكتب تفاصيل المشكلة بدقة لمساعدة فريق الصيانة الميداني في تحديد اللازم...',
                'Describe the problem in detail to help the field team...'),
          ),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) {
              return _tr(isAr, 'اكتب وصف المشكلة', 'Please describe the issue');
            }
            if (text.length < _minChars) {
              return _tr(
                  isAr,
                  'اكتب وصفًا أوضح ($_minChars حروف على الأقل)',
                  'Please write a bit more (at least $_minChars characters)');
            }
            return null;
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.edit_note, size: 15, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _tr(isAr, 'توضيح المعالم القريبة يسرّع الحل',
                    'Mentioning nearby landmarks speeds things up'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
            Text(
              isAr
                  ? '${_descController.text.length} / $_maxChars حرف'
                  : '${_descController.text.length} / $_maxChars chars',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slateSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- 3) الصور ----------
  Future<void> _pickPhoto(ImageSource source, bool isAr) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 50,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() => _photos.add(bytes));
    } catch (e) {
      if (!mounted) return;
      _soon(
        isAr,
        'معرفناش نفتح الكاميرا أو المعرض',
        'Could not open the camera or gallery',
      );
    }
  }

  void _showPhotoSourceSheet(bool isAr) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppColors.navy),
                title: Text(_tr(isAr, 'التقاط صورة بالكاميرا', 'Take a photo')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(ImageSource.camera, isAr);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.navy),
                title: Text(
                    _tr(isAr, 'اختيار من المعرض', 'Choose from gallery')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(ImageSource.gallery, isAr);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumb(int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _photos[index],
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
        PositionedDirectional(
          top: -6,
          end: -6,
          child: GestureDetector(
            onTap: () => setState(() => _photos.removeAt(index)),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: _errorRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(
              _tr(isAr, 'إضافة صورة توضيحية', 'Add a photo'),
              hintText: _tr(isAr, '(اختياري)', '(optional)'),
            ),
            Text(
              '${_photos.length}/$_maxPhotos',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slateSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photos.isNotEmpty) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_photos.length, _buildPhotoThumb),
          ),
          const SizedBox(height: 12),
        ],
        if (_photos.length < _maxPhotos)
          Material(
            color: AppColors.containerLow,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showPhotoSourceSheet(isAr),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.tintSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.navy, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tr(isAr, 'اضغط لرفع صورة أو التقاطها فوراً',
                          'Tap to upload or take a photo'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tr(isAr, 'يمكنك إرفاق حتى ٣ صور للموقع المتضرر',
                          'You can attach up to 3 photos of the damaged spot'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slateSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------- 4) الموقع ----------
  // حالياً: المواطن بيكتب العنوان وأقرب علامة مميزة.
  // تحديد الموقع (GPS) والخريطة في المرحلة الجاية.
  Future<void> _useCurrentLocation(bool isAr) async {
    setState(() => _locating = true);
    final result = await fetchCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);

    final point = result.point;
    if (point == null) {
      _soon(isAr, locationFailureMessage(result.failure!, true),
          locationFailureMessage(result.failure!, false));
      return;
    }

    setState(() => _picked = point);
  }

  Future<void> _openMapPicker() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: _picked),
      ),
    );

    if (point != null && mounted) {
      setState(() => _picked = point);
    }
  }

  Widget _locationPill({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, size: 16, color: _blue),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(_tr(isAr, 'الموقع', 'Location'), isRequired: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: _locationController,
          style: const TextStyle(fontSize: 14, color: _textPrimary),
          decoration: _fieldDecoration(
            hint: _tr(isAr, 'اكتب الحي والشارع وأقرب علامة مميزة',
                'Write the area, street and nearest landmark'),
            prefixIcon:
                const Icon(Icons.location_on_outlined, color: AppColors.navy),
          ),
          // كفاية عنوان مكتوب أو مكان متحدد على الخريطة
          validator: (value) =>
              (value ?? '').trim().isEmpty && _picked == null
                  ? _tr(isAr, 'اكتب مكان المشكلة أو حدده على الخريطة',
                      'Enter the location or pick it on the map')
                  : null,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _locationPill(
              icon: Icons.my_location,
              label: _tr(isAr, 'موقعي الحالي', 'My location'),
              loading: _locating,
              onTap: _locating ? null : () => _useCurrentLocation(isAr),
            ),
            _locationPill(
              icon: Icons.map_outlined,
              label: _tr(isAr, 'حدد على الخريطة', 'Pick on the map'),
              onTap: _openMapPicker,
            ),
          ],
        ),
        if (_picked != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 18, color: Color(0xFF15803D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _tr(isAr, 'تم تحديد الموقع على الخريطة',
                        'Location pinned on the map'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _picked = null),
                  child: const Icon(Icons.close,
                      size: 18, color: Color(0xFF15803D)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------- زرار الإرسال ----------
  Widget _buildSubmitButton(bool isAr) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tr(isAr, 'إرسال البلاغ', 'Submit report'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Icon(isAr ? Icons.arrow_back : Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureFooter(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.containerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined, size: 18, color: _blue),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _tr(
                  isAr,
                  'بياناتك محمية وموثقة عبر البوابة البلدية الذكية',
                  'Your data is protected and verified by the Smart City Portal'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slateSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}