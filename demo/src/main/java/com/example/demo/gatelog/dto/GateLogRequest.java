package com.example.demo.gatelog.dto;

public class GateLogRequest {

    private Integer permissionNo;
    private String action;
    private String enterBy;

    public GateLogRequest() {
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

    public String getEnterBy() {
        return enterBy;
    }

    public void setEnterBy(String enterBy) {
        this.enterBy = enterBy;
    }
}