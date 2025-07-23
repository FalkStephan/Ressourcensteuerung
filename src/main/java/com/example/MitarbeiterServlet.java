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

@WebServlet("/mitarbeiter")
public class MitarbeiterServlet extends HttpServlet {
    private MitarbeiterDAO mitarbeiterDAO;

    public void init() {
        mitarbeiterDAO = new MitarbeiterDAO();
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect("login"); // Zum Login umleiten, wenn nicht angemeldet
            return;
        }

        // Benutzerdaten als Map aus der Session holen
        Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
        
        // Annahme: Das Recht wird als Boolean 'can_manage_users' gespeichert
        boolean hatRecht = (boolean) user.getOrDefault("can_manage_users", false);

        if (!hatRecht) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Zugriff verweigert");
            return;
        }

        try {
            List<Mitarbeiter> mitarbeiterListe;
            String userAbteilung = (String) user.get("abteilung");

            if (userAbteilung != null && !userAbteilung.isEmpty()) {
                mitarbeiterListe = mitarbeiterDAO.getMitarbeiterByAbteilung(userAbteilung);
            } else {
                mitarbeiterListe = mitarbeiterDAO.getAllMitarbeiter();
            }
            
            request.setAttribute("mitarbeiterListe", mitarbeiterListe);
            request.getRequestDispatcher("/mitarbeiter.jsp").forward(request, response);

        } catch (SQLException e) {
            throw new ServletException("Datenbankfehler", e);
        }
    }
}