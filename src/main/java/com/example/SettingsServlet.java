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

        List<Map<String, Object>> statuses = DatabaseService.getAllTaskStatuses();
        req.setAttribute("taskStatuses", statuses);
        req.getRequestDispatcher("/WEB-INF/settings.jsp").forward(req, resp);
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
        String colorCode = req.getParameter("color_code");

        try {
            switch (action) {
                case "add_status":
                    DatabaseService.addTaskStatus(
                        req.getParameter("name"),
                        "on".equals(req.getParameter("active")),
                        Integer.parseInt(req.getParameter("sort_order")),
                        colorCode,
                        actor);
                    break;
                case "edit_status":
                    DatabaseService.updateTaskStatus(
                        Integer.parseInt(req.getParameter("id")),
                        req.getParameter("name"),
                        "on".equals(req.getParameter("active")),
                        Integer.parseInt(req.getParameter("sort_order")),
                        colorCode,
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