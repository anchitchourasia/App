package com.example.demo.insurance.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.io.InputStream;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Optional;

@Repository
public class InsuranceFileRepository {

  public record PdfRow(String fileName, String mimeType, long sizeBytes, InputStream stream) {}
  
  private final JdbcTemplate jdbc;

  public InsuranceFileRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  // Upsert: 1 PDF per insuranceId (unique constraint)
  public void savePdf(long insuranceId, String fileName, String mimeType, long sizeBytes, InputStream dataStream, String uploadedBy) {
    // MERGE is typical in Oracle to upsert
    String sql = """
      MERGE INTO INSURANCE_FILES t
      USING (SELECT ? AS INSURANCE_ID FROM dual) s
      ON (t.INSURANCE_ID = s.INSURANCE_ID)
      WHEN MATCHED THEN UPDATE SET
        FILE_NAME = ?, MIME_TYPE = ?, SIZE_BYTES = ?, CONTENT_BLOB = ?, UPLOADED_AT = SYSTIMESTAMP, UPLOADED_BY = ?
      WHEN NOT MATCHED THEN INSERT
        (INSURANCE_ID, FILE_NAME, MIME_TYPE, SIZE_BYTES, CONTENT_BLOB, UPLOADED_AT, UPLOADED_BY)
        VALUES (?, ?, ?, ?, ?, SYSTIMESTAMP, ?)
    """;

    jdbc.update(con -> {
      PreparedStatement ps = con.prepareStatement(sql);
      int i = 1;
      ps.setLong(i++, insuranceId);

      ps.setString(i++, fileName);
      ps.setString(i++, mimeType);
      ps.setLong(i++, sizeBytes);
      ps.setBinaryStream(i++, dataStream, sizeBytes); // streaming insert [Oracle LOB pattern] [web:8131]
      ps.setString(i++, uploadedBy);

      ps.setLong(i++, insuranceId);
      ps.setString(i++, fileName);
      ps.setString(i++, mimeType);
      ps.setLong(i++, sizeBytes);
      ps.setBinaryStream(i++, dataStream, sizeBytes);
      ps.setString(i++, uploadedBy);
      return ps;
    });
  }

  public Optional<PdfRow> loadPdf(long insuranceId) {
    String sql = """
      SELECT FILE_NAME, MIME_TYPE, SIZE_BYTES, CONTENT_BLOB
      FROM INSURANCE_FILES
      WHERE INSURANCE_ID = ?
    """;

    return jdbc.query(sql, (ResultSet rs) -> {
      if (!rs.next()) return Optional.empty();
      InputStream in = rs.getBinaryStream("CONTENT_BLOB");
      return Optional.of(new PdfRow(
          rs.getString("FILE_NAME"),
          rs.getString("MIME_TYPE"),
          rs.getLong("SIZE_BYTES"),
          in
      ));
    }, insuranceId);
  }
}
