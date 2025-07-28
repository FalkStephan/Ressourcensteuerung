    <style>
    .user-status-pill {
        display: inline-block;
        min-width: 70px;
        text-align: center;
        padding: 2px 14px;
        border-radius: 999px;
        font-size: 0.95em;
        font-weight: normal;
        border: 2px solid transparent;
        margin: 0 auto;
    }
    .user-status-aktiv {
        background: #e6ffe6;
        color: #218838;
        border-color: #28a745;
    }
    .user-status-inaktiv {
        background: #ffe6e6;
        color: #c82333;
        border-color: #dc3545;
    }
    </style>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
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
                <button type="button" class="button create" onclick="showUserForm('add')">Neuen Benutzer anlegen</button>

                <div class="search-container">
                    <input type="text" id="userSearch" onkeyup="filterTable()" placeholder="Benutzer suchen...">
                </div>

                <table id="userTable">
                    <thead>
                        <tr>
                            <th class="sortable-header" onclick="sortTable(0, 'number')">ID</th>
                            <th class="sortable-header" onclick="sortTable(1, 'string')">Mitarbeiterkennung</th>
                            <th class="sortable-header" onclick="sortTable(2, 'string')">Name</th>
                            <th class="sortable-header" onclick="sortTable(3, 'string')">Vorname</th>
                            <th class="sortable-header" onclick="sortTable(4, 'string')">Stelle</th>
                            <th class="sortable-header" onclick="sortTable(5, 'string')">Team</th>
                            <th class="sortable-header" onclick="sortTable(6, 'string')">Benutzerverwaltung</th>
                            <th class="sortable-header" onclick="sortTable(7, 'string')">Logbuch</th>
                            <th class="sortable-header" onclick="sortTable(8, 'string')">Abteilung</th>
                            <th class="sortable-header" onclick="sortTable(9, 'string')">Status</th>
                            <th>Aktionen</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="u" items="${users}">
                            <tr>
                                <td>${u.id}</td>
                                <td>
                                    <c:out value="${u.username}" />
                                </td>
                                <td><c:out value="${u.name}" /></td>
                                <td><c:out value="${u.vorname}" /></td>
                                <td><c:out value="${u.stelle}" /></td>
                                <td><c:out value="${u.team}" /></td>
                                <td>${u.can_manage_users ? 'Ja' : 'Nein'}</td>
                                <td>${u.can_view_logbook ? 'Ja' : 'Nein'}</td>
                                <td><c:out value="${u.abteilung}" /></td>
                                <td style="text-align: center; vertical-align: middle;">
                            <c:if test="${u.is_user}">
                                <span title="Benutzerkonto" style="margin-right:4px; color:#007bff; vertical-align:middle;">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:middle;"><path d="M20 21v-2a4 4 0 0 0-3-3.87"/><path d="M4 21v-2a4 4 0 0 1 3-3.87"/><circle cx="12" cy="7" r="4"/></svg>
                                </span>
                            </c:if>
                            <span class="user-status-pill ${u.active ? 'user-status-aktiv' : 'user-status-inaktiv'}">
                                ${u.active ? 'Aktiv' : 'Inaktiv'}
                            </span>
                                </td>
                                <td>
                                    <button type="button" class="button small" onclick="showUserForm('edit', this)" 
                                        data-id="${u.id}"
                                        data-username="${u.username}"
                                        data-name="${u.name}"
                                        data-vorname="${u.vorname}"
                                        data-stelle="${u.stelle}"
                                        data-team="${u.team}"
                                        data-can_manage_users="${u.can_manage_users}"
                                        data-can_view_logbook="${u.can_view_logbook}"
                                        data-abteilung="${u.abteilung}"
                                        data-active="${u.active}"
                                        data-is_user="${u.is_user}">
                                        Bearbeiten
                                    </button>
                                    <c:if test="${sessionScope.user.username != u.username}">
                                        <form action="${pageContext.request.contextPath}/users/delete" method="post" style="display:inline;" class="delete-form">
                                            <input type="hidden" name="id" value="${u.id}">
                                            <button type="button" class="button small delete" onclick="showDeleteModal(this)"
                                                data-id="${u.id}" 
                                                data-username="${fn:escapeXml(u.username)}">
                                                Löschen
                                            </button>
                                        </form>
                                    </c:if>
                                </td>
                            </tr>
                        </c:forEach>
                        <c:if test="${empty users}">
                            <tr>
                                <td colspan="6" style="text-align: center;">Keine Benutzer gefunden.</td>
                            </tr>
                        </c:if>
                    </tbody>
                </table>
            </div>
        </main>

    <!-- Modal für Benutzer anlegen/bearbeiten -->
    <div id="userModal" class="modal-overlay" style="display:none;">
        <div class="modal-content">
            <form id="userForm" method="post">
                <input type="hidden" name="id" id="userFormId" />
                <input type="hidden" name="action" id="userFormAction" value="add" />
                <!-- 1. Zeile: Mitarbeiterkennung -->
                <div>
                    <label for="userFormUsername">Mitarbeiterkennung<span class="required-star">*</span>:</label>
                    <input type="text" id="userFormUsername" name="username" required />
                </div>
                <!-- 2. Zeile: Vorname, Name -->
                <div style="display: flex; gap: 1em;">
                    <div style="flex:1;">
                        <label for="userFormVorname">Vorname<span class="required-star">*</span>:</label>
                        <input type="text" id="userFormVorname" name="vorname" required />
                    </div>
                    <div style="flex:1;">
                        <label for="userFormName">Name<span class="required-star">*</span>:</label>
                        <input type="text" id="userFormName" name="name" required />
                    </div>
                </div>
                <!-- 3. Zeile: Abteilung, Team -->
                <div style="display: flex; gap: 1em;">
                    <div style="flex:1;">
                        <label for="userFormAbteilung">Abteilung:</label>
                        <input type="text" id="userFormAbteilung" name="abteilung" />
                    </div>
                    <div style="flex:1;">
                        <label for="userFormTeam">Team:</label>
                        <input type="text" id="userFormTeam" name="team" />
                    </div>
                </div>
                <!-- 4. Zeile: Stelle, Aktiv -->
                <div style="display: flex; gap: 1em; align-items: center;">
                    <div style="flex:1;">
                        <label for="userFormStelle">Stelle:</label>
                        <input type="text" id="userFormStelle" name="stelle" />
                    </div>
                    <div style="flex:1; margin-top: 2em;">
                        <label for="userFormActive">
                            <input type="checkbox" id="userFormActive" name="active"> Aktiv
                        </label>
                    </div>
                </div>
                <!-- 5. Zeile: ist Benutzer, Passwort (nur wenn ist Benutzer aktiv) -->
                <div style="display: flex; gap: 1em; align-items: center;">
                    <div style="flex:1;">
                        <!-- Hidden field, damit beim Deaktivieren der Checkbox der Wert immer gesendet wird 
                         <input type="hidden" name="is_user" value="off" /> 
                         -->
                        <label for="userFormIsUser">
                            <input type="checkbox" id="userFormIsUser" name="is_user" value="on" checked onchange="toggleUserFields()"> ist Benutzer
                        </label>
                    </div>
                    <div style="flex:1;" id="passwordFieldWrapper">
                        <label for="userFormPassword">Passwort<span class="required-star">*</span>:</label>
                        <input type="password" id="userFormPassword" name="password" required />
                    </div>
                </div>
                <!-- 6. Zeile: Rechte (nur wenn ist Benutzer aktiv) -->
                <div style="margin-top: 1em;" id="rechteFieldWrapper">
                    <label style="display: block; margin-bottom: 10px;">Rechte:</label>
                    <label for="userFormCanManageUsers">
                        <input type="checkbox" id="userFormCanManageUsers" name="can_manage_users"> Benutzerverwaltung
                    </label>
                    <label for="userFormCanViewLogbook" style="margin-left: 2em;">
                        <input type="checkbox" id="userFormCanViewLogbook" name="can_view_logbook"> Logbuch
                    </label>
                </div>
                <div class="modal-buttons" style="margin-top: 2em;">
                    <button type="submit" class="button create">Speichern</button>
                    <button type="button" class="button delete" onclick="hideUserModal()">Abbrechen</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Modal für Löschen -->
    <div id="deleteUserModal" class="modal-overlay" style="display:none;">
        <div class="modal-content">
            <p><strong id="deleteUserName"></strong></p>
            <p id="deleteUserText">Soll dieser Benutzer wirklich gelöscht werden?</p>
            <form id="deleteUserForm" method="post" action="${pageContext.request.contextPath}/users/delete">
                <input type="hidden" name="id" id="deleteUserId" />
                <div class="modal-buttons">
                    <button type="submit" class="button delete">Ja, löschen</button>
                    <button type="button" class="button" onclick="hideDeleteModal()">Abbrechen</button>
                </div>
            </form>
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

        // --- Benutzer-Modal ---
        function showUserForm(mode, btn) {
            const modal = document.getElementById('userModal');
            const form = document.getElementById('userForm');
            document.getElementById('userFormPassword').required = (mode === 'add');
            if (mode === 'add') {
                form.action = "${pageContext.request.contextPath}/users/add";
                document.getElementById('userFormAction').value = 'add';
                document.getElementById('userFormId').value = '';
                document.getElementById('userFormUsername').value = '';
                document.getElementById('userFormName').value = '';
                document.getElementById('userFormVorname').value = '';
                document.getElementById('userFormStelle').value = '';
                document.getElementById('userFormTeam').value = '';
                document.getElementById('userFormPassword').value = '';
                document.getElementById('userFormCanManageUsers').checked = false;
                document.getElementById('userFormCanViewLogbook').checked = false;
                document.getElementById('userFormAbteilung').value = '';
                document.getElementById('userFormActive').checked = true;
                document.getElementById('userFormIsUser').checked = true;
                toggleUserFields();
            } else if (mode === 'edit' && btn) {
                form.action = "${pageContext.request.contextPath}/users/edit";
                document.getElementById('userFormAction').value = 'edit';
                document.getElementById('userFormId').value = btn.dataset.id;
                document.getElementById('userFormUsername').value = btn.dataset.username;
                document.getElementById('userFormName').value = btn.dataset.name || '';
                document.getElementById('userFormVorname').value = btn.dataset.vorname || '';
                document.getElementById('userFormStelle').value = btn.dataset.stelle || '';
                document.getElementById('userFormTeam').value = btn.dataset.team || '';
                document.getElementById('userFormPassword').value = '';
                document.getElementById('userFormCanManageUsers').checked = (btn.dataset.can_manage_users === 'true');
                document.getElementById('userFormCanViewLogbook').checked = (btn.dataset.can_view_logbook === 'true');
                document.getElementById('userFormAbteilung').value = btn.dataset.abteilung || '';
                document.getElementById('userFormActive').checked = (btn.dataset.active === 'true');
                const isUserVal = btn.dataset.is_user;
                document.getElementById('userFormIsUser').checked = (isUserVal === 'true' || isUserVal === true || isUserVal === 1 || isUserVal === '1');
                toggleUserFields();
            }
            modal.style.display = 'flex';
        }
        function hideUserModal() {
            document.getElementById('userModal').style.display = 'none';
        }

        // --- Löschen-Modal ---
        function showDeleteModal(btn) {
            const id = btn.getAttribute('data-id');
            const username = btn.getAttribute('data-username');
            document.getElementById('deleteUserId').value = id;
            document.getElementById('deleteUserName').textContent = username;
            document.getElementById('deleteUserText').innerHTML = 'Soll dieser Benutzer wirklich gelöscht werden?';
            document.getElementById('deleteUserModal').style.display = 'flex';
        }
        function hideDeleteModal() {
            document.getElementById('deleteUserModal').style.display = 'none';
        }

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
        // --- Felder ein-/ausblenden je nach "ist Benutzer" ---
        // (Logik für is_user entfernt)
        function toggleUserFields() {
            const isUser = document.getElementById('userFormIsUser').checked;
            document.getElementById('passwordFieldWrapper').style.display = isUser ? '' : 'none';
            document.getElementById('rechteFieldWrapper').style.display = isUser ? '' : 'none';
            document.getElementById('userFormPassword').required = isUser;
        }
        // Initial beim Öffnen Modal setzen:
        document.addEventListener('DOMContentLoaded', function() {
            if (document.getElementById('userFormIsUser')) {
                toggleUserFields();
            }
        });
        // Auch beim Öffnen Modal setzen:
        // (Diese zweite Definition wird entfernt, die Logik ist bereits in der ersten showUserForm enthalten)
    </script>
</body>
</html>