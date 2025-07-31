package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

// GEÄNDERT: Die URL-Muster wurden angepasst, um POST-Anfragen korrekt zu behandeln
@WebServlet(urlPatterns = {"/users", "/users/"})
public class UserServlet extends HttpServlet {

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (user == null || !(Boolean) user.getOrDefault("can_manage_users", false)) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        List<Map<String, Object>> userList = DatabaseService.getAllUsers(user);
        req.setAttribute("users", userList);
        req.getRequestDispatcher("/WEB-INF/users.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> currentUser = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;
        String actor = (currentUser != null) ? (String) currentUser.get("username") : "System";

        if (currentUser == null || !(Boolean) currentUser.getOrDefault("can_manage_users", false)) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }
        
        try {
            String action = req.getParameter("action");
            String username = req.getParameter("username");
            String name = req.getParameter("name");
            String vorname = req.getParameter("vorname");
            String stelle = req.getParameter("stelle");
            String team = req.getParameter("team");
            String abteilung = req.getParameter("abteilung");
            String password = req.getParameter("password");
            boolean active = "on".equals(req.getParameter("active"));
            boolean isUser = "on".equals(req.getParameter("is_user"));
            boolean canManageUsers = "on".equals(req.getParameter("can_manage_users"));
            boolean canViewLogbook = "on".equals(req.getParameter("can_view_logbook"));
            boolean canManageFeiertage = "on".equals(req.getParameter("can_manage_feiertage"));
            boolean seeAllUsers = "on".equals(req.getParameter("see_all_users"));
            boolean canManageCalendar = "on".equals(req.getParameter("can_manage_calendar"));

            if ("add".equals(action)) {
                DatabaseService.addUser(username, password, name, vorname, stelle, team, abteilung, active, isUser, canManageUsers, canViewLogbook, canManageFeiertage, seeAllUsers, canManageCalendar, actor);
            } else if ("edit".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                DatabaseService.updateUser(id, username, password, name, vorname, stelle, team, abteilung, active, isUser, canManageUsers, canViewLogbook, canManageFeiertage, seeAllUsers, canManageCalendar, actor);
            }
            resp.sendRedirect(req.getContextPath() + "/users");

        } catch (SQLException | NumberFormatException e) {
            e.printStackTrace();
            req.setAttribute("error", "Fehler beim Speichern: " + e.getMessage());
            doGet(req, resp);
        }
    }
}