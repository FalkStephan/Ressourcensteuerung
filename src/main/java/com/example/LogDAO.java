package com.example;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class LogDAO {
    public void addLogEintrag(LogEintrag logEintrag) throws SQLException {
        String sql = "INSERT INTO log_eintraege (timestamp, aktion, beschreibung) VALUES (?, ?, ?)";
        try (Connection conn = DatabaseService.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setTimestamp(1, logEintrag.getTimestamp());
            pstmt.setString(2, logEintrag.getAktion());
            pstmt.setString(3, logEintrag.getBeschreibung());
            pstmt.executeUpdate();
        }
    }
}