package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@WebServlet("/logbook")
public class LogbookServlet extends HttpServlet {

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;

        if (user == null || !(Boolean) user.getOrDefault("can_view_logbook", false)) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String search = req.getParameter("search");
        if (search == null) search = "";

        int page = 1;
        try {
            if (req.getParameter("page") != null) {
                page = Integer.parseInt(req.getParameter("page"));
            }
        } catch (NumberFormatException e) {
            page = 1;
        }

        int limit = 25;
        try {
            if (req.getParameter("limit") != null) {
                limit = Integer.parseInt(req.getParameter("limit"));
            }
        } catch (NumberFormatException e) {
            limit = 25;
        }
        
        List<Map<String, Object>> logs = DatabaseService.getLogs(search, page, limit);
        int totalLogs = DatabaseService.getTotalLogCount(search);
        int totalPages = (int) Math.ceil((double) totalLogs / limit);
        
        req.setAttribute("logs", logs);
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("limit", limit);
        req.setAttribute("search", search);
        
        req.getRequestDispatcher("/WEB-INF/logbook.jsp").forward(req, resp);
    }
}