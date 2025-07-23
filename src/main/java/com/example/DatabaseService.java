package com.example;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.StringJoiner;
import org.mindrot.jbcrypt.BCrypt;

public class DatabaseService {

    private static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(
            ConfigService.getDbUrl(),
            ConfigService.getDbUser(),
            ConfigService.getDbPassword()
        );
    }

    public static void init() {
        try {
            Class.forName("org.mariadb.jdbc.Driver");
            try (Connection conn = getConnection(); Statement stmt = conn.createStatement()) {
                // ... kontaktSql und logSql unverändert ...

                // GEÄNDERT: users-Tabelle mit neuen Rechten
                String userSql = "CREATE TABLE IF NOT EXISTS users (" +
                                 " id INTEGER PRIMARY KEY AUTO_INCREMENT," +
                                 " username VARCHAR(255) NOT NULL UNIQUE," +
                                 " password_hash VARCHAR(255) NOT NULL," +
                                 " can_manage_users BOOLEAN NOT NULL DEFAULT FALSE," +
                                 " can_view_logbook BOOLEAN NOT NULL DEFAULT FALSE);";
                stmt.execute(userSql);

                createAdminIfNotExists(conn);
            }
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("Konnte die Datenbank nicht initialisieren.", e);
        }
    }

    private static void createAdminIfNotExists(Connection conn) throws SQLException {
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM users WHERE username = 'admin'")) {
            if (rs.next() && rs.getInt(1) == 0) {
                String hashedPassword = BCrypt.hashpw("admin", BCrypt.gensalt());
                // GEÄNDERT: Setzt beide Rechte für den Admin
                String sql = "INSERT INTO users(username, password_hash, can_manage_users, can_view_logbook) VALUES(?, ?, ?, ?)";
                try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                    pstmt.setString(1, "admin");
                    pstmt.setString(2, hashedPassword);
                    pstmt.setBoolean(3, true); // Benutzerverwaltung
                    pstmt.setBoolean(4, true); // Logbuch
                    pstmt.executeUpdate();
                    System.out.println("Standard-Admin 'admin' wurde erstellt.");
                    logAction("System", "Erstellen", "Standard-Admin 'admin' wurde angelegt. [Rechte: Benutzerverwaltung, Logbuch]");
                }
            }
        }
    }
    
    public static void logAction(String username, String action, String description) throws SQLException {
        String sql = "INSERT INTO logbook(timestamp, username, action, description) VALUES (?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setTimestamp(1, Timestamp.from(Instant.now()));
            pstmt.setString(2, username);
            pstmt.setString(3, action);
            pstmt.setString(4, description);
            pstmt.executeUpdate();
        }
    }

    public static List<Map<String, Object>> getLogs(String search, int page, int limit) {
        List<Map<String, Object>> logs = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT timestamp, username, action, description FROM logbook");
        
        if (search != null && !search.trim().isEmpty()) {
            sql.append(" WHERE username LIKE ? OR action LIKE ? OR description LIKE ?");
        }
        
        sql.append(" ORDER BY timestamp DESC LIMIT ? OFFSET ?");

        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            int paramIndex = 1;
            if (search != null && !search.trim().isEmpty()) {
                String searchTerm = "%" + search + "%";
                pstmt.setString(paramIndex++, searchTerm);
                pstmt.setString(paramIndex++, searchTerm);
                pstmt.setString(paramIndex++, searchTerm);
            }
            
            pstmt.setInt(paramIndex++, limit);
            pstmt.setInt(paramIndex++, (page - 1) * limit);
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> log = new HashMap<>();
                log.put("timestamp", rs.getTimestamp("timestamp"));
                log.put("username", rs.getString("username"));
                log.put("action", rs.getString("action"));
                log.put("description", rs.getString("description"));
                logs.add(log);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return logs;
    }
    
    public static int getTotalLogCount(String search) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM logbook");
        if (search != null && !search.trim().isEmpty()) {
            sql.append(" WHERE username LIKE ? OR action LIKE ? OR description LIKE ?");
        }

        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            if (search != null && !search.trim().isEmpty()) {
                String searchTerm = "%" + search + "%";
                pstmt.setString(1, searchTerm);
                pstmt.setString(2, searchTerm);
                pstmt.setString(3, searchTerm);
            }

            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public static void saveContact(String name, String email, String actor) throws SQLException {
        String sql = "INSERT INTO kontakte(name, email) VALUES(?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, name);
            pstmt.setString(2, email);
            pstmt.executeUpdate();
            
            String description = String.format("Kontakt angelegt. [name=%s, email=%s]", name, email);
            logAction(actor, "Erstellen", description);
        }
    }
    
    public static List<Map<String, String>> getContacts() {
        List<Map<String, String>> contacts = new ArrayList<>();
        String sql = "SELECT name, email FROM kontakte ORDER BY name";
        try (Connection conn = getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Map<String, String> contact = new HashMap<>();
                contact.put("name", rs.getString("name"));
                contact.put("email", rs.getString("email"));
                contacts.add(contact);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return contacts;
    }

    public static Map<String, Object> findUser(String username, String password) {
        // GEÄNDERT: Liest die neuen Rechte-Spalten
        String sql = "SELECT username, password_hash, can_manage_users, can_view_logbook FROM users WHERE username = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                String hashedPassword = rs.getString("password_hash");
                if (BCrypt.checkpw(password, hashedPassword)) {
                    Map<String, Object> user = new HashMap<>();
                    user.put("username", rs.getString("username"));
                    user.put("can_manage_users", rs.getBoolean("can_manage_users"));
                    user.put("can_view_logbook", rs.getBoolean("can_view_logbook"));
                    return user;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
    
    public static List<Map<String, Object>> getAllUsers() {
        // GEÄNDERT: Liest die neuen Rechte-Spalten
        List<Map<String, Object>> users = new ArrayList<>();
        String sql = "SELECT id, username, can_manage_users, can_view_logbook FROM users ORDER BY username";
        try (Connection conn = getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Map<String, Object> user = new HashMap<>();
                user.put("id", rs.getInt("id"));
                user.put("username", rs.getString("username"));
                user.put("can_manage_users", rs.getBoolean("can_manage_users"));
                user.put("can_view_logbook", rs.getBoolean("can_view_logbook"));
                users.add(user);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return users;
    }

    public static void addUser(String username, String password, boolean canManageUsers, boolean canViewLogbook, String actor) throws SQLException {
        String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
        // GEÄNDERT: Schreibt in die neuen Rechte-Spalten
        String sql = "INSERT INTO users(username, password_hash, can_manage_users, can_view_logbook) VALUES(?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            pstmt.setString(2, hashedPassword);
            pstmt.setBoolean(3, canManageUsers);
            pstmt.setBoolean(4, canViewLogbook);
            pstmt.executeUpdate();
            
            String description = String.format("Benutzer angelegt. [username=%s, benutzerverwaltung=%b, logbuch=%b]", username, canManageUsers, canViewLogbook);
            logAction(actor, "Erstellen", description);
        }
    }

    public static void updateUser(int id, String username, String password, boolean canManageUsers, boolean canViewLogbook, String actor) throws SQLException {
    Map<String, Object> oldUser = getUserById(id);
    if (oldUser == null) {
        throw new SQLException("Benutzer mit ID " + id + " nicht gefunden.");
    }
    
    String oldUsername = (String) oldUser.get("username");
    boolean oldCanManageUsers = (Boolean) oldUser.get("can_manage_users");
    boolean oldCanViewLogbook = (Boolean) oldUser.get("can_view_logbook");

    StringJoiner changes = new StringJoiner(", ");
    if (!oldUsername.equals(username)) {
        changes.add(String.format("username: '%s' -> '%s'", oldUsername, username));
    }
    if (oldCanManageUsers != canManageUsers) {
        changes.add(String.format("Benutzerverwaltung: '%b' -> '%b'", oldCanManageUsers, canManageUsers));
    }
    if (oldCanViewLogbook != canViewLogbook) {
        changes.add(String.format("Logbuch: '%b' -> '%b'", oldCanViewLogbook, canViewLogbook));
    }
    
    StringBuilder sql = new StringBuilder("UPDATE users SET username = ?, can_manage_users = ?, can_view_logbook = ?");
    boolean passwordChanged = (password != null && !password.isEmpty());
    if (passwordChanged) {
        sql.append(", password_hash = ?");
        changes.add("password: 'geändert'");
    }
    sql.append(" WHERE id = ?");

    try (Connection conn = getConnection();
         PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
        
        pstmt.setString(1, username);
        pstmt.setBoolean(2, canManageUsers);
        pstmt.setBoolean(3, canViewLogbook);
        int paramIndex = 4;
        if (passwordChanged) {
            String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
            pstmt.setString(paramIndex++, hashedPassword);
        }
        pstmt.setInt(paramIndex, id);
        pstmt.executeUpdate();

        String description = (changes.length() > 0)
            ? String.format("Benutzer '%s' (ID: %d) aktualisiert. Änderungen: [%s]", oldUsername, id, changes.toString())
            : String.format("Benutzer '%s' (ID: %d) bearbeitet, keine Änderungen vorgenommen.", oldUsername, id);
        logAction(actor, "Bearbeiten", description);
    }
}
    
    public static void deleteUser(int id, String actor) throws SQLException {
        String username = getUserById(id).get("username").toString();
        String sql = "DELETE FROM users WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            pstmt.executeUpdate();
            logAction(actor, "Löschen", "Benutzer '" + username + "' (ID: " + id + ") wurde gelöscht.");
        }
    }

    public static Map<String, Object> getUserById(int id) {
        // KORRIGIERT: Wählt jetzt die neuen Rechte-Spalten aus
        String sql = "SELECT id, username, can_manage_users, can_view_logbook FROM users WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                Map<String, Object> user = new HashMap<>();
                user.put("id", rs.getInt("id"));
                user.put("username", rs.getString("username"));
                // KORRIGIERT: Liest die neuen Rechte-Spalten
                user.put("can_manage_users", rs.getBoolean("can_manage_users"));
                user.put("can_view_logbook", rs.getBoolean("can_view_logbook"));
                return user;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
}