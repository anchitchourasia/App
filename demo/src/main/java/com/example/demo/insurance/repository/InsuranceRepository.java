package com.example.demo.insurance.repository;

import com.example.demo.insurance.dto.response.InsuranceResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

import java.sql.PreparedStatement;
import java.util.List;
import java.util.Optional;

@Repository
public class InsuranceRepository {

  private final JdbcTemplate jdbc;

  public InsuranceRepository(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  private final RowMapper<InsuranceResponse> mapper = (rs, i) -> new InsuranceResponse(
      rs.getLong("ID"),
      rs.getString("USER_ID"),
      rs.getString("VEHICLE_TYPE"),
      rs.getString("VEHICLE_NUMBER"),
      rs.getString("INSURANCE_TYPE"),
      rs.getString("VALID_FROM"),
      rs.getString("VALID_TO"),
      rs.getString("COMPANY_NAME"),
      rs.getString("STATUS"),
      rs.getString("ADMIN_NOTE"),
      rs.getString("REVIEWED_BY"),
      rs.getString("REVIEWED_AT"),
      rs.getString("CREATED_AT"),
      rs.getInt("HAS_PDF") == 1
  );

  private static final String BASE_SELECT = """
    SELECT u.ID, u.USER_ID, u.VEHICLE_TYPE, u.VEHICLE_NUMBER, u.INSURANCE_TYPE,
           TO_CHAR(u.VALID_FROM,'YYYY-MM-DD') VALID_FROM,
           TO_CHAR(u.VALID_TO,'YYYY-MM-DD') VALID_TO,
           u.COMPANY_NAME, u.STATUS, u.ADMIN_NOTE, u.REVIEWED_BY,
           TO_CHAR(u.REVIEWED_AT,'YYYY-MM-DD"T"HH24:MI:SS') REVIEWED_AT,
           TO_CHAR(u.CREATED_AT,'YYYY-MM-DD"T"HH24:MI:SS') CREATED_AT,
           CASE WHEN f.INSURANCE_ID IS NULL THEN 0 ELSE 1 END HAS_PDF
    FROM INSURANCE_UPLOADS u
    LEFT JOIN INSURANCE_FILES f ON f.INSURANCE_ID = u.ID
  """;

  public long insertUpload(
      String userId, String vehicleType, String vehicleNumber,
      String insuranceType, String validFrom, String validTo, String companyName
  ) {
    String sql = """
      INSERT INTO INSURANCE_UPLOADS
      (USER_ID, VEHICLE_TYPE, VEHICLE_NUMBER, INSURANCE_TYPE, VALID_FROM, VALID_TO, COMPANY_NAME, STATUS)
      VALUES (?, ?, ?, ?, TO_DATE(?, 'YYYY-MM-DD'), TO_DATE(?, 'YYYY-MM-DD'), ?, 'PENDING')
    """;

    KeyHolder kh = new GeneratedKeyHolder();
    jdbc.update(con -> {
      PreparedStatement ps = con.prepareStatement(sql, new String[]{"ID"});
      ps.setString(1, userId);
      ps.setString(2, vehicleType);
      ps.setString(3, vehicleNumber);
      ps.setString(4, insuranceType);
      ps.setString(5, validFrom);
      ps.setString(6, validTo);
      ps.setString(7, companyName);
      return ps;
    }, kh);

    Number key = kh.getKey();
    if (key == null) {
      throw new IllegalStateException("Insert ok but ID not returned (Oracle trigger/sequence).");
    }
    return key.longValue();
  }

  // used by InsuranceService.getById()
  public Optional<InsuranceResponse> findById(long id) {
    String sql = BASE_SELECT + """
      WHERE u.ID = ?
    """;
    return jdbc.query(sql, mapper, id).stream().findFirst();
  }

  public List<InsuranceResponse> listForUser(String userId) {
    String sql = BASE_SELECT + """
      WHERE u.USER_ID = ?
      ORDER BY u.ID DESC
    """;
    return jdbc.query(sql, mapper, userId);
  }

  public List<InsuranceResponse> listForAdmin(String statusOrNull) {
    boolean hasStatus = (statusOrNull != null && !statusOrNull.isBlank());
    String sql = BASE_SELECT
        + (hasStatus ? " WHERE u.STATUS = ? " : "")
        + " ORDER BY u.ID DESC";

    return hasStatus
        ? jdbc.query(sql, mapper, statusOrNull)
        : jdbc.query(sql, mapper);
  }

  public int updateStatus(long id, String status, String reviewedBy, String adminNote) {
    String sql = """
      UPDATE INSURANCE_UPLOADS
      SET STATUS = ?, REVIEWED_BY = ?, ADMIN_NOTE = ?, REVIEWED_AT = SYSTIMESTAMP
      WHERE ID = ?
    """;
    return jdbc.update(sql, status, reviewedBy, adminNote, id);
  }

  public Optional<String> getOwnerUserId(long id) {
    String sql = "SELECT USER_ID FROM INSURANCE_UPLOADS WHERE ID = ?";
    List<String> rows = jdbc.query(sql, (rs, i) -> rs.getString(1), id);
    return rows.isEmpty() ? Optional.empty() : Optional.ofNullable(rows.get(0));
  }

  // NEW: derived "notifications" (no separate table)
  public List<InsuranceResponse> listNotificationsForUser(String userId) {
    String sql = BASE_SELECT + """
      WHERE u.USER_ID = ?
        AND u.REVIEWED_AT IS NOT NULL
        AND u.STATUS IN ('APPROVED','MODIFY')
      ORDER BY u.REVIEWED_AT DESC NULLS LAST
    """;

    return jdbc.query(sql, mapper, userId);
  }
}
 