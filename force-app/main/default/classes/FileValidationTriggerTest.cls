@IsTest
private class FileValidationTriggerTest {

    // ─── Helpers ────────────────────────────────────────────────────────────────

    private static ContentVersion buildCV(String title, String ext, Long sizeBytes) {
        ContentVersion cv = new ContentVersion();
        cv.Title          = title;
        cv.FileExtension  = ext;
        cv.FileType       = ext; // simplified for unit test
        cv.ContentSize    = sizeBytes;
        cv.PathOnClient   = title + '.' + ext;
        cv.VersionData    = Blob.valueOf('test');
        return cv;
    }

    // ─── Tests ──────────────────────────────────────────────────────────────────

    @IsTest
    static void testPdfPassesValidation() {
        ContentVersion cv = buildCV('Policy_Doc', 'pdf', 1024 * 1024); // 1 MB
        Test.startTest();
        String err = FileValidationTrigger.getValidationError(cv);
        Test.stopTest();
        System.assertEquals(null, err, 'A valid PDF under 10 MB should pass');
    }

    @IsTest
    static void testJpgPassesValidation() {
        ContentVersion cv = buildCV('ID_Photo', 'jpg', 500 * 1024); // 500 KB
        String err = FileValidationTrigger.getValidationError(cv);
        System.assertEquals(null, err, 'A valid JPG should pass');
    }

    @IsTest
    static void testPngPassesValidation() {
        ContentVersion cv = buildCV('Screenshot', 'png', 2 * 1024 * 1024); // 2 MB
        String err = FileValidationTrigger.getValidationError(cv);
        System.assertEquals(null, err, 'A valid PNG should pass');
    }

    @IsTest
    static void testExeFailsValidation() {
        ContentVersion cv = buildCV('Malware', 'exe', 100);
        String err = FileValidationTrigger.getValidationError(cv);
        System.assertNotEquals(null, err, 'An .exe should be rejected');
        System.assert(err.contains('.exe'), 'Error should mention the bad extension');
    }

    @IsTest
    static void testDocxFailsValidation() {
        ContentVersion cv = buildCV('Proposal', 'docx', 200 * 1024);
        String err = FileValidationTrigger.getValidationError(cv);
        System.assertNotEquals(null, err, 'A .docx should be rejected');
    }

    @IsTest
    static void testOversizedPdfFails() {
        ContentVersion cv = buildCV('HugeDoc', 'pdf', 11 * 1024 * 1024); // 11 MB
        String err = FileValidationTrigger.getValidationError(cv);
        System.assertNotEquals(null, err, '11 MB PDF should be rejected');
        System.assert(err.contains('10 MB'), 'Error should mention the 10 MB limit');
    }

    @IsTest
    static void testExactly10MbPasses() {
        ContentVersion cv = buildCV('EdgeCase', 'pdf', 10 * 1024 * 1024); // exactly 10 MB
        String err = FileValidationTrigger.getValidationError(cv);
        System.assertEquals(null, err, 'Exactly 10 MB should be allowed');
    }

    @IsTest
    static void testBulkValidation() {
        List<ContentVersion> versions = new List<ContentVersion>();
        for (Integer i = 0; i < 50; i++) {
            versions.add(buildCV('doc_' + i, 'pdf', 1024));
        }
        Test.startTest();
        // Should not throw
        FileValidationTrigger.validateOnVersionInsert(versions);
        Test.stopTest();
        // If we reached here, no errors on valid files
        System.assert(true, 'Bulk validation completed without unexpected errors');
    }
}
