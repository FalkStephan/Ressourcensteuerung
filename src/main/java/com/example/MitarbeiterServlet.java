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

@WebServlet("/mitarbeiter")
public class MitarbeiterServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendRedirect("login");
            return;
        }

        String search = req.getParameter("search");
        String sortField = req.getParameter("sort");
        String sortDir = req.getParameter("dir");
        
        // KORREKTUR: Der Parameter "abteilung" wurde aus dem Aufruf entfernt, um der Definition zu entsprechen
        List<Map<String, Object>> mitarbeiter = DatabaseService.getMitarbeiterList(search, null, sortField, sortDir);
        req.setAttribute("mitarbeiter", mitarbeiter);
        req.getRequestDispatcher("/WEB-INF/mitarbeiter.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendRedirect("login");
            return;
        }

        Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
        String actor = (String) user.get("username");
        String action = req.getParameter("action");

        try {
            if ("add".equals(action)) {
                DatabaseService.addMitarbeiter(
                    req.getParameter("name"),
                    req.getParameter("stelle"),
                    req.getParameter("team"),
                    req.getParameter("abteilung"),
                    actor
                );
            } else if ("edit".equals(action)) {
                DatabaseService.updateMitarbeiter(
                    Integer.parseInt(req.getParameter("id")),
                    req.getParameter("name"),
                    req.getParameter("stelle"),
                    req.getParameter("team"),
                    req.getParameter("abteilung"),
                    actor
                );
            } else if ("delete".equals(action)) {
                DatabaseService.deleteMitarbeiter(
                    Integer.parseInt(req.getParameter("id")),
                    actor
                );
            }
        } catch (Exception e) {
            req.setAttribute("error", e.getMessage());
        }
        resp.sendRedirect("mitarbeiter");
    }
}