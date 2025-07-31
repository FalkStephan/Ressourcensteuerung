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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/calendar")
public class CalendarServlet extends HttpServlet {

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_calendar"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }

        List<Map<String, Object>> visibleUsers = DatabaseService.getAllUsers(user);
        Map<Map<String, Object>, List<Map<String, Object>>> userAbsences = new LinkedHashMap<>();

        for (Map<String, Object> visibleUser : visibleUsers) {
            List<Map<String, Object>> absences = DatabaseService.getAbsencesForUser((Integer) visibleUser.get("id"));
            
            // --- KORREKTUR START ---
            // Konvertiere LocalDate zu java.sql.Date für die JSP
            for (Map<String, Object> absence : absences) {
                if (absence.get("start_date") instanceof LocalDate) {
                    absence.put("start_date", Date.valueOf((LocalDate) absence.get("start_date")));
                }
                if (absence.get("end_date") instanceof LocalDate) {
                    absence.put("end_date", Date.valueOf((LocalDate) absence.get("end_date")));
                }
            }
            // --- KORREKTUR ENDE ---

            userAbsences.put(visibleUser, absences);
        }

        req.setAttribute("userAbsences", userAbsences);
        req.getRequestDispatcher("/WEB-INF/calendar.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_calendar"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }
        String actor = (String) user.get("username");
        String action = req.getParameter("action");

        try {
            if ("add_absence".equals(action)) {
                int userId = Integer.parseInt(req.getParameter("userId"));
                LocalDate startDate = LocalDate.parse(req.getParameter("startDate"));
                LocalDate endDate = LocalDate.parse(req.getParameter("endDate"));
                String reason = req.getParameter("reason");
                DatabaseService.addAbsence(userId, startDate, endDate, reason, actor);
            } else if ("delete_absence".equals(action)) {
                int absenceId = Integer.parseInt(req.getParameter("id"));
                DatabaseService.deleteAbsence(absenceId, actor);
            }
        } catch (Exception e) {
            // Einfache Fehlerbehandlung
            e.printStackTrace();
        }
        resp.sendRedirect(req.getContextPath() + "/calendar");
    }
}