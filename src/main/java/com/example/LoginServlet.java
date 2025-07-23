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

    /**
     * Behandelt GET-Anfragen, indem sie das Login-Formular anzeigt.
     * Der Pfad wurde auf /WEB-INF/login.jsp korrigiert.
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // **KORREKTUR: Der Pfad zur JSP-Datei wird hier korrigiert.**
        request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
    }

    /**
     * Behandelt POST-Anfragen (das Absenden des Login-Formulars).
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        Map<String, Object> user = null;

        try {
            user = DatabaseService.findUser(username, password);
        } catch (SQLException e) {
            throw new ServletException("Datenbankfehler während des Logins.", e);
        }

        if (user != null) {
            HttpSession session = request.getSession();
            session.setAttribute("user", user);

            try {
                DatabaseService.logAction("LOGIN_SUCCESS", "Benutzer '" + username + "' hat sich erfolgreich angemeldet.", username);
            } catch (SQLException e) {
                System.err.println("Fehler beim Schreiben des Login-Log-Eintrags: " + e.getMessage());
            }

            response.sendRedirect(request.getContextPath() + "/");
        } else {
            request.setAttribute("error", "Ungültiger Benutzername oder Passwort.");
            // **KORREKTUR: Auch hier wird der Pfad zur JSP-Datei korrigiert.**
            request.getRequestDispatcher("/WEB-INF/login.jsp").forward(request, response);
        }
    }
}