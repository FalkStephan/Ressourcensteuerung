package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Date;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@WebServlet("/tasks")
public class TaskServlet extends HttpServlet {

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        // KORREKTUR: Das 'user'-Objekt muss hier deklariert werden
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;
        
        // NEU: Rechteprüfung
        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_tasks"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }

        if (user == null) {
            resp.sendRedirect("login");
            return;
        }

        String search = req.getParameter("search");
        String statusFilter = req.getParameter("status_filter");
        int statusId = -1;
        if (statusFilter != null && !statusFilter.isEmpty()) {
            try {
                statusId = Integer.parseInt(statusFilter);
            } catch (NumberFormatException e) {
                // Wert ignorieren
            }
        }

        List<Map<String, Object>> tasks = DatabaseService.getAllTasks(search, statusId, user);
        List<Map<String, Object>> statuses = DatabaseService.getAllTaskStatuses();
        
        for (Map<String, Object> task : tasks) {
            if (task.get("start_date") instanceof LocalDate) {
                task.put("start_date", Date.valueOf((LocalDate) task.get("start_date")));
            }
            if (task.get("end_date") instanceof LocalDate) {
                task.put("end_date", Date.valueOf((LocalDate) task.get("end_date")));
            }
        }
        
        req.setAttribute("tasks", tasks);
        req.setAttribute("taskStatuses", statuses);
        req.setAttribute("currentSearch", search);
        req.setAttribute("currentStatusFilter", statusId);
        
        req.getRequestDispatcher("/WEB-INF/tasks.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;
        String actor = (user != null) ? (String) user.get("username") : "System";
        String action = req.getParameter("action");

        try {
            String name = req.getParameter("name");
            LocalDate startDate = req.getParameter("start_date").isEmpty() ? null : LocalDate.parse(req.getParameter("start_date"));
            LocalDate endDate = req.getParameter("end_date").isEmpty() ? null : LocalDate.parse(req.getParameter("end_date"));
            String abteilung = req.getParameter("abteilung");
            
            // CORRECTED SECTION: Safely parse numeric inputs
            String effortParam = req.getParameter("effort_days");
            double effortDays = (effortParam == null || effortParam.isEmpty()) ? 0.0 : Double.parseDouble(effortParam);

            String progressParam = req.getParameter("progress_percent");
            int progress = (progressParam == null || progressParam.isEmpty()) ? 0 : Integer.parseInt(progressParam);
            
            String statusParam = req.getParameter("status_id");
            int statusId = (statusParam == null || statusParam.isEmpty()) ? 0 : Integer.parseInt(statusParam);
            // END CORRECTION

            if ("add".equals(action)) {
                DatabaseService.addTask(name, startDate, endDate, effortDays, statusId, progress, abteilung, actor);
            } else if ("edit".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                DatabaseService.updateTask(id, name, startDate, endDate, effortDays, statusId, progress, abteilung, actor);
            }
        } catch (Exception e) {
            e.printStackTrace(); 
        }
        resp.sendRedirect(req.getContextPath() + "/tasks");
    }
}