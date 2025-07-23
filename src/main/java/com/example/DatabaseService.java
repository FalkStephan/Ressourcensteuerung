package com.example;

// Import für jBcrypt hinzufügen
import org.mindrot.jbcrypt.BCrypt;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

public class DatabaseService {

    // (Die loadDatabaseProperties und getConnection Methoden bleiben unverändert)
    private static final Properties dbProperties = new Properties();
    private static boolean isLoaded = false;

    private static synchronized void loadDatabaseProperties() {
        if (isLoaded) return;
        try (InputStream input = DatabaseService.class.getClassLoader().getResourceAsStream("config.ini")) {
            if (input == null) throw new RuntimeException("Kritischer Fehler: Die Datei 'config.ini' konnte im 'resources'-Ordner nicht gefunden werden.");
            dbProperties.load(input);
            isLoaded = true;
        } catch (Exception ex) {
            throw new RuntimeException("Fehler beim Laden der config.ini: " + ex.getMessage(), ex);
        }
    }

    public static Connection getConnection() throws SQLException {
        loadDatabaseProperties();
        try {
            Class.forName("org.mariadb.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MariaDB JDBC Driver nicht gefunden.", e);
        }
        return DriverManager.getConnection(
            dbProperties.getProperty("database.url"),
            dbProperties.getProperty("database.user"),
            dbProperties.getProperty("database.password")
        );
    }
    
    // --- KORRIGIERTE METHODEN MIT jBCRYPT ---

    public static void init() {
        loadDatabaseProperties();
    }

    // **KORREKTUR:** Implementiert den korrekten Login-Flow mit Passwort-Überprüfung.
    public static Map<String, Object> findUser(String username, String plainTextPassword) throws SQLException {
        String sql = "SELECT * FROM users WHERE username = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                String storedHash = rs.getString("password_hash");

                // Überprüfe, ob das eingegebene Passwort mit dem gespeicherten Hash übereinstimmt.
                if (BCrypt.checkpw(plainTextPassword, storedHash)) {
                    Map<String, Object> user = new HashMap<>();
                    user.put("id", rs.getInt("id"));
                    user.put("username", rs.getString("username"));
                    user.put("abteilung", rs.getString("abteilung"));
                    user.put("can_manage_users", rs.getBoolean("can_manage_users"));
                    user.put("can_view_logbook", rs.getBoolean("can_view_logbook"));
                    return user; // Erfolg!
                }
            }
        }
        return null; // Benutzer nicht gefunden oder Passwort falsch.
    }
    
    // **KORREKTUR:** Hasht das Passwort vor dem Speichern.
    public static void addUser(String username, String plainTextPassword, boolean canManage, boolean canView, String abteilung) throws SQLException {
        // Generiere einen Salt und hashe das Passwort
        String hashedPassword = BCrypt.hashpw(plainTextPassword, BCrypt.gensalt());

        String sql = "INSERT INTO users (username, password_hash, can_manage_users, can_view_logbook, abteilung) VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            pstmt.setString(2, hashedPassword); // Speichere den Hash
            pstmt.setBoolean(3, canManage);
            pstmt.setBoolean(4, canView);
            pstmt.setString(5, abteilung);
            pstmt.executeUpdate();
        }
    }

    // (Die restlichen Methoden bleiben unverändert)
    public static Map<String, Object> getUserById(int id) throws SQLException { /*...*/ return null; }
    public static void deleteUser(int id, String deletedByUsername) throws SQLException { /*...*/ }
    public static void logAction(String action, String details, String username) throws SQLException { /*...*/ }
    public static List<Map<String, Object>> getLogs(String searchTerm, int offset, int limit) throws SQLException { /*...*/ return new ArrayList<>(); }
    public static int getTotalLogCount(String searchTerm) throws SQLException { /*...*/ return 0; }
    public static void saveContact(String name, String email, String message) throws SQLException { /*...*/ }
}