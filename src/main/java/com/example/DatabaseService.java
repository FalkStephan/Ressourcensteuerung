package com.example;

import java.sql.Connection;
import java.sql.Date;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
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
                String userSql = "CREATE TABLE IF NOT EXISTS users (" +
                        " id INTEGER PRIMARY KEY AUTO_INCREMENT," +
                        " username VARCHAR(255) NOT NULL UNIQUE," +
                        " password_hash VARCHAR(255) NOT NULL," +
                        " name VARCHAR(255) NOT NULL," +
                        " vorname VARCHAR(255) NOT NULL," +
                        " stelle VARCHAR(255)," +
                        " team VARCHAR(255)," +
                        " abteilung VARCHAR(255) NULL," +
                        " active BOOLEAN NOT NULL DEFAULT TRUE," +
                        " is_user BOOLEAN NOT NULL DEFAULT TRUE," +
                        " can_manage_users BOOLEAN NOT NULL DEFAULT FALSE," +
                        " can_view_logbook BOOLEAN NOT NULL DEFAULT FALSE," +
                        " can_manage_feiertage BOOLEAN NOT NULL DEFAULT FALSE," +
                        " INDEX idx_abteilung (abteilung)," +
                        " see_all_users BOOLEAN NOT NULL DEFAULT FALSE," +
                        " can_manage_calendar BOOLEAN NOT NULL DEFAULT FALSE," +
                        " can_manage_capacities BOOLEAN NOT NULL DEFAULT FALSE," +
                        " can_manage_settings BOOLEAN NOT NULL DEFAULT FALSE," +
                        " can_manage_calendar_overview BOOLEAN NOT NULL DEFAULT FALSE," +
                        " can_manage_tasks BOOLEAN NOT NULL DEFAULT FALSE);";
                stmt.execute(userSql);

                // Spalten für bestehende Installationen hinzufügen (sicherstellen, dass alle vorhanden sind)
                try { stmt.execute("ALTER TABLE users ADD COLUMN can_manage_feiertage BOOLEAN NOT NULL DEFAULT FALSE"); } catch (Exception e) { /* Spalte existiert evtl. schon */ }
                try { stmt.execute("ALTER TABLE users ADD COLUMN see_all_users BOOLEAN NOT NULL DEFAULT FALSE"); } catch (Exception e) { /* Spalte existiert evtl. schon */ }
                try { stmt.execute("ALTER TABLE users ADD COLUMN can_manage_calendar BOOLEAN NOT NULL DEFAULT FALSE"); } catch (Exception e) { /* Spalte existiert evtl. schon */ }
                try { stmt.execute("ALTER TABLE users ADD COLUMN can_manage_calendar_overview BOOLEAN NOT NULL DEFAULT FALSE"); } catch (Exception e) { /* Spalte existiert evtl. schon */ }
                try { stmt.execute("ALTER TABLE users ADD COLUMN can_manage_capacities BOOLEAN NOT NULL DEFAULT FALSE"); } catch (Exception e) { /* Spalte existiert evtl. schon */ }
                try { stmt.execute("ALTER TABLE users ADD COLUMN can_manage_settings BOOLEAN NOT NULL DEFAULT FALSE"); } catch (Exception e) { /* Spalte existiert evtl. schon */ }
                try { stmt.execute("ALTER TABLE users ADD COLUMN can_manage_tasks BOOLEAN NOT NULL DEFAULT FALSE"); } catch (Exception e) { /* Spalte existiert evtl. schon */ }
                try { stmt.execute("ALTER TABLE task_statuses ADD COLUMN color_code VARCHAR(7) DEFAULT '#FFFFFF'"); } catch (Exception e) { /* Spalte existiert evtl. schon */ }
                try { stmt.execute("ALTER TABLE tasks ADD COLUMN abteilung VARCHAR(255)"); } catch (SQLException e) {}
               
                String mitarbeiterSql = "CREATE TABLE IF NOT EXISTS mitarbeiter (" +
                        " id INTEGER PRIMARY KEY AUTO_INCREMENT," +
                        " name VARCHAR(255) NOT NULL," +
                        " stelle VARCHAR(255)," +
                        " team VARCHAR(255)," +
                        " abteilung VARCHAR(255) NOT NULL);";
                stmt.execute(mitarbeiterSql);
                
                String feiertageSql = "CREATE TABLE IF NOT EXISTS feiertage (" +
                        " id INTEGER PRIMARY KEY AUTO_INCREMENT," +
                        " datum DATE NOT NULL," +
                        " bezeichnung VARCHAR(255) NOT NULL);";
                stmt.execute(feiertageSql);
                
                String absenceSql = "CREATE TABLE IF NOT EXISTS user_absences (" +
                        " id INTEGER PRIMARY KEY AUTO_INCREMENT," +
                        " user_id INTEGER NOT NULL," +
                        " start_date DATE NOT NULL," +
                        " end_date DATE NOT NULL," +
                        " reason VARCHAR(255)," +
                        " FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);";
                stmt.execute(absenceSql);

                String capacitiySql = "CREATE TABLE IF NOT EXISTS user_capacities (" +
                        " id INTEGER PRIMARY KEY AUTO_INCREMENT," +
                        " user_id INTEGER NOT NULL," +
                        " start_date DATE NOT NULL," +
                        " capacity_percent INTEGER NOT NULL," +
                        " FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);";
                stmt.execute(capacitiySql);

                // Tabelle für Aufgaben-Status
                String statusSql = "CREATE TABLE IF NOT EXISTS task_statuses (" +
                        " id INTEGER PRIMARY KEY AUTO_INCREMENT," +
                        " name VARCHAR(255) NOT NULL," +
                        " active BOOLEAN NOT NULL DEFAULT TRUE," +
                        " sort_order INTEGER NOT NULL DEFAULT 0," +
                        " color_code VARCHAR(7) NOT NULL DEFAULT '#FFFFFF');";
                stmt.execute(statusSql);

                // Tabelle für Aufgaben
                String taskSql = "CREATE TABLE IF NOT EXISTS tasks (" +
                        " id INTEGER PRIMARY KEY AUTO_INCREMENT," +
                        " name VARCHAR(255) NOT NULL," +
                        " start_date DATE," +
                        " end_date DATE," +
                        " effort_days DECIMAL(10, 2)," +
                        " status_id INTEGER," +
                        " progress_percent INTEGER DEFAULT 0," +
                        " abteilung VARCHAR(255)," +
                        " FOREIGN KEY(status_id) REFERENCES task_statuses(id));";
                stmt.execute(taskSql);
                


                createAdminIfNotExists(conn);
            }
        } catch (Exception e) {
            // Zeile 85 in der Fehlermeldung
            throw new RuntimeException("Konnte die Datenbank nicht initialisieren.", e);
        }
    }

    private static void createAdminIfNotExists(Connection conn) throws SQLException {
        if (getUserByUsername("admin") == null) {
            String hashedPassword = BCrypt.hashpw("admin", BCrypt.gensalt());
            String sql = "INSERT INTO users(username, password_hash, name, vorname, active, is_user, can_manage_users, can_view_logbook, can_manage_feiertage, see_all_users, can_manage_calendar, can_manage_capacities, can_manage_settings, can_manage_tasks, can_manage_calendar_overview) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, "admin");
                pstmt.setString(2, hashedPassword);
                pstmt.setString(3, "Admin");
                pstmt.setString(4, "Super");
                pstmt.setBoolean(5, true);
                pstmt.setBoolean(6, true);
                pstmt.setBoolean(7, true);
                pstmt.setBoolean(8, true);
                pstmt.setBoolean(9, true);
                pstmt.setBoolean(10, true);
                pstmt.setBoolean(11, true); // can_manage_calendar
                pstmt.setBoolean(12, true); // can_manage_capacities
                pstmt.setBoolean(13, true); // can_manage_settings
                pstmt.setBoolean(14, true); // can_manage_tasks
                pstmt.setBoolean(15, true); // can_manage_calendar_overview
                pstmt.executeUpdate();
            }
        }
    }


    // ####################
    // USER
    // ####################
    
    private static Map<String, Object> mapUser(ResultSet rs) throws SQLException {
        Map<String, Object> user = new HashMap<>();
        user.put("id", rs.getInt("id"));
        user.put("username", rs.getString("username"));
        user.put("name", rs.getString("name"));
        user.put("vorname", rs.getString("vorname"));
        user.put("stelle", rs.getString("stelle"));
        user.put("team", rs.getString("team"));
        user.put("abteilung", rs.getString("abteilung"));
        user.put("active", rs.getBoolean("active"));
        user.put("is_user", rs.getBoolean("is_user"));
        user.put("can_manage_users", rs.getBoolean("can_manage_users"));
        user.put("can_view_logbook", rs.getBoolean("can_view_logbook"));
        user.put("can_manage_feiertage", rs.getBoolean("can_manage_feiertage"));
        user.put("see_all_users", rs.getBoolean("see_all_users"));
        user.put("can_manage_calendar", rs.getBoolean("can_manage_calendar"));
        user.put("can_manage_capacities", rs.getBoolean("can_manage_capacities"));
        user.put("can_manage_settings", rs.getBoolean("can_manage_settings"));
        user.put("can_manage_tasks", rs.getBoolean("can_manage_tasks"));
        user.put("can_manage_calendar_overview", rs.getBoolean("can_manage_calendar_overview"));
        return user;
    }

    public static Map<String, Object> findUser(String username, String password) {
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM users WHERE username = ?")) {
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next() && BCrypt.checkpw(password, rs.getString("password_hash"))) {
                return mapUser(rs);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }
    
    public static Map<String, Object> getUserByUsername(String username) {
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM users WHERE username = ?")) {
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) return mapUser(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public static Map<String, Object> getUserById(int id) {
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM users WHERE id = ?")) {
            pstmt.setInt(1, id);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) return mapUser(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    
    public static List<Map<String, Object>> getAllUsers(Map<String, Object> currentUser) {
        List<Map<String, Object>> users = new ArrayList<>();
        
        boolean canSeeAll = (currentUser != null) && Boolean.TRUE.equals(currentUser.get("see_all_users"));
        
        String sql;
        if (canSeeAll) {
            // Zeige alle AKTIVEN Benutzer aus allen Abteilungen
            sql = "SELECT * FROM users ORDER BY username";
        } else {
            // Zeige nur aktive Benutzer aus der EIGENEN Abteilung
            sql = "SELECT * FROM users WHERE abteilung = ? ORDER BY username";
        }

        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            if (!canSeeAll) {
                String abteilung = (currentUser != null) ? (String) currentUser.get("abteilung") : "";
                pstmt.setString(1, abteilung);
            }
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                users.add(mapUser(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return users;
    }
    
   public static void addUser(String username, String password, String name, String vorname, String stelle, String team, String abteilung, boolean active, boolean isUser, boolean canManageUsers, boolean canViewLogbook, boolean canManageFeiertage, boolean seeAllUsers, boolean canManageCalendar, boolean canManageCapacities, boolean canManageSettings, boolean canManageTasks, boolean canManageCalendarOverview, String actor) throws SQLException {
        String sql = "INSERT INTO users(username, password_hash, name, vorname, stelle, team, abteilung, active, is_user, can_manage_users, can_view_logbook, can_manage_feiertage, see_all_users, can_manage_calendar, can_manage_capacities, can_manage_settings, can_manage_tasks, can_manage_calendar_overview) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            int i = 1;
            pstmt.setString(i++, username);
            pstmt.setString(i++, BCrypt.hashpw(password, BCrypt.gensalt()));
            pstmt.setString(i++, name);
            pstmt.setString(i++, vorname);
            pstmt.setString(i++, stelle);
            pstmt.setString(i++, team);
            pstmt.setString(i++, abteilung);
            pstmt.setBoolean(i++, active);
            pstmt.setBoolean(i++, isUser);
            pstmt.setBoolean(i++, canManageUsers);
            pstmt.setBoolean(i++, canViewLogbook);
            pstmt.setBoolean(i++, canManageFeiertage);
            pstmt.setBoolean(i++, seeAllUsers);
            pstmt.setBoolean(i++, canManageCalendar);
            pstmt.setBoolean(i++, canManageCapacities);
            pstmt.setBoolean(i++, canManageSettings);
            pstmt.setBoolean(i++, canManageTasks);
            pstmt.setBoolean(i++, canManageCalendarOverview);
            pstmt.executeUpdate();
            logAction(actor, "Erstellen", "Benutzer '" + username + "' angelegt.");
        }
    }

    public static void updateUser(int id, String username, String password, String name, String vorname, String stelle, String team, String abteilung, boolean active, boolean isUser, boolean canManageUsers, boolean canViewLogbook, boolean canManageFeiertage, boolean seeAllUsers, boolean canManageCalendar, boolean canManageCapacities, boolean canManageSettings, boolean canManageTasks, boolean canManageCalendarOverview, String actor) throws SQLException {
        StringBuilder sql = new StringBuilder("UPDATE users SET username=?, name=?, vorname=?, stelle=?, team=?, abteilung=?, active=?, is_user=?, can_manage_users=?, can_view_logbook=?, can_manage_feiertage=?, see_all_users=?, can_manage_calendar=?, can_manage_capacities=?, can_manage_settings=?, can_manage_tasks=?, can_manage_calendar_overview=?");
        if (password != null && !password.isEmpty()) {
            sql.append(", password_hash=?");
        }
        sql.append(" WHERE id=?");

        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            int i = 1;
            pstmt.setString(i++, username);
            pstmt.setString(i++, name);
            pstmt.setString(i++, vorname);
            pstmt.setString(i++, stelle);
            pstmt.setString(i++, team);
            pstmt.setString(i++, abteilung); // Dieser Parameter fehlte in der Ausführung
            pstmt.setBoolean(i++, active);
            pstmt.setBoolean(i++, isUser);
            pstmt.setBoolean(i++, canManageUsers);
            pstmt.setBoolean(i++, canViewLogbook);
            pstmt.setBoolean(i++, canManageFeiertage);
            pstmt.setBoolean(i++, seeAllUsers);
            pstmt.setBoolean(i++, canManageCalendar);
            pstmt.setBoolean(i++, canManageCapacities);
            pstmt.setBoolean(i++, canManageSettings);
            pstmt.setBoolean(i++, canManageTasks);
            pstmt.setBoolean(i++, canManageCalendarOverview);
            
            if (password != null && !password.isEmpty()) {
                pstmt.setString(i++, BCrypt.hashpw(password, BCrypt.gensalt()));
            }
            
            pstmt.setInt(i, id);
            pstmt.executeUpdate();
            logAction(actor, "Bearbeiten", "Benutzer '" + username + "' (ID: " + id + ") aktualisiert.");
        }
    }

    public static void deleteUser(int id, String actor) throws SQLException {
        String username = getUserById(id).get("username").toString();
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement("DELETE FROM users WHERE id = ?")) {
            pstmt.setInt(1, id);
            pstmt.executeUpdate();
            logAction(actor, "Löschen", "Benutzer '" + username + "' (ID: " + id + ") gelöscht.");
        }
    }
    
    public static int deactivateUsersNotIn(List<String> usernames) throws SQLException {
        if (usernames == null || usernames.isEmpty()) return 0;
        StringBuilder sql = new StringBuilder("UPDATE users SET active = false WHERE active = true AND username NOT IN (");
        for (int i = 0; i < usernames.size(); i++) {
            sql.append(i == 0 ? "?" : ",?");
        }
        sql.append(")");
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < usernames.size(); i++) {
                pstmt.setString(i + 1, usernames.get(i));
            }
            return pstmt.executeUpdate();
        }
    }

    public static void logAction(String username, String action, String description) throws SQLException {
        String sql = "INSERT INTO logbook(timestamp, username, action, description) VALUES (?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setTimestamp(1, Timestamp.from(Instant.now()));
            pstmt.setString(2, username);
            pstmt.setString(3, action);
            pstmt.setString(4, description);
            pstmt.executeUpdate();
        }
    }



 
    


    // ####################
    // Logbuch
    // ####################

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
    

    





    // --- Mitarbeiter-CRUD ---
 
    public static void addMitarbeiter(String name, String stelle, String team, String abteilung, String actor) throws SQLException {
        String sql = "INSERT INTO mitarbeiter(name, stelle, team, abteilung) VALUES (?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, name);
            pstmt.setString(2, stelle);
            pstmt.setString(3, team);
            pstmt.setString(4, abteilung);
            pstmt.executeUpdate();
            String desc = String.format("Mitarbeiter angelegt. [name=%s, stelle=%s, team=%s, abteilung=%s]", name, stelle, team, abteilung);
            logAction(actor, "Erstellen", desc);
        }
    }

    public static void updateMitarbeiter(int id, String name, String stelle, String team, String abteilung, String actor) throws SQLException {
        Map<String, Object> old = getMitarbeiterById(id);
        if (old == null) throw new SQLException("Mitarbeiter mit ID " + id + " nicht gefunden.");
        StringJoiner changes = new StringJoiner(", ");
        if (!old.get("name").equals(name)) changes.add(String.format("name: '%s' -> '%s'", old.get("name"), name));
        if (!equalsNullable(old.get("stelle"), stelle)) changes.add(String.format("stelle: '%s' -> '%s'", old.get("stelle"), stelle));
        if (!equalsNullable(old.get("team"), team)) changes.add(String.format("team: '%s' -> '%s'", old.get("team"), team));
        if (!old.get("abteilung").equals(abteilung)) changes.add(String.format("abteilung: '%s' -> '%s'", old.get("abteilung"), abteilung));
        String sql = "UPDATE mitarbeiter SET name=?, stelle=?, team=?, abteilung=? WHERE id=?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, name);
            pstmt.setString(2, stelle);
            pstmt.setString(3, team);
            pstmt.setString(4, abteilung);
            pstmt.setInt(5, id);
            pstmt.executeUpdate();
            String desc = changes.length() > 0 ? String.format("Mitarbeiter '%s' (ID: %d) aktualisiert. Änderungen: [%s]", old.get("name"), id, changes.toString()) : String.format("Mitarbeiter '%s' (ID: %d) bearbeitet, keine Änderungen.", old.get("name"), id);
            logAction(actor, "Bearbeiten", desc);
        }
    }

    public static void deleteMitarbeiter(int id, String actor) throws SQLException {
        Map<String, Object> old = getMitarbeiterById(id);
        if (old == null) throw new SQLException("Mitarbeiter mit ID " + id + " nicht gefunden.");
        String sql = "DELETE FROM mitarbeiter WHERE id = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            pstmt.executeUpdate();
            String desc = String.format("Mitarbeiter '%s' (ID: %d) gelöscht.", old.get("name"), id);
            logAction(actor, "Löschen", desc);
        }
    }

    public static Map<String, Object> getMitarbeiterById(int id) {
        String sql = "SELECT id, name, stelle, team, abteilung FROM mitarbeiter WHERE id = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("id", rs.getInt("id"));
                m.put("name", rs.getString("name"));
                m.put("stelle", rs.getString("stelle"));
                m.put("team", rs.getString("team"));
                m.put("abteilung", rs.getString("abteilung"));
                return m;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public static List<Map<String, Object>> getMitarbeiterList(String search, String abteilung, String sortField, String sortDir) {
        List<Map<String, Object>> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT id, name, stelle, team, abteilung FROM mitarbeiter");
        List<Object> params = new ArrayList<>();
        boolean where = false;
        if (search != null && !search.trim().isEmpty()) {
            sql.append(where ? " AND" : " WHERE");
            sql.append(" (name LIKE ? OR stelle LIKE ? OR team LIKE ? OR abteilung LIKE ?)");
            String s = "%" + search + "%";
            params.add(s); params.add(s); params.add(s); params.add(s);
            where = true;
        }
        if (abteilung != null && !abteilung.trim().isEmpty()) {
            sql.append(where ? " AND" : " WHERE");
            sql.append(" abteilung = ?");
            params.add(abteilung);
            where = true;
        }
        // Sortierung
        String allowedSort = "name,stelle,team,abteilung";
        if (sortField != null && allowedSort.contains(sortField)) {
            sql.append(" ORDER BY ").append(sortField);
            if ("desc".equalsIgnoreCase(sortDir)) sql.append(" DESC");
            else sql.append(" ASC");
        } else {
            sql.append(" ORDER BY name ASC");
        }
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("id", rs.getInt("id"));
                m.put("name", rs.getString("name"));
                m.put("stelle", rs.getString("stelle"));
                m.put("team", rs.getString("team"));
                m.put("abteilung", rs.getString("abteilung"));
                list.add(m);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    } 

    // --- NEUE METHODEN FÜR FEIERTAGE ---

    public static List<Map<String, Object>> getAllFeiertage() {
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection conn = getConnection(); Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery("SELECT * FROM feiertage ORDER BY datum")) {
            while(rs.next()) {
                Map<String, Object> f = new HashMap<>();
                f.put("id", rs.getInt("id"));
                f.put("datum", rs.getObject("datum", LocalDate.class));
                f.put("bezeichnung", rs.getString("bezeichnung"));
                list.add(f);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public static Map<String, Object> getFeiertagByDate(LocalDate datum) {
        String sql = "SELECT id, datum, bezeichnung FROM feiertage WHERE datum = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, Date.valueOf(datum));
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                Map<String, Object> f = new HashMap<>();
                f.put("id", rs.getInt("id"));
                f.put("datum", rs.getObject("datum", LocalDate.class));
                f.put("bezeichnung", rs.getString("bezeichnung"));
                return f;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }   

    public static Map<String, Object> getFeiertagById(int id) {
        String sql = "SELECT id, datum, bezeichnung FROM feiertage WHERE id = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                Map<String, Object> f = new HashMap<>();
                f.put("id", rs.getInt("id"));
                f.put("datum", rs.getObject("datum", LocalDate.class));
                f.put("bezeichnung", rs.getString("bezeichnung"));
                return f;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public static void addFeiertag(LocalDate datum, String bezeichnung, String actor) throws SQLException {
        String sql = "INSERT INTO feiertage(datum, bezeichnung) VALUES (?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, Date.valueOf(datum));
            pstmt.setString(2, bezeichnung);
            pstmt.executeUpdate();
            String desc = String.format("Feiertag angelegt: [Datum=%s, Bezeichnung=%s]", datum, bezeichnung);
            logAction(actor, "Erstellen", desc);
        }
    }

    public static void updateFeiertag(int id, LocalDate datum, String bezeichnung, String actor) throws SQLException {
        Map<String, Object> old = getFeiertagById(id);
        if (old == null) throw new SQLException("Feiertag mit ID " + id + " nicht gefunden.");
        String oldBezeichnung = (String) old.get("bezeichnung");
        LocalDate oldDatum = (LocalDate) old.get("datum");

        StringJoiner changes = new StringJoiner(", ");
        if (!Objects.equals(oldDatum, datum)) changes.add(String.format("Datum: '%s' -> '%s'", oldDatum, datum));
        if (!Objects.equals(oldBezeichnung, bezeichnung)) changes.add(String.format("Bezeichnung: '%s' -> '%s'", oldBezeichnung, bezeichnung));

        String sql = "UPDATE feiertage SET datum = ?, bezeichnung = ? WHERE id = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDate(1, Date.valueOf(datum));
            pstmt.setString(2, bezeichnung);
            pstmt.setInt(3, id);
            pstmt.executeUpdate();
            
            String desc = String.format("Feiertag '%s' (ID: %d) aktualisiert. Änderungen: [%s]", oldBezeichnung, id, changes.toString());
            logAction(actor, "Bearbeiten", desc);
        }
    }

    public static void deleteFeiertag(int id, String actor) throws SQLException {
        Map<String, Object> old = getFeiertagById(id);
        if (old == null) throw new SQLException("Feiertag mit ID " + id + " nicht gefunden.");

        String sql = "DELETE FROM feiertage WHERE id = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            pstmt.executeUpdate();
            String desc = String.format("Feiertag '%s' (ID: %d) gelöscht.", old.get("bezeichnung"), id);
            logAction(actor, "Löschen", desc);
        }
    }

    // ####################
    // Abwesenheiten
    // ####################

    public static void addAbsence(int userId, LocalDate startDate, LocalDate endDate, String reason, String actor) throws SQLException {
        String sql = "INSERT INTO user_absences(user_id, start_date, end_date, reason) VALUES (?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            pstmt.setDate(2, Date.valueOf(startDate));
            pstmt.setDate(3, Date.valueOf(endDate));
            pstmt.setString(4, reason);
            pstmt.executeUpdate();
            Map<String, Object> user = getUserById(userId);
            logAction(actor, "Erstellen", "Abwesenheit für " + user.get("username") + " vom " + startDate + " bis " + endDate + " angelegt.");
        }
    }

    public static void deleteAbsence(int absenceId, String actor) throws SQLException {
    try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement("DELETE FROM user_absences WHERE id = ?")) {
        pstmt.setInt(1, absenceId);
        pstmt.executeUpdate();
        logAction(actor, "Löschen", "Abwesenheit (ID: " + absenceId + ") gelöscht.");
    }
}

    public static List<Map<String, Object>> getAbsencesForUser(int userId) {
        List<Map<String, Object>> absences = new ArrayList<>();
        // KORREKTUR: Die Sortierrichtung wurde von DESC auf ASC geändert.
        String sql = "SELECT * FROM user_absences WHERE user_id = ? ORDER BY start_date ASC";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> absence = new HashMap<>();
                absence.put("id", rs.getInt("id"));
                absence.put("start_date", rs.getObject("start_date", LocalDate.class));
                absence.put("end_date", rs.getObject("end_date", LocalDate.class));
                absence.put("reason", rs.getString("reason"));
                absences.add(absence);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return absences;
    }
    
    // ####################
    // Kapazitäten
    // ####################

    public static void addCapacity(int userId, LocalDate startDate, int capacity, String actor) throws SQLException {
        String sql = "INSERT INTO user_capacities(user_id, start_date, capacity_percent) VALUES (?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            pstmt.setDate(2, Date.valueOf(startDate));
            pstmt.setInt(3, capacity);
            pstmt.executeUpdate();
            Map<String, Object> user = getUserById(userId);
            logAction(actor, "Erstellen", "Kapazität für " + user.get("username") + " ab " + startDate + " auf " + capacity + "% gesetzt.");
        }
    }

    public static List<Map<String, Object>> getCapacitiesForUser(int userId) {
        List<Map<String, Object>> capacities = new ArrayList<>();
        String sql = "SELECT * FROM user_capacities WHERE user_id = ? ORDER BY start_date ASC";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Map<String, Object> capacity = new HashMap<>();
                capacity.put("id", rs.getInt("id"));
                capacity.put("start_date", rs.getObject("start_date", LocalDate.class));
                capacity.put("capacity_percent", rs.getInt("capacity_percent"));
                capacities.add(capacity);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return capacities;
    }

    // ####################
    // Settings
    // ####################

    public static List<Map<String, Object>> getAllTaskStatuses() {
        List<Map<String, Object>> statuses = new ArrayList<>();
        String sql = "SELECT * FROM task_statuses ORDER BY sort_order ASC, name ASC";
        try (Connection conn = getConnection(); Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Map<String, Object> status = new HashMap<>();
                status.put("id", rs.getInt("id"));
                status.put("name", rs.getString("name"));
                status.put("active", rs.getBoolean("active"));
                status.put("sort_order", rs.getInt("sort_order"));
                status.put("color_code", rs.getString("color_code"));
                statuses.add(status);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return statuses;
    }

    public static void addTaskStatus(String name, boolean active, int sortOrder, String colorCode, String actor) throws SQLException {
        String sql = "INSERT INTO task_statuses(name, active, sort_order, color_code) VALUES (?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, name);
            pstmt.setBoolean(2, active);
            pstmt.setInt(3, sortOrder);
            pstmt.setString(4, colorCode); // NEU
            pstmt.executeUpdate();
            logAction(actor, "Erstellen", "Neuer Aufgaben-Status erstellt: " + name);
        }
    }

    public static void updateTaskStatus(int id, String name, boolean active, int sortOrder, String colorCode, String actor) throws SQLException {
        String sql = "UPDATE task_statuses SET name = ?, active = ?, sort_order = ?, color_code = ? WHERE id = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, name);
            pstmt.setBoolean(2, active);
            pstmt.setInt(3, sortOrder);
            pstmt.setString(4, colorCode); // NEU
            pstmt.setInt(5, id);
            pstmt.executeUpdate();
            logAction(actor, "Bearbeiten", "Aufgaben-Status (ID: " + id + ") aktualisiert.");
        }
    }

    public static void deleteTaskStatus(int id, String actor) throws SQLException {
        String sql = "DELETE FROM task_statuses WHERE id = ?";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            pstmt.executeUpdate();
            logAction(actor, "Löschen", "Aufgaben-Status (ID: " + id + ") gelöscht.");
        }
    }



    // ####################
    // Aufgaben
    // ####################
    public static List<Map<String, Object>> getAllTasks(String search, int statusId, Map<String, Object> currentUser) {
    List<Map<String, Object>> tasks = new ArrayList<>();
    
    StringBuilder sql = new StringBuilder("SELECT t.*, ts.name as status_name, ts.color_code as status_color FROM tasks t LEFT JOIN task_statuses ts ON t.status_id = ts.id");
    List<Object> params = new ArrayList<>();
    List<String> whereClauses = new ArrayList<>();

    // Textsuche
    if (search != null && !search.trim().isEmpty()) {
        whereClauses.add("t.name LIKE ?");
        params.add("%" + search.trim() + "%");
    }

    // Status-Filter
    if (statusId > 0) {
        whereClauses.add("t.status_id = ?");
        params.add(statusId);
    }

    // Abteilungs-Filter basierend auf Benutzerrechten
    if (currentUser != null && !Boolean.TRUE.equals(currentUser.get("see_all_users"))) {
        whereClauses.add("t.abteilung = ?");
        params.add(currentUser.get("abteilung"));
    }
    
    if (!whereClauses.isEmpty()) {
        sql.append(" WHERE ").append(String.join(" AND ", whereClauses));
    }
    
    sql.append(" ORDER BY t.start_date ASC, t.name ASC");

    try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
        for (int i = 0; i < params.size(); i++) {
            pstmt.setObject(i + 1, params.get(i));
        }
        
        ResultSet rs = pstmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> task = new HashMap<>();
            // KORREKTUR: Sicherstellen, dass alle Felder ausgelesen werden
            task.put("id", rs.getInt("id"));
            task.put("name", rs.getString("name"));
            task.put("start_date", rs.getObject("start_date", LocalDate.class));
            task.put("end_date", rs.getObject("end_date", LocalDate.class));
            task.put("effort_days", rs.getBigDecimal("effort_days"));
            task.put("status_id", rs.getInt("status_id"));
            task.put("status_name", rs.getString("status_name"));
            task.put("status_color", rs.getString("status_color")); 
            task.put("progress_percent", rs.getInt("progress_percent"));
            task.put("abteilung", rs.getString("abteilung"));
            tasks.add(task);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    return tasks;
}

    public static void addTask(String name, LocalDate startDate, LocalDate endDate, double effortDays, int statusId, int progress, String abteilung, String actor) throws SQLException {
        String sql = "INSERT INTO tasks(name, start_date, end_date, effort_days, status_id, progress_percent, abteilung) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, name);
            pstmt.setDate(2, startDate != null ? Date.valueOf(startDate) : null);
            pstmt.setDate(3, endDate != null ? Date.valueOf(endDate) : null);
            pstmt.setDouble(4, effortDays);
            pstmt.setInt(5, statusId);
            pstmt.setInt(6, progress);
            pstmt.setString(7, abteilung);
            pstmt.executeUpdate();
            logAction(actor, "Erstellen", "Neue Aufgabe erstellt: " + name);
        }
    }

    public static void updateTask(int id, String name, LocalDate startDate, LocalDate endDate, double effortDays, int statusId, int progress, String abteilung, String actor) throws SQLException {
        String sql = "UPDATE tasks SET name = ?, start_date = ?, end_date = ?, effort_days = ?, status_id = ?, progress_percent = ?, abteilung = ? WHERE id = ?";
         try (Connection conn = getConnection(); PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, name);
            pstmt.setDate(2, startDate != null ? Date.valueOf(startDate) : null);
            pstmt.setDate(3, endDate != null ? Date.valueOf(endDate) : null);
            pstmt.setDouble(4, effortDays);
            pstmt.setInt(5, statusId);
            pstmt.setInt(6, progress);
            pstmt.setString(7, abteilung);
            pstmt.setInt(8, id);
            pstmt.executeUpdate();
            logAction(actor, "Bearbeiten", "Aufgabe (ID: " + id + ") aktualisiert.");
        }
    }

    // Hilfsmethode für Nullable-Vergleich
    private static boolean equalsNullable(Object a, Object b) {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        return a.equals(b);
    }

    // Settings
    public static Map<String, String> getAllSettings() throws SQLException {
        Map<String, String> settings = new HashMap<>();
        String sql = "SELECT setting_key, setting_value FROM settings";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                settings.put(rs.getString("setting_key"), rs.getString("setting_value"));
            }
        }
        return settings;
    }

    public static void updateSetting(String key, String value, String actor) throws SQLException {
        String sql = "UPDATE settings SET setting_value = ? WHERE setting_key = ?";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, value);
            stmt.setString(2, key);
            stmt.executeUpdate();
            logAction(actor, "Einstellung ändern", "Setting '" + key + "' auf '" + value + "' geändert");
        }
    }

    public static List<Map<String, Object>> getSettingsWithDescription() throws SQLException {
        List<Map<String, Object>> settings = new ArrayList<>();
        String sql = "SELECT setting_key, setting_value, description FROM settings ORDER BY setting_key";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> setting = new HashMap<>();
                setting.put("key", rs.getString("setting_key"));
                setting.put("value", rs.getString("setting_value"));
                setting.put("description", rs.getString("description"));
                settings.add(setting);
            }
        }
        return settings;
    }

    // Kalenderübersicht
    public static List<Map<String, Object>> getActiveUsers() throws SQLException {
        List<Map<String, Object>> users = new ArrayList<>();
        String sql = "SELECT id, username, name, vorname, abteilung FROM users WHERE active = true ORDER BY abteilung, name, vorname";
        
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            
            while (rs.next()) {
                Map<String, Object> user = new HashMap<>();
                user.put("id", rs.getInt("id"));
                user.put("username", rs.getString("username"));
                user.put("name", rs.getString("name"));
                user.put("vorname", rs.getString("vorname"));
                user.put("abteilung", rs.getString("abteilung"));
                users.add(user);
            }
        }
        return users;
    }
    
    public static Map<LocalDate, String> getHolidaysForMonth(int year, int month) throws SQLException {
        Map<LocalDate, String> holidays = new HashMap<>();
        String sql = "SELECT datum, bezeichnung FROM feiertage WHERE YEAR(datum) = ? AND MONTH(datum) = ?";
        
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, year);
            stmt.setInt(2, month);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    LocalDate date = rs.getDate("datum").toLocalDate();
                    String name = rs.getString("bezeichnung");
                    holidays.put(date, name);
                }
            }
        }
        return holidays;
    }
    
    public static List<LocalDate> getAbsencesForUser(int userId, LocalDate startDate, LocalDate endDate) throws SQLException {
        List<LocalDate> absences = new ArrayList<>();
        String sql = "SELECT datum FROM calendar WHERE user_id = ? AND datum BETWEEN ? AND ?";
        
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, userId);
            stmt.setDate(2, java.sql.Date.valueOf(startDate));
            stmt.setDate(3, java.sql.Date.valueOf(endDate));
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    absences.add(rs.getDate("datum").toLocalDate());
                }
            }
        }
        return absences;
    }
}