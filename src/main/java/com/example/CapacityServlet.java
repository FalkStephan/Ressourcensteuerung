package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Date; // WICHTIG: java.sql.Date importieren
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/capacities")
public class CapacityServlet extends HttpServlet {

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_capacities"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }

        List<Map<String, Object>> visibleUsers = DatabaseService.getAllUsers(user);
        Map<Map<String, Object>, List<Map<String, Object>>> userCapacities = new LinkedHashMap<>();

        for (Map<String, Object> visibleUser : visibleUsers) {
            List<Map<String, Object>> capacities = DatabaseService.getCapacitiesForUser((Integer) visibleUser.get("id"));
            
            // --- KORREKTUR START ---
            // Konvertiere LocalDate zu java.sql.Date für die JSP
            for (Map<String, Object> capacity : capacities) {
                if (capacity.get("start_date") instanceof LocalDate) {
                    capacity.put("start_date", Date.valueOf((LocalDate) capacity.get("start_date")));
                }
            }
            // --- KORREKTUR ENDE ---

            userCapacities.put(visibleUser, capacities);
        }

        req.setAttribute("userCapacities", userCapacities);
        req.getRequestDispatcher("/WEB-INF/capacities.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_capacities"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }
        String actor = (String) user.get("username");
        String action = req.getParameter("action");

        try {
            if ("delete".equals(action)) {
                // Logik zum LÖSCHEN
                String capacityIdStr = req.getParameter("capacityId");
                if (capacityIdStr == null || capacityIdStr.trim().isEmpty()) {
                    throw new IllegalArgumentException("Capacity ID für das Löschen fehlt.");
                }
                int capacityId = Integer.parseInt(capacityIdStr);
                DatabaseService.deleteCapacity(capacityId, actor);

            } else {
                // Standard-Logik zum HINZUFÜGEN
                String userIdStr = req.getParameter("userId");
                String startDateStr = req.getParameter("startDate");
                String capacityStr = req.getParameter("capacity");

                // Validierung: Sicherstellen, dass keine Felder leer sind.
                if (userIdStr == null || userIdStr.trim().isEmpty() ||
                    startDateStr == null || startDateStr.trim().isEmpty() ||
                    capacityStr == null || capacityStr.trim().isEmpty()) {
                    throw new IllegalArgumentException("Bitte füllen Sie alle erforderlichen Felder aus (Benutzer, Datum, Kapazität).");
                }

                int userId = Integer.parseInt(userIdStr);
                LocalDate startDate = LocalDate.parse(startDateStr);
                int capacity = Integer.parseInt(capacityStr);

                if (capacity < 0 || capacity > 100) {
                    throw new IllegalArgumentException("Kapazität muss zwischen 0 und 100 liegen.");
                }
                DatabaseService.addCapacity(userId, startDate, capacity, actor);
            }
        } catch (Exception e) {
            // Setzt eine Session-Variable, um eine Fehlermeldung auf der JSP anzuzeigen
            session.setAttribute("errorMessage", "Ein Fehler ist aufgetreten: " + e.getMessage());
            e.printStackTrace();
        }
        
        // Nach der Aktion zurück zur Hauptseite umleiten
        resp.sendRedirect(req.getContextPath() + "/capacities");
    }
}