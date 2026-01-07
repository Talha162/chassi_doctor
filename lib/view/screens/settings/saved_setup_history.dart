import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:motorsport/controller/settings/saved_setup_history_controller.dart';
import 'package:motorsport/constants/app_colors.dart';
import 'package:motorsport/constants/app_images.dart';
import 'package:motorsport/constants/app_sizes.dart';
import 'package:motorsport/models/history_entry.dart';
import 'package:motorsport/view/screens/settings/chassis_session_detail.dart';
import 'package:motorsport/view/widget/my_button_widget.dart';
import 'package:motorsport/view/widget/my_text_widget.dart';
import 'package:motorsport/services/supabase/supabase_client_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedSetupHistory extends StatelessWidget {
  const SavedSetupHistory({super.key});

  Future<void> _shareSessionAsPdf(
    BuildContext context,
    HistoryEntry session,
  ) async {
    final pdf = pw.Document();

    final track = session.trackSnapshot;
    final symptom = session.symptomSnapshot;
    final issues = session.issuesSnapshot;
    final recommendations = session.recommendations;
    final formattedDate =
        DateFormat('yyyy-MM-dd HH:mm').format(session.createdAt.toLocal());
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final sourceType = session.hasSessionData ? 'session' : 'track';
    final note = userId == null
        ? null
        : await SupabaseService.instance.getHistoryNote(
            userId: userId,
            sourceType: sourceType,
            sourceId: session.id,
          );

    final logoData = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    height: 120,
                    width: 120,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColor.fromInt(0xFFEDE7F6),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Image(logoImage, height: 70, width: 70),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text(
                    'Chassis Doctor Session',
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    formattedDate,
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColor.fromInt(0xFF616161),
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'Powered by Motorsport University',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColor.fromInt(0xFF757575),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Text('Session Details', style: pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 6),
            pw.Text(formattedDate, style: pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 12),
            pw.Text('Track Configuration', style: pw.TextStyle(fontSize: 16)),
            pw.Bullet(text: 'Track Type: ${track['track_type'] ?? 'Not set'}'),
            pw.Bullet(text: 'Surface Type: ${track['surface_type'] ?? 'Not set'}'),
            pw.Bullet(text: 'Weather: ${track['weather_condition'] ?? 'Not set'}'),
            pw.SizedBox(height: 12),
            pw.Text('Selected Symptom', style: pw.TextStyle(fontSize: 16)),
            if (!session.hasSessionData)
              pw.Text('No symptom selected.')
            else ...[
              pw.Bullet(text: '${symptom['title'] ?? 'Unknown'}'),
              if ((symptom['description'] ?? '').toString().isNotEmpty)
                pw.Paragraph(text: symptom['description'].toString()),
            ],
            pw.SizedBox(height: 12),
            pw.Text('Selected Issues', style: pw.TextStyle(fontSize: 16)),
            if (!session.hasSessionData || issues.isEmpty)
              pw.Text('No issues selected.')
            else
              ...issues.map((issue) {
                final issueMap = issue as Map;
                return pw.Bullet(
                  text:
                      '${issueMap['title'] ?? 'Issue'} - ${issueMap['description'] ?? ''}',
                );
              }),
            pw.SizedBox(height: 12),
            pw.Text('AI Recommendations', style: pw.TextStyle(fontSize: 16)),
            if (!session.hasSessionData || recommendations.isEmpty)
              pw.Text('No recommendations generated.')
            else
              ...recommendations.map((rec) {
                final recMap = rec as Map;
                final category = recMap['category']?.toString();
                final title = recMap['title']?.toString() ?? 'Recommendation';
                final details = recMap['details']?.toString() ?? '';
                final header =
                    category == null || category.isEmpty ? title : '$title ($category)';
                return pw.Bullet(text: '$header - $details');
              }),
            pw.SizedBox(height: 12),
            pw.Text('Notes', style: pw.TextStyle(fontSize: 16)),
            if (note == null || note.note.trim().isEmpty)
              pw.Text('No notes added.')
            else
              pw.Paragraph(text: note.note),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/chassis_session_${session.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Chassis Doctor session details',
    );
  }

  @override
  Widget build(BuildContext context) {
    final SavedSetupHistoryController controller = Get.put(SavedSetupHistoryController());

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSizes.DEFAULT,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Saved Setup History',
                size: 18,
                paddingBottom: 8,
                weight: FontWeight.bold,
              ),
              MyText(
                text: 'Review and manage your past vehicle configurations.',
                size: 12,
                paddingBottom: 25,
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(child: CircularProgressIndicator(color: kSecondaryColor));
                  }

                  if (controller.entries.isEmpty) {
                    return  Center(
                      child: MyText(
                        text: 'No saved setups found.',
                        color: kTertiaryColor,
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.entries.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 180,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final session = controller.entries[index];
                      final formattedDate =
                          DateFormat('yyyy-MM-dd').format(session.createdAt);
                      final track = session.trackSnapshot;

                      return SetupHistoryTile(
                        trackType: track['track_type']?.toString() ?? 'Not set',
                        surfaceType:
                            track['surface_type']?.toString() ?? 'Not set',
                        weather:
                            track['weather_condition']?.toString() ?? 'Not set',
                        date: formattedDate,
                        onView: () {
                          Get.to(() => ChassisSessionDetail(session: session));
                        },
                        onShare: () {
                          _shareSessionAsPdf(context, session);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CORRECTED WIDGET
class SetupHistoryTile extends StatelessWidget {
  final String trackType;
  final String surfaceType;
  final String weather;
  final String date;
  final VoidCallback? onView;
  final VoidCallback? onShare;

  const SetupHistoryTile({
    super.key,
    required this.trackType,
    required this.surfaceType,
    required this.weather,
    required this.date,
    this.onView,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kQuaternaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: trackType, // Use trackType as the title
            size: 16,
            weight: FontWeight.bold,
            paddingBottom: 16,
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
          _buildInfoRow(Assets.imagesSurfaceType, surfaceType),
          const SizedBox(height: 12),
          _buildInfoRow(Assets.imagesWeather, weather),
          const SizedBox(height: 12),
          _buildInfoRow(Assets.imagesDate, date),
          const Spacer(), // Pushes buttons to the bottom
          Row(
            children: [
              Expanded(
                child: MyButton(
                  buttonText: 'View',
                  height: 30,
                  textSize: 12,
                  radius: 8,
                  onTap: onView,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MyBorderButton(
                  buttonText: 'Share',
                  height: 30,
                  textSize: 12,
                  buttonColor: kSecondaryColor,
                  textColor: kSecondaryColor,
                  radius: 8,
                  onTap: onShare ?? () {}, // Corrected this line
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String icon, String text) {
    return Row(
      children: [
        Image.asset(icon, height: 16),
        Expanded(
          child: MyText(
            paddingLeft: 6,
            text: text,
            size: 12,
            color: kTertiaryColor,
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
