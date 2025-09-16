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

        // Berechtigungsprüfung
        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_settings"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }
        String actor = (String) user.get("username");

        try {
            // KORREKTUR: Iteriere durch alle Parameter, die vom Formular gesendet wurden.
            // Das macht den Code flexibel für zukünftige neue Einstellungen.
            for (Map.Entry<String, String[]> entry : req.getParameterMap().entrySet()) {
                String key = entry.getKey();
                String value = entry.getValue()[0]; // Hole den ersten Wert für diesen Schlüssel

                // Rufe die update-Methode für jeden einzelnen Schlüssel-Wert-Paar auf.
                DatabaseService.updateSetting(key, value, actor);
            }

            // Erfolgsmeldung in die Session legen
            session.setAttribute("successMessage", "Einstellungen erfolgreich gespeichert.");

        } catch (SQLException e) {
            // Fehlermeldung in die Session legen
            session.setAttribute("errorMessage", "Fehler beim Speichern der Einstellungen: " + e.getMessage());
            e.printStackTrace();
        }

        // Zurück zur Einstellungsseite umleiten
        resp.sendRedirect(req.getContextPath() + "/settings");
    }
}