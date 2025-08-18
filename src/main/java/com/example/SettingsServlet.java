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

@WebServlet("/settings")
public class SettingsServlet extends HttpServlet {

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_settings"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }

        try {
            // Lade Task-Status
            List<Map<String, Object>> statuses = DatabaseService.getAllTaskStatuses();
            req.setAttribute("taskStatuses", statuses);
            
            // Lade Einstellungen
            List<Map<String, Object>> settings = DatabaseService.getSettingsWithDescription();
            req.setAttribute("settings", settings);
            
            req.getRequestDispatcher("/WEB-INF/settings.jsp").forward(req, resp);
        } catch (SQLException e) {
            throw new ServletException("Fehler beim Laden der Einstellungen", e);
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_settings"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }
        String actor = (String) user.get("username");
        String action = req.getParameter("action");

        try {
            switch (action) {
                case "update_settings":
                    // Alle settings aus der Datenbank holen
                    Map<String, String> currentSettings = DatabaseService.getAllSettings();
                    
                    // Für jede Einstellung prüfen, ob sie geändert wurde
                    for (String key : currentSettings.keySet()) {
                        String newValue = req.getParameter(key);
                        if (newValue != null && !newValue.equals(currentSettings.get(key))) {
                            DatabaseService.updateSetting(key, newValue, actor);
                        }
                    }
                    break;

                case "add_status":
                    DatabaseService.addTaskStatus(
                        req.getParameter("name"),
                        "on".equals(req.getParameter("active")),
                        Integer.parseInt(req.getParameter("sort_order")),
                        req.getParameter("color_code"),
                        actor);
                    break;
                    
                case "edit_status":
                    DatabaseService.updateTaskStatus(
                        Integer.parseInt(req.getParameter("id")),
                        req.getParameter("name"),
                        "on".equals(req.getParameter("active")),
                        Integer.parseInt(req.getParameter("sort_order")),
                        req.getParameter("color_code"),
                        actor);
                    break;
                    
                case "delete_status":
                    DatabaseService.deleteTaskStatus(
                        Integer.parseInt(req.getParameter("id")),
                        actor);
                    break;
            }
        } catch (SQLException | NumberFormatException e) {
            e.printStackTrace(); // Fehlerbehandlung
        }
        resp.sendRedirect(req.getContextPath() + "/settings");
    }
}