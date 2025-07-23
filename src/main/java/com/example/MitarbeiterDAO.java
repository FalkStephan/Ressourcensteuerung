package com.example;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class MitarbeiterDAO {

    /**
     * Fügt einen neuen Mitarbeiter zur Datenbank hinzu.
     */
    public void addMitarbeiter(Mitarbeiter mitarbeiter) throws SQLException {
        String sql = "INSERT INTO mitarbeiter (name, stelle, team, abteilung) VALUES (?, ?, ?, ?)";
        try (Connection conn = DatabaseService.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, mitarbeiter.getName());
            pstmt.setString(2, mitarbeiter.getStelle());
            pstmt.setString(3, mitarbeiter.getTeam());
            pstmt.setString(4, mitarbeiter.getAbteilung());
            pstmt.executeUpdate();
        }
    }

    /**
     * Ruft alle Mitarbeiter aus der Datenbank ab.
     */
    public List<Mitarbeiter> getAllMitarbeiter() throws SQLException {
        List<Mitarbeiter> mitarbeiterListe = new ArrayList<>();
        String sql = "SELECT * FROM mitarbeiter ORDER BY name";
        try (Connection conn = DatabaseService.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                mitarbeiterListe.add(mapRowToMitarbeiter(rs));
            }
        }
        return mitarbeiterListe;
    }

    /**
     * **NEUE METHODE:** Ruft einen einzelnen Mitarbeiter anhand seiner ID ab.
     * Diese Methode wird vom EditMitarbeiterServlet benötigt.
     */
    public Mitarbeiter getMitarbeiterById(int id) throws SQLException {
        String sql = "SELECT * FROM mitarbeiter WHERE id = ?";
        try (Connection conn = DatabaseService.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRowToMitarbeiter(rs);
                }
            }
        }
        return null; // Gibt null zurück, wenn kein Mitarbeiter gefunden wurde
    }

    /**
     * Ruft alle Mitarbeiter einer bestimmten Abteilung ab.
     */
    public List<Mitarbeiter> getMitarbeiterByAbteilung(String abteilung) throws SQLException {
        List<Mitarbeiter> mitarbeiterListe = new ArrayList<>();
        String sql = "SELECT * FROM mitarbeiter WHERE abteilung = ? ORDER BY name";
        try (Connection conn = DatabaseService.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, abteilung);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    mitarbeiterListe.add(mapRowToMitarbeiter(rs));
                }
            }
        }
        return mitarbeiterListe;
    }

    /**
     * Aktualisiert einen vorhandenen Mitarbeiter in der Datenbank.
     */
    public void updateMitarbeiter(Mitarbeiter mitarbeiter) throws SQLException {
        String sql = "UPDATE mitarbeiter SET name = ?, stelle = ?, team = ?, abteilung = ? WHERE id = ?";
        try (Connection conn = DatabaseService.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, mitarbeiter.getName());
            pstmt.setString(2, mitarbeiter.getStelle());
            pstmt.setString(3, mitarbeiter.getTeam());
            pstmt.setString(4, mitarbeiter.getAbteilung());
            pstmt.setInt(5, mitarbeiter.getId());
            pstmt.executeUpdate();
        }
    }

    /**
     * Löscht einen Mitarbeiter aus der Datenbank.
     */
    public void deleteMitarbeiter(int id) throws SQLException {
        String sql = "DELETE FROM mitarbeiter WHERE id = ?";
        try (Connection conn = DatabaseService.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            pstmt.executeUpdate();
        }
    }

    /**
     * Hilfsmethode, um eine Zeile aus dem ResultSet in ein Mitarbeiter-Objekt umzuwandeln.
     */
    private Mitarbeiter mapRowToMitarbeiter(ResultSet rs) throws SQLException {
        return new Mitarbeiter(
                rs.getInt("id"),
                rs.getString("name"),
                rs.getString("stelle"),
                rs.getString("team"),
                rs.getString("abteilung")
        );
    }
}