/**
 * FileValidationTrigger
 * Validates uploaded files: allowed types (PDF, JPG, PNG) and max size of 10 MB.
 *
 * Called from:
 *   ContentVersionBeforeInsert trigger (fires when any file version is created)
 *   ContentDocumentLinkBeforeInsert trigger (fires when a file is linked to a Lead)
 *
 * Note: ContentVersion.FileExtension, FileType, and ContentSize are system-managed
 * fields derived from PathOnClient and VersionData — they are NOT settable via DML.
 * Validation logic is exposed via a testable overload that accepts explicit parameters.
 */
public with sharing class FileValidationTrigger {

    // ─── Constants ──────────────────────────────────────────────────────────────

    private static final Long MAX_SIZE_BYTES = 10 * 1024 * 1024; // 10 MB

    private static final Set<String> ALLOWED_EXTENSIONS = new Set<String>{
        'pdf', 'jpg', 'jpeg', 'png'
    };

    // ─── Entry Point: ContentVersion before insert ───────────────────────────────

    public static void validateOnVersionInsert(List<ContentVersion> versions) {
        for (ContentVersion cv : versions) {
            String err = getValidationError(cv.Title, cv.FileExtension, cv.ContentSize);
            if (err != null) cv.addError(err);
        }
    }

    // ─── Entry Point: ContentDocumentLink before insert ──────────────────────────

    public static void validateOnLinkInsert(List<ContentDocumentLink> links) {
        // Only check files being linked to Lead records (prefix 00Q)
        Map<Id, ContentDocumentLink> docToLink = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdl : links) {
            String linkedId = String.valueOf(cdl.LinkedEntityId);
            if (linkedId != null && linkedId.startsWith('00Q')) {
                docToLink.put(cdl.ContentDocumentId, cdl);
            }
        }
        if (docToLink.isEmpty()) return;

        List<ContentVersion> versions = [
            SELECT Id, Title, FileExtension, ContentSize, ContentDocumentId
            FROM   ContentVersion
            WHERE  ContentDocumentId IN :docToLink.keySet()
              AND  IsLatest = true
        ];

        for (ContentVersion cv : versions) {
            String err = getValidationError(cv.Title, cv.FileExtension, cv.ContentSize);
            if (err != null) {
                docToLink.get(cv.ContentDocumentId).addError(err);
            }
        }
    }

    // ─── Core Validation (testable overload with explicit params) ────────────────

    /**
     * Returns an error message string if validation fails, null if the file is valid.
     * Exposed as @TestVisible so unit tests can call it directly without needing to
     * create real ContentVersion records (whose system fields are not settable via DML).
     *
     * @param title      File title / display name
     * @param extension  File extension in lower case (e.g. "pdf", "jpg")
     * @param sizeBytes  File size in bytes
     */
    @TestVisible
    static String getValidationError(String title, String extension, Long sizeBytes) {
        // Size check
        if (sizeBytes != null && sizeBytes > MAX_SIZE_BYTES) {
            Decimal sizeMb = sizeBytes / (1024 * 1024.0);
            return 'File "' + title + '" exceeds the 10 MB limit ('
                + sizeMb.setScale(1) + ' MB). Please compress the file and re-upload.';
        }

        // Extension check
        String ext = extension != null ? extension.toLowerCase() : '';
        if (!ALLOWED_EXTENSIONS.contains(ext)) {
            return 'File type ".' + ext + '" is not allowed. '
                + 'Only PDF, JPG, and PNG files may be uploaded to Lead records.';
        }

        return null; // passes
    }
}
