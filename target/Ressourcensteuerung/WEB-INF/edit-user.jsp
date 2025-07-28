<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Benutzer bearbeiten" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
</head>
<body>
    <jsp:include page="/WEB-INF/_nav.jsp" />
    <main>
        <div class="container">
            <h2>Benutzer bearbeiten</h2>
            <form action="${pageContext.request.contextPath}/users/edit" method="post">
                <input type="hidden" name="id" value="${userToEdit.id}">
                <c:if test="${not empty error}">
                    <p style="color:red;"><c:out value="${error}"/></p>
                </c:if>
                <div>
                    <label for="username">Benutzername<span class="required-star">*</span>:</label>
                    <input type="text" id="username" name="username" value="<c:out value='${userToEdit.username}'/>" required>
                </div>
                <div>
                    <label for="password">Neues Passwort (leer lassen, um es nicht zu ändern):</label>
                    <input type="password" id="password" name="password">
                </div>
                <div>
                    <label style="display: block; margin-bottom: 10px;">Rechte:</label>
                    <label for="can_manage_users">
                        <input type="checkbox" id="can_manage_users" name="can_manage_users" ${userToEdit.can_manage_users ? 'checked' : ''}> Benutzerverwaltung
                    </label>
                </div>
                <div>
                    <label for="can_view_logbook">
                        <input type="checkbox" id="can_view_logbook" name="can_view_logbook" ${userToEdit.can_view_logbook ? 'checked' : ''}> Logbuch
                    </label>
                </div>
                <div>
                    <label for="abteilung">Abteilung:</label>
                    <input type="text" id="abteilung" name="abteilung" value="<c:out value='${userToEdit.abteilung}'/>">
                </div>
                <div>
                    <label for="active">
                        <input type="checkbox" id="active" name="active" ${userToEdit.active ? 'checked' : ''}> Aktiv
                    </label>
                </div>
                <div class="modal-buttons">
                    <button type="submit" class="button create">Änderungen speichern</button>
                    <a href="${pageContext.request.contextPath}/users" class="button delete">Abbrechen</a>
                </div>
            </form>
        </div>
    </main>
</body>
</html>