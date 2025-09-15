<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Kapazitäten" scope="request"/>
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
            <h2>Kapazitäten verwalten</h2>
            <div class="search-container">
                <input type="text" id="userSearch" onkeyup="filterUsers()" placeholder="Benutzer suchen...">
            </div>

            <c:forEach var="entry" items="${userCapacities}">
                <c:set var="user" value="${entry.key}"/>
                <c:set var="capacities" value="${entry.value}"/>
                <div class="user-card">
                    <div class="user-header">
                        <h3><c:out value="${user.vorname} ${user.name}"/> (<c:out value="${user.abteilung}"/>)</h3>
                        <button class="button small create" onclick="showAddModal(${user.id})">Kapazität hinzufügen</button>
                    </div>
                    <c:if test="${not empty capacities}">
                        <table>
                            <thead><tr>
                                <th>Gültig ab</th>
                                <th>Kapazität</th>
                                <th>Aktionen</th>
                            </tr></thead>
                            <tbody>
                            <c:forEach var="cap" items="${capacities}">
                                <tr>
                                    <td><fmt:formatDate value="${cap.start_date}" type="date" pattern="dd.MM.yyyy"/></td>
                                    <td><c:out value="${cap.capacity_percent}"/> %</td>
                                    <td>
                                        <form action="capacities" method="post" style="sind sie sicher:inline;" onsubmit="return confirm('Sind Sie sicher, dass Sie diesen Eintrag vom ${cap.start_date} löschen möchten?');">
                                            <input type="hidden" name="action" value="delete">
                                            <input type="hidden" name="capacityId" value="${cap.id}">
                                            <button type="submit" class="button small delete">Löschen</button>
                                        </form>
                                    </td>
                                </tr>
                            </c:forEach>
                            </tbody>
                        </table>
                    </c:if>
                    <c:if test="${empty capacities}">
                        <p>Keine Kapazitäten erfasst.</p>
                    </c:if>
                </div>
            </c:forEach>
        </div>
    </main>
</div>

<div id="addCapacityModal" class="modal-overlay" style="display:none;">
    <div class="modal-content">
        <h3>Neue Kapazität</h3>
        <form id="addCapacityForm" method="post" action="capacities">
            <input type="hidden" name="userId" id="capacityUserId"/>
            <div>
                <label for="startDate">Gültig ab:</label>
                <input type="date" id="startDate" name="startDate" required/>
            </div>
            <div>
                <label for="capacity">Kapazität (%):</label>
                <input type="number" id="capacity" name="capacity" min="0" max="100" required/>
            </div>
            <div class="modal-buttons">
                <button type="submit" class="button create">Speichern</button>
                <button type="button" class="button delete" onclick="hideAddModal()">Abbrechen</button>
            </div>
        </form>
    </div>
</div>

<script>
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

    
    function showAddModal(userId) {
        document.getElementById('capacityUserId').value = userId;
        document.getElementById('addCapacityModal').style.display = 'flex';
    }
    function hideAddModal() {
        document.getElementById('addCapacityModal').style.display = 'none';
    }
</script>
</body>
</html>