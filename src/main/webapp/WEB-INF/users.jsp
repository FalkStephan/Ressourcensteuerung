<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Benutzerverwaltung" scope="request" />
    <jsp:include page="/WEB-INF/_header.jsp" />
</head>
<body>
    <div class="layout-wrapper">
        <jsp:include page="/WEB-INF/_nav.jsp" />
        <main>
            <div class="container">
                <h2>Benutzerverwaltung</h2>
                <a href="${pageContext.request.contextPath}/users/add" class="button create">Neuen Benutzer anlegen</a>

                <div class="search-container">
                    <input type="text" id="userSearch" onkeyup="filterTable()" placeholder="Benutzer suchen...">
                </div>

                <table id="userTable">
                    <thead>
                        <tr>
                            <th class="sortable-header" onclick="sortTable(0, 'number')">ID</th>
                            <th class="sortable-header" onclick="sortTable(1, 'string')">Benutzername</th>
                            <th class="sortable-header" onclick="sortTable(2, 'string')">Benutzerverwaltung</th>
                            <th class="sortable-header" onclick="sortTable(3, 'string')">Logbuch</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="u" items="${users}">
                            <tr>
                                <td>${u.id}</td>
                                <td><c:out value="${u.username}" /></td>
                                <td>${u.can_manage_users ? 'Ja' : 'Nein'}</td>
                                <td>${u.can_view_logbook ? 'Ja' : 'Nein'}</td>
                                <td>
                                    <a href="${pageContext.request.contextPath}/users/edit?id=${u.id}" class="button small">Bearbeiten</a>
                                    <c:if test="${sessionScope.user.username != u.username}">
                                        <form action="${pageContext.request.contextPath}/users/delete" method="post" style="display:inline;" class="delete-form">
                                            <input type="hidden" name="id" value="${u.id}">
                                            <button type="submit" class="button small delete" onclick="event.preventDefault(); showConfirmModal(this.form);">Löschen</button>
                                        </form>
                                    </c:if>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty users}">
                            <tr>
                                <td colspan="5" style="text-align: center;">Keine Benutzer gefunden.</td>
                            </tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </main>
    </div>

    <div id="confirmModal" class="modal-overlay">
        <div class="modal-content">
            <p>Soll dieser Benutzer wirklich gelöscht werden?</p>
            <div class="modal-buttons">
                <button id="cancelDeleteBtn" class="button" style="background-color: #7f8c8d;">Abbrechen</button>
                <button id="confirmDeleteBtn" class="button delete">Ja, löschen</button>
            </div>
        </div>
    </div>

    <script>
        // --- Live-Suche ---
        function filterTable() {
            const input = document.getElementById('userSearch');
            const filter = input.value.toLowerCase();
            const table = document.getElementById('userTable');
            const tr = table.getElementsByTagName('tr');

            for (let i = 1; i < tr.length; i++) {
                const tdUsername = tr[i].getElementsByTagName('td')[1];
                if (tdUsername) {
                    const txtValue = tdUsername.textContent || tdUsername.innerText;
                    if (txtValue.toLowerCase().indexOf(filter) > -1) {
                        tr[i].style.display = "";
                    } else {
                        tr[i].style.display = "none";
                    }
                }
            }
        }

        // --- Bestätigungs-Modal ---
        const modal = document.getElementById('confirmModal');
        const confirmBtn = document.getElementById('confirmDeleteBtn');
        const cancelBtn = document.getElementById('cancelDeleteBtn');
        let formToSubmit = null;

        function showConfirmModal(form) {
            formToSubmit = form;
            modal.style.display = 'flex';
        }

        function hideModal() {
            modal.style.display = 'none';
            formToSubmit = null;
        }

        confirmBtn.addEventListener('click', () => {
            if (formToSubmit) {
                formToSubmit.submit();
            }
        });

        cancelBtn.addEventListener('click', hideModal);

        modal.addEventListener('click', (event) => {
            if (event.target === modal) {
                hideModal();
            }
        });

        // --- Tabellen-Sortierung ---
        let currentSortColumn = -1;
        let currentSortDir = 'asc';

        function sortTable(columnIndex, type) {
            const table = document.getElementById('userTable');
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('tr'));
            const headers = table.querySelectorAll('.sortable-header');

            const sortDir = (columnIndex === currentSortColumn && currentSortDir === 'asc') ? 'desc' : 'asc';
            
            rows.sort((a, b) => {
                const cellA = a.querySelectorAll('td')[columnIndex].innerText.toLowerCase();
                const cellB = b.querySelectorAll('td')[columnIndex].innerText.toLowerCase();

                let valA = cellA;
                let valB = cellB;

                if (type === 'number') {
                    valA = parseInt(valA, 10) || 0;
                    valB = parseInt(valB, 10) || 0;
                }

                if (valA < valB) {
                    return sortDir === 'asc' ? -1 : 1;
                }
                if (valA > valB) {
                    return sortDir === 'asc' ? 1 : -1;
                }
                return 0;
            });

            headers.forEach(header => header.classList.remove('asc', 'desc'));
            headers[columnIndex].classList.add(sortDir);

            tbody.innerHTML = '';
            rows.forEach(row => tbody.appendChild(row));
            
            currentSortColumn = columnIndex;
            currentSortDir = sortDir;
        }
    </script>
</body>
</html>