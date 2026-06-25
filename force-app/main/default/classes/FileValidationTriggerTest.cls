/**
 * FileValidationTriggerTest
 * Tests the @TestVisible getValidationError(title, extension, sizeBytes) overload directly.
 * ContentVersion.FileExtension, FileType, and ContentSize are system-managed fields
 * that cannot be set via DML in tests, so we test the core logic via the param overload.
 */
@IsTest
private class FileValidationTriggerTest {

    @IsTest
    static void testPdfPassesValidation() {
        String err = FileValidationTrigger.getValidationError('Policy_Doc', 'pdf', 1 * 1024 * 1024L);
        System.assertEquals(null, err, 'A valid PDF under 10 MB should pass');
    }

    @IsTest
    static void testJpgPassesValidation() {
        String err = FileValidationTrigger.getValidationError('ID_Photo', 'jpg', 500 * 1024L);
        System.assertEquals(null, err, 'A valid JPG should pass');
    }

    @IsTest
    static void testJpegPassesValidation() {
        String err = FileValidationTrigger.getValidationError('Scan', 'jpeg', 200 * 1024L);
        System.assertEquals(null, err, 'A valid JPEG should pass');
    }

    @IsTest
    static void testPngPassesValidation() {
        String err = FileValidationTrigger.getValidationError('Screenshot', 'png', 2 * 1024 * 1024L);
        System.assertEquals(null, err, 'A valid PNG should pass');
    }

    @IsTest
    static void testExeFailsValidation() {
        String err = FileValidationTrigger.getValidationError('Malware', 'exe', 100L);
        System.assertNotEquals(null, err, 'An .exe should be rejected');
        System.assert(err.contains('.exe'), 'Error should mention the bad extension');
    }

    @IsTest
    static void testDocxFailsValidation() {
        String err = FileValidationTrigger.getValidationError('Proposal', 'docx', 200 * 1024L);
        System.assertNotEquals(null, err, 'A .docx should be rejected');
        System.assert(err.contains('.docx'), 'Error should mention the extension');
    }

    @IsTest
    static void testMp4FailsValidation() {
        String err = FileValidationTrigger.getValidationError('Video', 'mp4', 5 * 1024 * 1024L);
        System.assertNotEquals(null, err, 'An .mp4 should be rejected');
    }

    @IsTest
    static void testOversizedPdfFails() {
        Long elevenMb = 11L * 1024 * 1024;
        String err = FileValidationTrigger.getValidationError('HugeDoc', 'pdf', elevenMb);
        System.assertNotEquals(null, err, 'An 11 MB PDF should be rejected');
        System.assert(err.contains('10 MB'), 'Error should mention the 10 MB limit');
    }

    @IsTest
    static void testExactly10MbPasses() {
        Long tenMb = 10L * 1024 * 1024;
        String err = FileValidationTrigger.getValidationError('EdgeCase', 'pdf', tenMb);
        System.assertEquals(null, err, 'Exactly 10 MB should be allowed');
    }

    @IsTest
    static void testNullExtensionFails() {
        String err = FileValidationTrigger.getValidationError('NoExt', null, 100L);
        System.assertNotEquals(null, err, 'Null extension should be rejected');
    }

    @IsTest
    static void testNullSizePasses() {
        // ContentSize can be null before content is processed
        String err = FileValidationTrigger.getValidationError('Doc', 'pdf', null);
        System.assertEquals(null, err, 'Null size (pre-processing) should pass size check');
    }

    @IsTest
    static void testBulkValidation() {
        // Ensure no governor limit issues with 50 valid calls
        for (Integer i = 0; i < 50; i++) {
            String err = FileValidationTrigger.getValidationError('doc_' + i, 'pdf', 1024L);
            System.assertEquals(null, err, 'Bulk: valid PDF should pass at index ' + i);
        }
    }
}
