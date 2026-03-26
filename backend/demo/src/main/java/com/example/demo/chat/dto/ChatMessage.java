package com.example.demo.chat.dto;

public class ChatMessage {
    private String senderId;
    private String receiverId;
    private String message;
    private String senderName;
    private String timestamp;

    public ChatMessage() {}

    public ChatMessage(String senderId, String receiverId,
                       String message, String senderName, String timestamp) {
        this.senderId = senderId;
        this.receiverId = receiverId;
        this.message = message;
        this.senderName = senderName;
        this.timestamp = timestamp;
    }

    public String getSenderId()   { return senderId; }
    public String getReceiverId() { return receiverId; }
    public String getMessage()    { return message; }
    public String getSenderName() { return senderName; }
    public String getTimestamp()  { return timestamp; }

    public void setSenderId(String senderId)     { this.senderId = senderId; }
    public void setReceiverId(String receiverId) { this.receiverId = receiverId; }
    public void setMessage(String message)       { this.message = message; }
    public void setSenderName(String senderName) { this.senderName = senderName; }
    public void setTimestamp(String timestamp)   { this.timestamp = timestamp; }
}
