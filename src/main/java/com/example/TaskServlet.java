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
import java.util.Arrays;
import java.util.ArrayList;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import java.io.PrintWriter;
import java.sql.SQLException;

@WebServlet("/tasks")
public class TaskServlet extends HttpServlet {
    private final Gson gson = new GsonBuilder().create();

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        
        if ("getAvailableUsers".equals(action)) {
            handleGetAvailableUsers(req, resp);
            return;
        } else if ("getAssignedUsers".equals(action)) {
            handleGetAssignedUsers(req, resp);
            return;
        } else if ("getLastInsertedTaskId".equals(action)) {
            handleGetLastInsertedTaskId(req, resp);
            return;
        }
        HttpSession session = req.getSession(false);
        // KORREKTUR: Das 'user'-Objekt muss hier deklariert werden
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;
        
        // NEU: Rechteprüfung
        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_tasks"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
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
        
        // Lade verfügbare Benutzer basierend auf Berechtigungen
        List<Map<String, Object>> availableUsers = new ArrayList<>();
        try {
            if (Boolean.TRUE.equals(user.get("can_manage_users"))) {
                // Benutzer mit can_manage_users sehen alle aktiven Benutzer
                availableUsers = DatabaseService.getActiveUsersByDepartment(null);
            } else {
                // Andere Benutzer sehen nur Benutzer ihrer eigenen Abteilung
                String userDepartment = (String) user.get("abteilung");
                availableUsers = DatabaseService.getActiveUsersByDepartment(userDepartment);
            }
        } catch (SQLException e) {
            // Log the error but continue with empty user list
            e.printStackTrace();
        }
        
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
        req.setAttribute("users", availableUsers);
        
        req.getRequestDispatcher("/WEB-INF/tasks.jsp").forward(req, resp);
    }
    
    private void handleGetAvailableUsers(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            String abteilung = request.getParameter("abteilung");
            List<Map<String, Object>> users = DatabaseService.getActiveUsersByDepartment(abteilung);
            out.print(gson.toJson(users));
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }

    private void handleGetAssignedUsers(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int taskId = Integer.parseInt(request.getParameter("taskId"));
            List<Map<String, Object>> assignments = DatabaseService.getAssignedUsersForTask(taskId);
            out.print(gson.toJson(assignments));
        } catch (SQLException | NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }
    
    private void handleGetLastInsertedTaskId(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int taskId = DatabaseService.getLastInsertedTaskId();
            out.print("{\"taskId\": " + taskId + "}");
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }

    private void handleSaveAssignments(HttpServletRequest request, HttpServletResponse response, String actor) 
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        try {
            int taskId = Integer.parseInt(request.getParameter("taskId"));
            String[] userIds = request.getParameterValues("userIds[]");
            
            // Konvertiere String-Array in Integer-Liste
            List<Integer> userIdList = new ArrayList<>();
            if (userIds != null) {
                for (String userId : userIds) {
                    userIdList.add(Integer.parseInt(userId));
                }
            }
            
            DatabaseService.updateTaskAssignments(taskId, userIdList);
            out.print("{\"success\": true}");
        } catch (SQLException | NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;
        
        // Prüfe Berechtigung
        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_tasks"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }
        
        String actor = (user != null) ? (String) user.get("username") : "System";
        String action = req.getParameter("action");
        
        if ("saveAssignments".equals(action)) {
            handleSaveAssignments(req, resp, actor);
            return;
        }
        
        if ("saveAssignments".equals(action)) {
            handleSaveAssignments(req, resp);
            return;
        }

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