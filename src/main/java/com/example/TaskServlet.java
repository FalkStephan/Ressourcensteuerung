package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Date;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.HashMap;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import java.sql.SQLException;

@WebServlet("/tasks")
public class TaskServlet extends HttpServlet {
    private final Gson gson = new GsonBuilder().create();

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        HttpSession session = req.getSession(false);
        Map<String, Object> user = (session != null) ? (Map<String, Object>) session.getAttribute("user") : null;
        
        if (user == null || !Boolean.TRUE.equals(user.get("can_manage_tasks"))) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }
        
        if ("getAvailableUsers".equals(action)) {
            handleGetAvailableUsers(req, resp);
            return;
        } else if ("getAssignedUsers".equals(action)) {
            handleGetAssignedUsers(req, resp);
            return;
        } else if ("getLastInsertedTaskId".equals(action)) {
            handleGetLastInsertedTaskId(req, resp);
            return;
        } else if ("getUserDetails".equals(action)) {
            handleGetUserDetails(req, resp);
            return;
        } else if ("edit".equals(action)) {
            handleEditForm(req, resp, user);
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
    
    private void handleEditForm(HttpServletRequest request, HttpServletResponse response, Map<String, Object> user) 
            throws ServletException, IOException {
        String taskId = request.getParameter("id");
        Map<String, Object> task = null;
        
        if (taskId != null) {
            try {
                task = DatabaseService.getTaskById(Integer.parseInt(taskId));
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        
        List<Map<String, Object>> statuses = new ArrayList<>();
        List<Map<String, Object>> availableUsers = new ArrayList<>();
        
        try {
            statuses = DatabaseService.getAllTaskStatuses();
            if (Boolean.TRUE.equals(user.get("can_manage_users"))) {
                availableUsers = DatabaseService.getActiveUsersByDepartment(null);
            } else {
                String userDepartment = (String) user.get("abteilung");
                availableUsers = DatabaseService.getActiveUsersByDepartment(userDepartment);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        request.setAttribute("task", task);
        request.setAttribute("taskStatuses", statuses);
        request.setAttribute("availableUsers", availableUsers);
        
        request.getRequestDispatcher("/WEB-INF/edit-task.jsp").forward(request, response);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        PrintWriter out = resp.getWriter();

        try {
            String action = req.getParameter("action");
            
            // Wenn es sich um Zuweisungen handelt, andere Verarbeitung
            if ("saveAssignments".equals(action)) {
                handleSaveAssignments(req, resp);
                return;
            }
            
            // Ab hier normale Task-Verarbeitung
            String name = req.getParameter("name");
            if (name == null || name.trim().isEmpty()) {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\": \"Name ist erforderlich\"}");
                return;
            }
            
            String actor = "System"; // Standardwert

            // Berechtigungsprüfung
            HttpSession session = req.getSession(false);
            if (session != null) {
                Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
                if (user != null) {
                    actor = (String) user.get("username");
                }
            }

            // Parameter verarbeiten
            String startDateStr = req.getParameter("start_date");
            String endDateStr = req.getParameter("end_date");
            String abteilung = req.getParameter("abteilung");
            
            LocalDate startDate = (startDateStr == null || startDateStr.isEmpty()) ? null : LocalDate.parse(startDateStr);
            LocalDate endDate = (endDateStr == null || endDateStr.isEmpty()) ? null : LocalDate.parse(endDateStr);

            String effortParam = req.getParameter("effort_days");
            double effortDays = (effortParam == null || effortParam.isEmpty()) ? 0.0 : Double.parseDouble(effortParam);

            String progressParam = req.getParameter("progress_percent");
            int progress = (progressParam == null || progressParam.isEmpty()) ? 0 : Integer.parseInt(progressParam);
            
            String statusParam = req.getParameter("status_id");
            int statusId = (statusParam == null || statusParam.isEmpty()) ? 0 : Integer.parseInt(statusParam);

            // Aktion ausführen
            if ("add".equals(action)) {
                DatabaseService.addTask(name, startDate, endDate, effortDays, statusId, progress, abteilung, actor);
                out.print("{\"success\": true, \"message\": \"Task erfolgreich erstellt\"}");
            } else if ("edit".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                DatabaseService.updateTask(id, name, startDate, endDate, effortDays, statusId, progress, abteilung, actor);
                out.print("{\"success\": true, \"message\": \"Task erfolgreich aktualisiert\"}");
            } else {
                resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.print("{\"error\": \"Ungültige Aktion: " + action + "\"}");
            }

        } catch (NumberFormatException e) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\": \"Ungültiges Zahlenformat: " + e.getMessage() + "\"}");
        } catch (Exception e) {
            e.printStackTrace();
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\": \"Serverfehler: " + e.getMessage() + "\"}");
        }
    }
    
    private void handleSaveAssignments(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        PrintWriter out = resp.getWriter();

        try {
            // Debug: Alle empfangenen Parameter ausgeben
            System.out.println("Empfangene Parameter:");
            req.getParameterMap().forEach((key, value) -> {
                System.out.println(key + ": " + String.join(", ", value));
            });

            int taskId = Integer.parseInt(req.getParameter("taskId"));
            int count = Integer.parseInt(req.getParameter("count"));
            
            List<Map<String, Object>> assignments = new ArrayList<>();
            
            // Parameter ohne Index prüfen
            String userIdRaw = req.getParameter("userId_");
            String effortDaysRaw = req.getParameter("effortDays_");
            
            if (userIdRaw != null && effortDaysRaw != null) {
                Map<String, Object> assignment = new HashMap<>();
                assignment.put("userId", Integer.parseInt(userIdRaw.trim()));
                assignment.put("effortDays", Double.parseDouble(effortDaysRaw.trim()));
                assignments.add(assignment);
                System.out.println("Zuweisung hinzugefügt: " + assignment);
            }
            
            System.out.println("Speichere " + assignments.size() + " Zuweisungen");
            DatabaseService.saveTaskAssignments(taskId, assignments);
            
            out.print("{\"success\": true, \"message\": \"Zuweisungen erfolgreich gespeichert\"}");
            
        } catch (Exception e) {
            System.err.println("Fehler beim Speichern der Zuweisungen: " + e.getMessage());
            e.printStackTrace();
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }

    private void handleGetUserDetails(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        String userIdParam = request.getParameter("userId");
        if (userIdParam == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\": \"Fehlender Parameter: userId\"}");
            return;
        }
        
        int userId;
        try {
            userId = Integer.parseInt(userIdParam);
        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\": \"Ungültige userId\"}");
            return;
        }
        
        try {
            Map<String, Object> userDetails = DatabaseService.getUserById(userId);
            
            if (userDetails == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                out.print("{\"error\": \"Benutzer nicht gefunden\"}");
                return;
            }
            
            // Nur die benötigten Felder zurückgeben
            Map<String, Object> userResponse = new HashMap<>();
            userResponse.put("id", userDetails.get("id"));
            userResponse.put("name", userDetails.get("name"));
            userResponse.put("vorname", userDetails.get("vorname"));
            userResponse.put("abteilung", userDetails.get("abteilung"));
            
            out.print(gson.toJson(userResponse));
            
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\": \"Datenbankfehler: " + e.getMessage() + "\"}");
        }
    }
}