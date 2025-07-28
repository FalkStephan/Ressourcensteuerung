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
        String name = req.getParameter("name");
        String vorname = req.getParameter("vorname");
        String stelle = req.getParameter("stelle");
        String team = req.getParameter("team");
        String password = req.getParameter("password");
        boolean canManageUsers = "on".equals(req.getParameter("can_manage_users"));
        boolean canViewLogbook = "on".equals(req.getParameter("can_view_logbook"));
        String abteilung = req.getParameter("abteilung");
        boolean active = req.getParameter("active") != null;
        boolean isUser = "on".equals(req.getParameter("is_user"));
        try {
            DatabaseService.addUser(username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, abteilung, actor, active, isUser);
            resp.sendRedirect(req.getContextPath() + "/users");
        } catch (SQLException e) {
            req.setAttribute("error", "Fehler: Benutzername existiert bereits oder Eingabe ungültig.");
            req.getRequestDispatcher("/WEB-INF/add-user.jsp").forward(req, resp);
        }
    }
}