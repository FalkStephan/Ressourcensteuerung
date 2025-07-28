<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Benutzer hinzufügen" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
</head>
<body>
    <jsp:include page="/WEB-INF/_nav.jsp" />
    <main>
        <div class="container">
            <h2>Neuen Benutzer anlegen</h2>
            <form action="${pageContext.request.contextPath}/users/add" method="post">
                <c:if test="${not empty error}">
                    <p style="color:red;"><c:out value="${error}"/></p>
                </c:if>
                <!-- 1. Zeile: Anmeldename -->
                <div>
                    <label for="username">Anmeldename<span class="required-star">*</span>:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                <!-- 2. Zeile: Vorname, Name -->
                <div style="display: flex; gap: 1em;">
                    <div style="flex:1;">
                        <label for="vorname">Vorname<span class="required-star">*</span>:</label>
                        <input type="text" id="vorname" name="vorname" required>
                    </div>
                    <div style="flex:1;">
                        <label for="name">Name<span class="required-star">*</span>:</label>
                        <input type="text" id="name" name="name" required>
                    </div>
                </div>
                <!-- 3. Zeile: Abteilung, Team -->
                <div style="display: flex; gap: 1em;">
                    <div style="flex:1;">
                        <label for="abteilung">Abteilung:</label>
                        <input type="text" id="abteilung" name="abteilung">
                    </div>
                    <div style="flex:1;">
                        <label for="team">Team:</label>
                        <input type="text" id="team" name="team">
                    </div>
                </div>
                <!-- 4. Zeile: Stelle, Aktiv -->
                <div style="display: flex; gap: 1em; align-items: center;">
                    <div style="flex:1;">
                        <label for="stelle">Stelle:</label>
                        <input type="text" id="stelle" name="stelle">
                    </div>
                    <div style="flex:1; margin-top: 2em;">
                        <label for="active">
                            <input type="checkbox" id="active" name="active" checked> Aktiv
                        </label>
                    </div>
                </div>
                <!-- 5. Zeile: ist Benutzer, Passwort -->
                <div style="display: flex; gap: 1em; align-items: center;">
                    <div style="flex:1;">
                        <label for="is_user">
                            <input type="checkbox" id="is_user" name="is_user" checked> ist Benutzer
                        </label>
                    </div>
                    <div style="flex:1;">
                        <label for="password">Passwort<span class="required-star">*</span>:</label>
                        <input type="password" id="password" name="password" required>
                    </div>
                </div>
                <!-- 6. Zeile: Rechte -->
                <div style="margin-top: 1em;">
                    <label style="display: block; margin-bottom: 10px;">Rechte:</label>
                    <label for="can_manage_users">
                        <input type="checkbox" id="can_manage_users" name="can_manage_users"> Benutzerverwaltung
                    </label>
                    <label for="can_view_logbook" style="margin-left: 2em;">
                        <input type="checkbox" id="can_view_logbook" name="can_view_logbook"> Logbuch
                    </label>
                </div>
                <div class="modal-buttons" style="margin-top: 2em;">
                    <button type="submit" class="button create">Speichern</button>
                    <a href="${pageContext.request.contextPath}/users" class="button delete">Abbrechen</a>
                </div>
            </form>
        </div>
    </main>
</body>
</html>