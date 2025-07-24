
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
            resp.sendRedirect("login.jsp");
            return;
        }
        Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
        String abteilung = (String) user.get("abteilung");
        String search = req.getParameter("search");
        String sort = req.getParameter("sort");
        String dir = req.getParameter("dir");
        List<Map<String, Object>> mitarbeiter = DatabaseService.getMitarbeiterList(search, abteilung, sort, dir);
        req.setAttribute("mitarbeiter", mitarbeiter);
        req.getRequestDispatcher("WEB-INF/mitarbeiter.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            resp.sendRedirect("login.jsp");
            return;
        }
        Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
        String actor = (String) user.get("username");
        String action = req.getParameter("action");
        try {
            if ("add".equals(action)) {
                String name = req.getParameter("name");
                String stelle = req.getParameter("stelle");
                String team = req.getParameter("team");
                String abteilung = req.getParameter("abteilung");
                DatabaseService.addMitarbeiter(name, stelle, team, abteilung, actor);
            } else if ("edit".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                String name = req.getParameter("name");
                String stelle = req.getParameter("stelle");
                String team = req.getParameter("team");
                String abteilung = req.getParameter("abteilung");
                DatabaseService.updateMitarbeiter(id, name, stelle, team, abteilung, actor);
            } else if ("delete".equals(action)) {
                int id = Integer.parseInt(req.getParameter("id"));
                DatabaseService.deleteMitarbeiter(id, actor);
            }
        } catch (Exception e) {
            req.setAttribute("error", e.getMessage());
        }
        resp.sendRedirect("mitarbeiter");
    }
}
