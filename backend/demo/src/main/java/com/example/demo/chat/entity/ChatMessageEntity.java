package com.example.demo.chat.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "CHAT_MESSAGES")
public class ChatMessageEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "chatSeq")
    @SequenceGenerator(name = "chatSeq", sequenceName = "CHAT_MESSAGES_SEQ", allocationSize = 1)
    private Long id;

    @Column(name = "SENDER_ID", nullable = false)
    private String senderId;

    @Column(name = "RECEIVER_ID", nullable = false)
    private String receiverId;

    @Column(name = "MESSAGE", nullable = false)
    private String message;

    @Column(name = "SENDER_NAME")
    private String senderName;

    @Column(name = "SENT_AT")
    private LocalDateTime sentAt;

    @PrePersist
    public void prePersist() {
        sentAt = LocalDateTime.now();
    }

    // Getters
    public Long getId()           { return id; }
    public String getSenderId()   { return senderId; }
    public String getReceiverId() { return receiverId; }
    public String getMessage()    { return message; }
    public String getSenderName() { return senderName; }
    public LocalDateTime getSentAt() { return sentAt; }

    // Setters
    public void setId(Long id)               { this.id = id; }
    public void setSenderId(String s)        { this.senderId = s; }
    public void setReceiverId(String r)      { this.receiverId = r; }
    public void setMessage(String m)         { this.message = m; }
    public void setSenderName(String n)      { this.senderName = n; }
    public void setSentAt(LocalDateTime t)   { this.sentAt = t; }
}
