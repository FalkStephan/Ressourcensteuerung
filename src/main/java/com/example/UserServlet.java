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

        List<Map<String, Object>> userList = DatabaseService.getAllUsers();
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
        
        // Der Parameter 'action' entscheidet, ob hinzugefügt oder bearbeitet wird
        String action = req.getParameter("action");
        if (action == null) {
            resp.sendRedirect(req.getContextPath() + "/users");
            return;
        }

        try {
            if ("add".equals(action)) {
                // Logik aus dem AddUserServlet
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
                DatabaseService.addUser(username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, abteilung, actor, active, isUser);

            } else if ("edit".equals(action)) {
                // Logik aus dem EditUserServlet
                int id = Integer.parseInt(req.getParameter("id"));
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
                DatabaseService.updateUser(id, username, password, name, vorname, stelle, team, canManageUsers, canViewLogbook, abteilung, actor, active, isUser);
            }
            resp.sendRedirect(req.getContextPath() + "/users");

        } catch (SQLException | NumberFormatException e) {
            e.printStackTrace();
            req.setAttribute("error", "Fehler beim Speichern des Benutzers: " + e.getMessage());
            // Leite zur Liste zurück, um die Seite neu zu laden und den Fehler anzuzeigen
            doGet(req, resp);
        }
    }
}