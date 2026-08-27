package com.example.demo.chat.repository;

import com.example.demo.chat.entity.ChatMessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ChatMessageRepository extends JpaRepository<ChatMessageEntity, Long> {

    // ✅ Full chat history between two users (sorted)
    @Query("""
        SELECT m FROM ChatMessageEntity m
        WHERE (TRIM(m.senderId) = :user1 AND TRIM(m.receiverId) = :user2)
           OR (TRIM(m.senderId) = :user2 AND TRIM(m.receiverId) = :user1)
        ORDER BY m.sentAt ASC
    """)
    List<ChatMessageEntity> findConversation(
            @Param("user1") String user1,
            @Param("user2") String user2
    );

    // ✅ Admin inbox list: latest message per employee who messaged admin
    // - Oracle 11g: no FETCH FIRST
    // - Excludes admin->admin/self rows
    // - Uses KEEP(DENSE_RANK LAST ...) to pick last message + name based on sent_at
    @Query(value = """
        SELECT user_id, sender_name, last_message, last_time
        FROM (
          SELECT
            TRIM(sender_id) AS user_id,
            MAX(sender_name) KEEP (DENSE_RANK LAST ORDER BY sent_at) AS sender_name,
            MAX(message)     KEEP (DENSE_RANK LAST ORDER BY sent_at) AS last_message,
            MAX(sent_at) AS last_time
          FROM chat_messages
          WHERE TRIM(receiver_id) = TRIM(:adminId)
            AND TRIM(sender_id) <> TRIM(:adminId)
          GROUP BY TRIM(sender_id)
          ORDER BY MAX(sent_at) DESC
        )
        WHERE ROWNUM <= 200
        """, nativeQuery = true)
    List<Object[]> findConversationsForAdmin(@Param("adminId") String adminId);

    // ✅ (Optional) If you need: employees list who have chatted with admin (distinct)
    @Query(value = """
        SELECT DISTINCT TRIM(sender_id)
        FROM chat_messages
        WHERE TRIM(receiver_id) = TRIM(:adminId)
          AND TRIM(sender_id) <> TRIM(:adminId)
        """, nativeQuery = true)
    List<String> findDistinctSendersToAdmin(@Param("adminId") String adminId);
}
