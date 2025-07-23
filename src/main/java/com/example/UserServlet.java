package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/users")
public class UserServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        List<Map<String, Object>> users = new ArrayList<>();
        String sql = "SELECT id, username, abteilung, can_manage_users, can_view_logbook FROM users ORDER BY username";

        try (Connection conn = DatabaseService.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Map<String, Object> user = new HashMap<>();
                user.put("id", rs.getInt("id"));
                user.put("username", rs.getString("username"));
                user.put("abteilung", rs.getString("abteilung"));
                user.put("can_manage_users", rs.getBoolean("can_manage_users"));
                user.put("can_view_logbook", rs.getBoolean("can_view_logbook"));
                users.add(user);
            }
        } catch (SQLException e) {
            throw new ServletException("Fehler beim Laden der Benutzerliste", e);
        }
        
        request.setAttribute("users", users);
        
        // **KORREKTUR: Der Pfad zur JSP-Datei wird hier korrigiert.**
        request.getRequestDispatcher("/WEB-INF/users.jsp").forward(request, response);
    }
}