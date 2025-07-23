package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

@WebServlet("/users/add")
public class AddUserServlet extends HttpServlet {

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (user == null || !(Boolean) user.getOrDefault("can_manage_users", false)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/add-user.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;
        String actor = (user != null) ? (String) user.get("username") : "System";

        if (user == null || !(Boolean) user.getOrDefault("can_manage_users", false)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }

        String username = req.getParameter("username");
        String password = req.getParameter("password");
        
        // KORRIGIERT: Liest jetzt beide neuen Rechte-Checkboxen aus
        boolean canManageUsers = "on".equals(req.getParameter("can_manage_users"));
        boolean canViewLogbook = "on".equals(req.getParameter("can_view_logbook"));

        try {
            // KORRIGIERT: Ruft die addUser-Methode mit den korrekten Parametern auf
            DatabaseService.addUser(username, password, canManageUsers, canViewLogbook, actor);
            resp.sendRedirect(req.getContextPath() + "/users");
        } catch (SQLException e) {
            req.setAttribute("error", "Fehler: Benutzername existiert bereits oder Eingabe ungültig.");
            req.getRequestDispatcher("/WEB-INF/add-user.jsp").forward(req, resp);
        }
    }
}