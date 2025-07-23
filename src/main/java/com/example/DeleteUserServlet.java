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

@WebServlet("/users/delete")
public class DeleteUserServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        try {
            int id = Integer.parseInt(request.getParameter("id"));
            Map<String, Object> userToDelete = DatabaseService.getUserById(id);
            
            if (userToDelete == null) {
                // Benutzer existiert nicht, nichts zu tun
                response.sendRedirect(request.getContextPath() + "/users");
                return;
            }

            // Hole den angemeldeten Benutzer für die Protokollierung
            Map<String, Object> loggedInUser = (Map<String, Object>) session.getAttribute("user");
            String loggedInUsername = (String) loggedInUser.get("username");

            // Verhindere, dass sich der Benutzer selbst löscht
            if (loggedInUsername.equals(userToDelete.get("username"))) {
                // Optional: eine Fehlermeldung an den Benutzer senden
                response.sendRedirect(request.getContextPath() + "/users");
                return;
            }

            // Führe die Löschoperation aus
            DatabaseService.deleteUser(id, loggedInUsername);

        } catch (SQLException e) {
            throw new ServletException("Datenbankfehler beim Löschen des Benutzers", e);
        } catch (NumberFormatException e) {
            // Falls die ID kein gültiger Zahlenwert ist
            response.sendRedirect(request.getContextPath() + "/users");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/users");
    }
}