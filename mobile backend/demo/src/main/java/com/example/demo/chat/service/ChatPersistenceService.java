package com.example.demo.chat.service;

import com.example.demo.chat.dto.ChatMessage;
import com.example.demo.chat.entity.ChatMessageEntity;
import com.example.demo.chat.repository.ChatMessageRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;

@Service
public class ChatPersistenceService {

    private final ChatMessageRepository chatRepo;

    public ChatPersistenceService(ChatMessageRepository chatRepo) {
        this.chatRepo = chatRepo;
    }

    // ✅ Save message to DB (sets sentAt so "latest message per user" works)
    public ChatMessageEntity saveMessage(ChatMessage msg) {
        ChatMessageEntity entity = new ChatMessageEntity();
        entity.setSenderId(safeTrim(msg.getSenderId()));
        entity.setReceiverId(safeTrim(msg.getReceiverId()));
        entity.setMessage(msg.getMessage() == null ? "" : msg.getMessage());
        entity.setSenderName(msg.getSenderName() == null ? "" : msg.getSenderName());

        // IMPORTANT: ensure sentAt is always present
        entity.setSentAt(LocalDateTime.now());

        return chatRepo.save(entity);
    }

    // ✅ Full chat history between 2 users
    public List<ChatMessageEntity> getHistory(String user1, String user2) {
        return chatRepo.findConversation(safeTrim(user1), safeTrim(user2));
    }

    // ✅ Raw rows for admin inbox (recommended for controller mapping)
    public List<Object[]> getConversationsForAdminRaw(String adminId) {
        return chatRepo.findConversationsForAdmin(safeTrim(adminId));
    }

    // ✅ If you still want Map output (Flutter friendly)
    public List<Map<String, String>> getConversationsForAdmin(String adminId) {
        List<Object[]> rows = getConversationsForAdminRaw(adminId);

        List<Map<String, String>> result = new ArrayList<>();
        for (Object[] row : rows) {
            Map<String, String> map = new LinkedHashMap<>();
            map.put("userId",      rowValue(row, 0));
            map.put("senderName",  rowValue(row, 1));
            map.put("lastMessage", rowValue(row, 2));
            map.put("lastTime",    rowValue(row, 3));
            result.add(map);
        }
        return result;
    }

    private static String rowValue(Object[] row, int i) {
        if (row == null || row.length <= i || row[i] == null) return "";
        return row[i].toString();
    }

    private static String safeTrim(String s) {
        return s == null ? "" : s.trim();
    }
}
