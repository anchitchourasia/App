package com.example.demo.insurance.service;

import com.example.demo.insurance.dto.request.CreateInsuranceRequest;
import com.example.demo.insurance.dto.request.UpdateStatusRequest;
import com.example.demo.insurance.dto.response.InsuranceResponse;
import com.example.demo.insurance.exception.NotFoundException;
import com.example.demo.insurance.repository.InsuranceFileRepository;
import com.example.demo.insurance.repository.InsuranceRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class InsuranceServiceTest {

    @Mock
    private InsuranceRepository repo;

    @Mock
    private InsuranceFileRepository fileRepo;

    @InjectMocks
    private InsuranceService service;

    // ─── create ──────────────────────────────────────────────────────────────
    @Test
    void create_returnsId() {
        CreateInsuranceRequest req = new CreateInsuranceRequest(
            "u1", "CAR", "MH01AB1234", "COMPREHENSIVE",
            "2026-01-01", "2027-01-01", "HDFC"
        );
        when(repo.insertUpload("u1", "CAR", "MH01AB1234", "COMPREHENSIVE",
            "2026-01-01", "2027-01-01", "HDFC")).thenReturn(42L);

        long id = service.create(req);

        assertEquals(42L, id);
    }

    // ─── listUser ─────────────────────────────────────────────────────────────
    @Test
    void listUser_returnsEmptyList() {
        when(repo.listForUser("u1")).thenReturn(List.of());
        List<InsuranceResponse> result = service.listUser("u1");
        assertNotNull(result);
        assertTrue(result.isEmpty());
    }

    // ─── listAdmin ────────────────────────────────────────────────────────────
    @Test
    void listAdmin_returnsEmptyList() {
        when(repo.listForAdmin("PENDING")).thenReturn(List.of());
        List<InsuranceResponse> result = service.listAdmin("PENDING");
        assertNotNull(result);
        assertTrue(result.isEmpty());
    }

    // ─── getById: found ───────────────────────────────────────────────────────
    @Test
    void getById_found_returnsResponse() {
        InsuranceResponse mockResp = mock(InsuranceResponse.class);
        when(repo.findById(1L)).thenReturn(Optional.of(mockResp));
        InsuranceResponse result = service.getById(1L);
        assertEquals(mockResp, result);
    }

    // ─── getById: not found ───────────────────────────────────────────────────
    @Test
    void getById_notFound_throwsNotFoundException() {
        when(repo.findById(99L)).thenReturn(Optional.empty());
        assertThrows(NotFoundException.class, () -> service.getById(99L));
    }

    // ─── updateStatus: success ────────────────────────────────────────────────
    @Test
    void updateStatus_success_doesNotThrow() {
        UpdateStatusRequest req = new UpdateStatusRequest("APPROVED", "admin1", "looks good");
        when(repo.updateStatus(1L, "APPROVED", "admin1", "looks good")).thenReturn(1);
        assertDoesNotThrow(() -> service.updateStatus(1L, req));
    }

    // ─── updateStatus: not found ──────────────────────────────────────────────
    @Test
    void updateStatus_notFound_throwsNotFoundException() {
        UpdateStatusRequest req = new UpdateStatusRequest("APPROVED", "admin1", "note");
        when(repo.updateStatus(99L, "APPROVED", "admin1", "note")).thenReturn(0);
        assertThrows(NotFoundException.class, () -> service.updateStatus(99L, req));
    }

    // ─── downloadPdf: found ───────────────────────────────────────────────────
    @Test
    void downloadPdf_found_returnsPdfRow() {
        InsuranceFileRepository.PdfRow mockRow = mock(InsuranceFileRepository.PdfRow.class);
        when(fileRepo.loadPdf(1L)).thenReturn(Optional.of(mockRow));
        InsuranceFileRepository.PdfRow result = service.downloadPdf(1L);
        assertEquals(mockRow, result);
    }

    // ─── downloadPdf: not found ───────────────────────────────────────────────
    @Test
    void downloadPdf_notFound_throwsNotFoundException() {
        when(fileRepo.loadPdf(99L)).thenReturn(Optional.empty());
        assertThrows(NotFoundException.class, () -> service.downloadPdf(99L));
    }

    // ─── listUserNotifications ────────────────────────────────────────────────
    @Test
    void listUserNotifications_returnsEmptyList() {
        when(repo.listNotificationsForUser("u1")).thenReturn(List.of());
        List<InsuranceResponse> result = service.listUserNotifications("u1");
        assertNotNull(result);
        assertTrue(result.isEmpty());
    }

    // ─── uploadPdf: insurance id not found ───────────────────────────────────
    @Test
    void uploadPdf_insuranceNotFound_throwsNotFoundException() {
        when(repo.getOwnerUserId(1L)).thenReturn(Optional.empty());
        MockMultipartFile file = new MockMultipartFile(
            "file", "test.pdf", "application/pdf", "data".getBytes()
        );
        assertThrows(NotFoundException.class,
            () -> service.uploadPdf(1L, file, "user1"));
    }

    // ─── uploadPdf: null file ─────────────────────────────────────────────────
    @Test
    void uploadPdf_nullFile_throwsIllegalArgumentException() {
        when(repo.getOwnerUserId(1L)).thenReturn(Optional.of("user1"));
        assertThrows(IllegalArgumentException.class,
            () -> service.uploadPdf(1L, null, "user1"));
    }

    // ─── uploadPdf: empty file ────────────────────────────────────────────────
    @Test
    void uploadPdf_emptyFile_throwsIllegalArgumentException() {
        when(repo.getOwnerUserId(1L)).thenReturn(Optional.of("user1"));
        MockMultipartFile emptyFile = new MockMultipartFile(
            "file", "test.pdf", "application/pdf", new byte[0]
        );
        assertThrows(IllegalArgumentException.class,
            () -> service.uploadPdf(1L, emptyFile, "user1"));
    }

    // ─── uploadPdf: null filename → uses default name ────────────────────────
    @Test
    void uploadPdf_nullFilename_usesDefaultName() throws IOException {
        when(repo.getOwnerUserId(1L)).thenReturn(Optional.of("user1"));
        MockMultipartFile file = new MockMultipartFile(
            "file", null, "application/pdf", "data".getBytes()
        );
        service.uploadPdf(1L, file, "user1");
        verify(fileRepo).savePdf(
            eq(1L), eq("insurance_1.pdf"), eq("application/pdf"),
            anyLong(), any(), eq("user1")
        );
    }

    // ─── uploadPdf: null content type → uses default mime ────────────────────
    @Test
    void uploadPdf_nullContentType_usesDefaultMime() throws IOException {
        when(repo.getOwnerUserId(1L)).thenReturn(Optional.of("user1"));
        MockMultipartFile file = new MockMultipartFile(
            "file", "test.pdf", null, "data".getBytes()
        );
        service.uploadPdf(1L, file, "user1");
        verify(fileRepo).savePdf(
            eq(1L), eq("test.pdf"), eq("application/pdf"),
            anyLong(), any(), eq("user1")
        );
    }

    // ─── uploadPdf: valid file → saves successfully ───────────────────────────
    @Test
    void uploadPdf_validFile_savesSuccessfully() throws IOException {
        when(repo.getOwnerUserId(1L)).thenReturn(Optional.of("user1"));
        MockMultipartFile file = new MockMultipartFile(
            "file", "policy.pdf", "application/pdf", "pdfdata".getBytes()
        );
        service.uploadPdf(1L, file, "user1");
        verify(fileRepo).savePdf(
            eq(1L), eq("policy.pdf"), eq("application/pdf"),
            anyLong(), any(), eq("user1")
        );
    }
}