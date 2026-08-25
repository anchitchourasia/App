package com.example.demo.chat.config;

import org.springframework.stereotype.Service;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AdminAvailabilityService {

    private final Map<String, Boolean> manualAvailability = new ConcurrentHashMap<>();

    public boolean isAvailable(String userId) {
        // DEFAULT FALSE: Admin is offline until they manually click "Online"
        return manualAvailability.getOrDefault(userId, false);
    }

    public void setAvailable(String userId, boolean available) {
        if (userId == null || userId.isBlank()) return;
        manualAvailability.put(userId.trim(), available);
    }
}
