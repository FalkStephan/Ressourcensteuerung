package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/users/edit")
public class EditUserServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        Map<String, Object> user = new HashMap<>();
        String sql = "SELECT id, username, abteilung, can_manage_users, can_view_logbook FROM users WHERE id = ?";

        try (Connection conn = DatabaseService.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                user.put("id", rs.getInt("id"));
                user.put("username", rs.getString("username"));
                user.put("abteilung", rs.getString("abteilung"));
                user.put("can_manage_users", rs.getBoolean("can_manage_users"));
                user.put("can_view_logbook", rs.getBoolean("can_view_logbook"));
            }
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        request.setAttribute("user", user);
        request.getRequestDispatcher("/WEB-INF/edit-user.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        String username = request.getParameter("username");
        String abteilung = request.getParameter("abteilung");
        boolean canManageUsers = "true".equals(request.getParameter("can_manage_users"));
        boolean canViewLogbook = "true".equals(request.getParameter("can_view_logbook"));

        String sql = "UPDATE users SET username = ?, abteilung = ?, can_manage_users = ?, can_view_logbook = ? WHERE id = ?";
        try (Connection conn = DatabaseService.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            pstmt.setString(2, abteilung);
            pstmt.setBoolean(3, canManageUsers);
            pstmt.setBoolean(4, canViewLogbook);
            pstmt.setInt(5, id);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            throw new ServletException(e);
        }
        response.sendRedirect(request.getContextPath() + "/users");
    }
}