package com.example.demo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.Table;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;

import java.util.Date;

@Entity
@Table(name = "AMS_APPLICANT_DETAILS")
@NamedQuery(
    name = "Applicant.findAllApplicants",
    query = "SELECT a FROM Applicant a"
)
public class Applicant {

    @Id
    @Column(name = "ID")
    private Integer id;

    @Column(name = "APPLYING_POSITION")
    private String applyingPosition;

    @Column(name = "FIRST_NAME")
    private String firstName;

    @Column(name = "MIDDLE_NAME")
    private String middleName;

    @Column(name = "LAST_NAME")
    private String lastName;

    @Column(name = "EMAIL")
    private String email;

    @Column(name = "MOBILE_NO")
    private String mobileNo;

    @Column(name = "CATEGORY")
    private String category;

    @Column(name = "GENDER")
    private Integer gender;

    @Column(name = "DOB")
    @Temporal(TemporalType.DATE)
    private Date dob;

    public Applicant() {}

    public Applicant(Integer id, String firstName, String middleName, String lastName) {
        this.id = id;
        this.firstName = firstName;
        this.middleName = middleName;
        this.lastName = lastName;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getApplyingPosition() { return applyingPosition; }
    public void setApplyingPosition(String applyingPosition) { this.applyingPosition = applyingPosition; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getMiddleName() { return middleName; }
    public void setMiddleName(String middleName) { this.middleName = middleName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getMobileNo() { return mobileNo; }
    public void setMobileNo(String mobileNo) { this.mobileNo = mobileNo; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public Integer getGender() { return gender; }
    public void setGender(Integer gender) { this.gender = gender; }

    public Date getDob() { return dob; }
    public void setDob(Date dob) { this.dob = dob; }

    public String getFullName() {
        StringBuilder fullName = new StringBuilder();
        if (firstName != null) fullName.append(firstName).append(" ");
        if (middleName != null) fullName.append(middleName).append(" ");
        if (lastName != null) fullName.append(lastName);
        return fullName.toString().trim();
    }

    public String getApplicantId() {
        return "APP" + String.format("%05d", id);
    }
}
