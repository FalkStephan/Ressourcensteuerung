<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Abwesenheiten" scope="request"/>
    <jsp:include page="/WEB-INF/_header.jsp"/>
    <style>
        .user-card { margin-bottom: 2em; padding: 1em; border: 1px solid #ddd; border-radius: 5px; }
        .user-header { display: flex; justify-content: space-between; align-items: center; }
    </style>
</head>
<body>
<div class="layout-wrapper">
    <jsp:include page="/WEB-INF/_nav.jsp"/>
    <main>
        <div class="container">
            <h2>Abwesenheiten verwalten</h2>

            <div class="search-container">
                <input type="text" id="userSearch" onkeyup="filterUsers()" placeholder="Benutzer suchen...">
            </div>

            <c:forEach var="entry" items="${userAbsences}">
                <c:set var="user" value="${entry.key}"/>
                <c:set var="absences" value="${entry.value}"/>
                <div class="user-card">
                    <div class="user-header">
                        <h3><c:out value="${user.vorname} ${user.name}"/> (<c:out value="${user.abteilung}"/>)</h3>
                        <button class="button small create" onclick="showAddModal(${user.id})">Abwesenheit hinzufügen</button>
                    </div>
                    <c:if test="${not empty absences}">
                        <table>
                            <thead><tr><th>Von</th><th>Bis</th><th>Grund</th><th>Aktion</th></tr></thead>
                            <tbody>
                            <c:forEach var="absence" items="${absences}">
                                <tr>
                                    <td><fmt:formatDate value="${absence.start_date}" type="date" pattern="dd.MM.yyyy"/></td>
                                    <td><fmt:formatDate value="${absence.end_date}" type="date" pattern="dd.MM.yyyy"/></td>
                                    <td><c:out value="${absence.reason}"/></td>
                                    <td>
                                        <%-- KORREKTUR: Der Button ruft jetzt das Modal auf --%>
                                        <button type="button" class="button small delete"
                                                onclick="showDeleteModal(this)"
                                                data-id="${absence.id}"
                                                data-description="Abwesenheit für ${user.username} vom <fmt:formatDate value='${absence.start_date}' type='date' pattern='dd.MM.yyyy'/>">
                                            Löschen
                                        </button>
                                    </td>
                                </tr>
                            </c:forEach>
                            </tbody>
                        </table>
                    </c:if>
                    <c:if test="${empty absences}">
                        <p>Keine Abwesenheiten erfasst.</p>
                    </c:if>
                </div>
            </c:forEach>
        </div>
    </main>
</div>

<div id="addAbsenceModal" class="modal-overlay" style="display:none;">
    <div class="modal-content">
        <h3>Neue Abwesenheit</h3>
        <form id="addAbsenceForm" method="post" action="calendar">
            <input type="hidden" name="action" value="add_absence"/>
            <input type="hidden" name="userId" id="absenceUserId"/>
            <div>
                <label for="startDate">Von-Datum:</label>
                <input type="date" id="startDate" name="startDate" required/>
            </div>
            <div>
                <label for="endDate">Bis-Datum:</label>
                <input type="date" id="endDate" name="endDate" required/>
            </div>
            <div>
                <label for="reason">Grund (optional):</label>
                <input type="text" id="reason" name="reason"/>
            </div>
            <div class="modal-buttons">
                <button type="submit" class="button create">Speichern</button>
                <button type="button" class="button delete" onclick="hideAddModal()">Abbrechen</button>
            </div>
        </form>
    </div>
</div>

<div id="deleteAbsenceModal" class="modal-overlay" style="display:none;">
    <div class="modal-content">
        <p>Soll dieser Eintrag wirklich gelöscht werden?</p>
        <p><strong id="deleteAbsenceDescription"></strong></p>
        <form id="deleteAbsenceForm" method="post" action="calendar">
            <input type="hidden" name="action" value="delete_absence" />
            <input type="hidden" name="id" id="deleteAbsenceId" />
            <div class="modal-buttons">
                <button type="submit" class="button delete">Ja, löschen</button>
                <button type="button" class="button" onclick="hideDeleteModal()">Abbrechen</button>
            </div>
        </form>
    </div>
</div>

<script>
    function showAddModal(userId) {
        document.getElementById('absenceUserId').value = userId;
        document.getElementById('addAbsenceModal').style.display = 'flex';
    }
    function hideAddModal() {
        document.getElementById('addAbsenceModal').style.display = 'none';
    }

    function showDeleteModal(btn) {
        const id = btn.dataset.id;
        const description = btn.dataset.description;
        document.getElementById('deleteAbsenceId').value = id;
        document.getElementById('deleteAbsenceDescription').textContent = description;
        document.getElementById('deleteAbsenceModal').style.display = 'flex';
    }
    function hideDeleteModal() {
        document.getElementById('deleteAbsenceModal').style.display = 'none';
    }

    function filterUsers() {
        const input = document.getElementById('userSearch');
        const filter = input.value.toLowerCase();
        const userCards = document.querySelectorAll('.user-card');

        userCards.forEach(card => {
            const userName = card.querySelector('h3').textContent.toLowerCase();
            if (userName.includes(filter)) {
                card.style.display = '';
            } else {
                card.style.display = 'none';
            }
        });
    }
</script>
</body>
</html>