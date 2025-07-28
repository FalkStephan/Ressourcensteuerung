package com.example;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String username = req.getParameter("username");
        String password = req.getParameter("password");
        Map<String, Object> user = DatabaseService.findUser(username, password);

        if (user != null) {
            Boolean isActive = (Boolean) user.get("active");
            Object isUserObj = user.get("is_user");
            boolean isUser = false;
            if (isUserObj instanceof Boolean) {
                isUser = (Boolean) isUserObj;
            } else if (isUserObj instanceof Number) {
                isUser = ((Number) isUserObj).intValue() == 1;
            } else if (isUserObj != null) {
                isUser = "true".equalsIgnoreCase(isUserObj.toString()) || "1".equals(isUserObj.toString());
            }
            if (isUser) {
                if (isActive != null && isActive) {
                    HttpSession session = req.getSession();
                    session.setAttribute("user", user);
                    try {
                        DatabaseService.logAction(username, "Login", "Benutzer hat sich erfolgreich angemeldet.");
                    } catch (SQLException e) {
                        e.printStackTrace(); // Fehler beim Loggen, aber Login trotzdem erlauben
                    }
                    resp.sendRedirect("index.jsp");
                } else {
                    req.setAttribute("error", "Ihr Benutzerkonto ist inaktiv. Bitte wenden Sie sich an den Administrator.");
                    req.getRequestDispatcher("/WEB-INF/login.jsp").forward(req, resp);
                }
            } else {
                req.setAttribute("error", "Für diesen Datensatz ist kein Login möglich.");
                req.getRequestDispatcher("/WEB-INF/login.jsp").forward(req, resp);
            }
        } else {
            req.setAttribute("error", "Ungültiger Benutzername oder Passwort.");
            req.getRequestDispatcher("/WEB-INF/login.jsp").forward(req, resp);
        }
    }
}