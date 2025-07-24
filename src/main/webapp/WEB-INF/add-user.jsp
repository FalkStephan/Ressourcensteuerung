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
                <div>
                    <label for="username">Benutzername<span class="required-star">*</span>:</label>
                    <input type="text" id="username" name="username" required>
                </div>
                <div>
                    <label for="password">Passwort<span class="required-star">*</span>:</label>
                    <input type="password" id="password" name="password" required>
                </div>
                <div>
                    <label style="display: block; margin-bottom: 10px;">Rechte:</label>
                    <label for="can_manage_users">
                        <input type="checkbox" id="can_manage_users" name="can_manage_users"> Benutzerverwaltung
                    </label>
                </div>
                <div>
                    <label for="can_view_logbook">
                        <input type="checkbox" id="can_view_logbook" name="can_view_logbook"> Logbuch
                    </label>
                </div>
                <div>
                    <label for="abteilung">Abteilung:</label>
                    <input type="text" id="abteilung" name="abteilung">
                </div>
                <div class="modal-buttons">
                    <button type="submit" class="button create">Speichern</button>
                    <a href="${pageContext.request.contextPath}/users" class="button delete">Abbrechen</a>
                </div>
            </form>
        </div>
    </main>
</body>
</html>