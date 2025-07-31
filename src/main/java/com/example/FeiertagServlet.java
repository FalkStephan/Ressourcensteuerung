package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Date; // WICHTIG: java.sql.Date importieren
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@WebServlet("/feiertage")
public class FeiertagServlet extends HttpServlet {

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        // NEU: Rechteprüfung
        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_feiertage"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }

        
        List<Map<String, Object>> feiertage = DatabaseService.getAllFeiertage();
        
        // --- KORREKTUR START ---
        // Konvertiere LocalDate zu java.sql.Date, damit <fmt:formatDate> es verarbeiten kann.
        for (Map<String, Object> feiertag : feiertage) {
            Object datumObj = feiertag.get("datum");
            if (datumObj instanceof LocalDate) {
                feiertag.put("datum", Date.valueOf((LocalDate) datumObj));
            }
        }
        // --- KORREKTUR ENDE ---
        
        req.setAttribute("feiertage", feiertage);
        req.getRequestDispatcher("/WEB-INF/feiertage.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Nicht angemeldet");
            return;
        }
        
        Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
        String actor = (String) user.get("username");
        String action = req.getParameter("action");

        try {
            if (action != null) {
                switch (action) {
                    case "add": {
                        String bezeichnung = req.getParameter("bezeichnung");
                        LocalDate datum = LocalDate.parse(req.getParameter("datum"));
                        DatabaseService.addFeiertag(datum, bezeichnung, actor);
                        break;
                    }
                    case "edit": {
                        int id = Integer.parseInt(req.getParameter("id"));
                        String bezeichnung = req.getParameter("bezeichnung");
                        LocalDate datum = LocalDate.parse(req.getParameter("datum"));
                        DatabaseService.updateFeiertag(id, datum, bezeichnung, actor);
                        break;
                    }
                    case "delete": {
                        int id = Integer.parseInt(req.getParameter("id"));
                        DatabaseService.deleteFeiertag(id, actor);
                        break;
                    }
                }
            }
        } catch (SQLException | NumberFormatException | java.time.format.DateTimeParseException e) {
            // Im Fehlerfall eine Nachricht setzen und die Seite neu laden
            req.setAttribute("error", "Fehler: " + e.getMessage());
            doGet(req, resp);
            return;
        }
        resp.sendRedirect(req.getContextPath() + "/feiertage");
    }
}