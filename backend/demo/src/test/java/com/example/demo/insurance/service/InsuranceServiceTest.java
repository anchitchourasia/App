package com.example.demo.insurance.service;

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

    // ─── uploadPdf: null filename → uses default name ─────────────────────────
    @Test
    void uploadPdf_nullFilename_usesDefaultName() throws IOException {
        when(repo.getOwnerUserId(1L)).thenReturn(Optional.of("user1"));

        MockMultipartFile file = new MockMultipartFile(
            "file", null, "application/pdf", "data".getBytes()
        );

        service.uploadPdf(1L, file, "user1");

        verify(fileRepo).savePdf(
            eq(1L),
            eq("insurance_1.pdf"),   // default name used
            eq("application/pdf"),
            anyLong(),
            any(),
            eq("user1")
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
            eq(1L),
            eq("test.pdf"),
            eq("application/pdf"),   // default mime used
            anyLong(),
            any(),
            eq("user1")
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
            eq(1L),
            eq("policy.pdf"),
            eq("application/pdf"),
            anyLong(),
            any(),
            eq("user1")
        );
    }
}