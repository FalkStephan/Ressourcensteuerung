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
                    <p style="color:red; font-weight:bold;"><c:out value="${error}"/></p>
                </c:if>
                <div>
                    <label for="username">Benutzername:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                <div>
                    <label for="password">Passwort:</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <div>
                    <label style="display: block; font-weight: bold; margin-bottom: 10px;">Rechte:</label>
                    <label for="can_manage_users" style="display: inline-block; font-weight: normal;">
                        <input type="checkbox" id="can_manage_users" name="can_manage_users" style="width: auto;"> Benutzerverwaltung
                    </label>
                </div>
                <div>
                    <label for="can_view_logbook" style="display: inline-block; font-weight: normal;">
                        <input type="checkbox" id="can_view_logbook" name="can_view_logbook" style="width: auto;">Logbuch
                    </label>
                </div>
                <div>
                    <label for="abteilung">Abteilung (optional):</label>
                    <input type="text" id="abteilung" name="abteilung">
                </div>
                <div>
                    <button type="submit" class="button create">Speichern</button>
                    <a href="${pageContext.request.contextPath}/users" class="button delete">Abbrechen</a>
                </div>
            </form>
        </div>
    </main>
</body>
</html>