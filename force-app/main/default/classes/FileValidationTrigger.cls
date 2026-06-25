/**
 * FileValidationTrigger
 * Validates uploaded files on Lead records: allowed types (PDF, JPG, PNG)
 * and max size of 10 MB.
 *
 * Fires on ContentVersion (after insert) – ContentVersion is created when a
 * file is attached via the Files component on any record.
 *
 * Linked records are checked via ContentDocumentLink; because the link is
 * created AFTER the ContentVersion we rely on a separate trigger on
 * ContentDocumentLink (FileDistributionTrigger) to validate on link creation.
 * This class provides the shared validation logic used by both triggers.
 */
public with sharing class FileValidationTrigger {

    // ─── Constants ──────────────────────────────────────────────────────────────

    private static final Long    MAX_SIZE_BYTES     = 10 * 1024 * 1024; // 10 MB
    private static final Set<String> ALLOWED_EXTENSIONS = new Set<String>{
        'pdf', 'jpg', 'jpeg', 'png'
    };
    private static final Set<String> ALLOWED_CONTENT_TYPES = new Set<String>{
        'application/pdf',
        'image/jpeg',
        'image/jpg',
        'image/png'
    };

    // ─── Entry Point: called from ContentVersion trigger ────────────────────────

    /**
     * Validate a list of ContentVersion records on insert.
     * Adds an error to any record that fails size or type validation.
     *
     * @param versions  Trigger.new from a ContentVersion before-insert trigger
     */
    public static void validateOnVersionInsert(List<ContentVersion> versions) {
        for (ContentVersion cv : versions) {
            validateVersion(cv);
        }
    }

    // ─── Entry Point: called from ContentDocumentLink trigger ────────────────────

    /**
     * Validate files when they are linked to a Lead record.
     * Queries the related ContentVersion and adds an error on the link record
     * if the file fails validation.
     *
     * @param links  Trigger.new from a ContentDocumentLink before-insert trigger
     */
    public static void validateOnLinkInsert(List<ContentDocumentLink> links) {
        // Collect document IDs linked to Lead records
        Map<Id, ContentDocumentLink> docToLink = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdl : links) {
            // Only validate files being linked to Lead
            if (String.valueOf(cdl.LinkedEntityId).startsWith('00Q')) {
                docToLink.put(cdl.ContentDocumentId, cdl);
            }
        }

        if (docToLink.isEmpty()) return;

        // Fetch the latest version for each document
        List<ContentVersion> versions = [
            SELECT Id, Title, FileExtension, FileType, ContentSize, ContentDocumentId
            FROM   ContentVersion
            WHERE  ContentDocumentId IN :docToLink.keySet()
              AND  IsLatest = true
        ];

        for (ContentVersion cv : versions) {
            String errorMsg = getValidationError(cv);
            if (errorMsg != null) {
                docToLink.get(cv.ContentDocumentId).addError(errorMsg);
            }
        }
    }

    // ─── Private Helpers ────────────────────────────────────────────────────────

    @TestVisible
    private static void validateVersion(ContentVersion cv) {
        String errorMsg = getValidationError(cv);
        if (errorMsg != null) {
            cv.addError(errorMsg);
        }
    }

    @TestVisible
    private static String getValidationError(ContentVersion cv) {
        // Size check
        if (cv.ContentSize != null && cv.ContentSize > MAX_SIZE_BYTES) {
            Decimal sizeMb = cv.ContentSize / (1024 * 1024.0);
            return 'File "' + cv.Title + '" exceeds the 10 MB limit ('
                + sizeMb.setScale(1) + ' MB). Please compress the file and re-upload.';
        }

        // Extension check
        String ext = cv.FileExtension != null ? cv.FileExtension.toLowerCase() : '';
        String mime = cv.FileType    != null ? cv.FileType.toLowerCase()    : '';

        Boolean extOk  = ALLOWED_EXTENSIONS.contains(ext);
        Boolean mimeOk = ALLOWED_CONTENT_TYPES.contains(mime)
                      || ALLOWED_CONTENT_TYPES.contains(cv.FileType != null ? cv.FileType : '');

        if (!extOk) {
            return 'File type ".' + ext + '" is not allowed. Only PDF, JPG, and PNG files may be uploaded.';
        }

        return null; // passes validation
    }
}
