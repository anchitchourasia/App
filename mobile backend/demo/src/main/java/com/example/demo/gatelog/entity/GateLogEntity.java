package com.example.demo.gatelog.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;

@Entity
@Table(name = "CVPS_GATE_LOGS")
public class GateLogEntity {

    @Id
    @GeneratedValue(
        strategy = GenerationType.SEQUENCE,
        generator = "gate_log_sequence"
    )
    @SequenceGenerator(
        name = "gate_log_sequence",
        sequenceName = "SEQ_CVPS_GATE_LOGS",
        allocationSize = 1
    )
    @Column(name = "GATE_LOG_ID")
    private Long gateLogId;

    @Column(name = "PERMISSION_NO", nullable = false)
    private Integer permissionNo;

    @Column(name = "ACTION", nullable = false, length = 3)
    private String action;

    @Column(name = "ACTION_DATE", nullable = false)
    private LocalDate actionDate;

    @Column(name = "ACTION_TIME", nullable = false, length = 8)
    private String actionTime;

    @Column(name = "ENTER_BY", nullable = false, length = 50)
    private String enterBy;

    @Column(name = "CREATED_AT", nullable = false)
    private LocalDateTime createdAt;

    public GateLogEntity() {
    }

    public Long getGateLogId() {
        return gateLogId;
    }

    public void setGateLogId(Long gateLogId) {
        this.gateLogId = gateLogId;
    }

    public Integer getPermissionNo() {
        return permissionNo;
    }

    public void setPermissionNo(Integer permissionNo) {
        this.permissionNo = permissionNo;
    }

    public String getAction() {
        return action;
    }

    public void setAction(String action) {
        this.action = action;
    }

    public LocalDate getActionDate() {
        return actionDate;
    }

    public void setActionDate(LocalDate actionDate) {
        this.actionDate = actionDate;
    }

    public String getActionTime() {
        return actionTime;
    }

    public void setActionTime(String actionTime) {
        this.actionTime = actionTime;
    }

    public String getEnterBy() {
        return enterBy;
    }

    public void setEnterBy(String enterBy) {
        this.enterBy = enterBy;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}