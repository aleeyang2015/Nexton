import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../domain/entities/leave_attachment.dart';
import '../pages/leave_file_page.dart';

/// Opens a leave file where it can be read: a photo full screen (pinch to
/// zoom), a PDF in the App's viewer with Share, anything else (a Word file
/// sent from the web) on a page with Share. A file with no url cannot be
/// opened.
void openLeaveFile(BuildContext context, LeaveAttachment file) {
  final url = file.url;
  if (url == null) return;
  if (file.isImage) {
    showImageViewer(context, url);
    return;
  }
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => LeaveFilePage(file: file)));
}

/// One file of a request, on the employee's page and the approver's: tap
/// to open it. A file with no url is plain text.
class LeaveFileTile extends StatelessWidget {
  const LeaveFileTile({super.key, required this.file});

  final LeaveAttachment file;

  @override
  Widget build(BuildContext context) {
    final opens = file.url != null;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            file.isImage
                ? Icons.image_outlined
                : file.isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.attach_file,
            size: 18,
            color: opens ? AppColors.primary : AppColors.subTitle,
          ),
          widthBx(w: 8),
          Expanded(
            child: customText(
              file.displayName,
              fontSize: 13,
              color: opens ? AppColors.primary : AppColors.textPrimary,
              maxLine: 2,
            ),
          ),
          if (opens)
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.subTitle,
            ),
        ],
      ),
    );
    if (!opens) return row;
    return InkWell(onTap: () => openLeaveFile(context, file), child: row);
  }
}
