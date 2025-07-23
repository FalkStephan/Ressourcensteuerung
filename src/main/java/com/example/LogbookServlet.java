package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@WebServlet("/logbook")
public class LogbookServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
        boolean canViewLogbook = (boolean) user.getOrDefault("can_view_logbook", false);

        if (!canViewLogbook) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert.");
            return;
        }

        String searchTerm = request.getParameter("search") == null ? "" : request.getParameter("search");
        int page = request.getParameter("page") == null ? 1 : Integer.parseInt(request.getParameter("page"));
        int limit = 20; // Einträge pro Seite
        int offset = (page - 1) * limit;

        List<Map<String, Object>> logs = Collections.emptyList();
        int totalLogs = 0;

        // **KORREKTUR: Der gesamte Datenbankzugriff wird in einen try-catch-Block eingeschlossen**
        try {
            logs = DatabaseService.getLogs(searchTerm, offset, limit);
            totalLogs = DatabaseService.getTotalLogCount(searchTerm);
        } catch (SQLException e) {
            throw new ServletException("Fehler beim Abrufen der Logbuch-Einträge", e);
        }

        int totalPages = (int) Math.ceil((double) totalLogs / limit);

        request.setAttribute("logs", logs);
        request.setAttribute("currentPage", page);
        request.setAttribute("totalPages", totalPages);
        request.setAttribute("searchTerm", searchTerm);

        request.getRequestDispatcher("/WEB-INF/logbook.jsp").forward(request, response);
    }
}