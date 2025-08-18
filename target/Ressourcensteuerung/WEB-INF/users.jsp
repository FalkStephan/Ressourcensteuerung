<style>
    .user-status-pill {
        display: inline-block; min-width: 70px; text-align: center; padding: 2px 14px;
        border-radius: 999px; font-size: 0.95em; border: 2px solid transparent; margin: 0 auto;
    }
    .user-status-aktiv { background: #e6ffe6; color: #218838; border-color: #28a745; }
    .user-status-inaktiv { background: #ffe6e6; color: #c82333; border-color: #dc3545; }
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
                <button type="button" class="button create" style="margin-left:1em;"onclick="showImportModal()">Benutzer importieren</button>
                <a href="${pageContext.request.contextPath}/users/export" class="button" style="background:#007bff; color:#fff; margin-left:1em;">Benutzer exportieren</a>
                <div id="importUserModal" class="modal-overlay" style="display:none;">
                    <div class="modal-content" style="max-width:400px;">
                        <h3>Benutzer importieren</h3>
                        <form id="importUserForm" method="post" action="${pageContext.request.contextPath}/users/import" enctype="multipart/form-data">
                            <input type="file" name="importFile" id="importFile" accept=".csv,.xlsx,.xls,.txt" required style="margin-bottom:1em;"/>
                        <div style="margin-bottom:1em;">
                            <label style="display:block; margin-bottom:0.5em;">
                                <input type="checkbox" name="import_new" id="importNew" checked>neue Benutzer importieren
                            </label>
                            <label style="display:block; margin-bottom:0.5em;">
                                <input type="checkbox" name="update_existing" id="updateExisting" checked>bestehende Benutzer aktualisieren
                            </label>
                            <label style="display:block;">
                                <input type="checkbox" name="deactivate_missing" id="deactivateMissing">nicht enthaltene Benutzer deaktivieren
                            </label>
                        </div>
                        <div class="modal-buttons" style="display:flex; gap:0.5em;">
                            <a href="${pageContext.request.contextPath}/resources/Muster.xlsx" download class="button" style="background:#007bff; color:#fff;">Musterdatei herunterladen</a>
                            <button type="submit" class="button create">Datei importieren</button>
                            <button type="button" class="button delete" onclick="hideImportModal()">Abbrechen</button>
                        </div>
                        </form>
                    </div>
                </div>
                <div id="importFeedbackModal" class="modal-overlay" style="display:none;">
                    <div class="modal-content" style="max-width:400px;">
                        <h3>Import-Ergebnis</h3>
                        <div id="importFeedbackModalBody"></div>
                        <div  class="modal-buttons" style="margin-top:1em;">
                            <button type="button" class="button" onclick="hideImportFeedbackModal()">Schließen</button>
                        </div>
                    </div>
                </div>

                <div class="search-container">
                    <input type="text" id="userSearch"  onkeyup="filterTable()" placeholder="Benutzer suchen...">
                    <select id="statusFilter" onchange="filterTable()" style="margin-left:1em;">
                        <option value="all">Alle</option>
                        <option value="active" selected>Nur aktive</option>
                        <option value="inactive">Nur inaktive</option>
                    </select>
                    <select id="typeFilter" onchange="filterTable()" style="margin-left:1em;">
                        <option value="all">Alle</option>
                        <option value="user">Nur Benutzer</option>
                    </select>
                    <button type="button" class="button small" style="margin-bottom:0.5em;" onclick="showColModal()">Spalten wählen</button>
                    <div id="colModal" class="modal-overlay" style="display:none;">
                        <div class="modal-content" style="max-width:420px;">
                            <h3>Spalten ein-/ausblenden</h3>
                            <div id="columnSelector" style="margin-left: 2em;">
                                <label><input type="checkbox" class="col-toggle" data-col="0" checked> ID</label>
                                <label><input type="checkbox" class="col-toggle" data-col="1" checked> Mitarbeiterkennung</label>
                                <label><input type="checkbox" class="col-toggle" data-col="2" checked> Name</label>
                                <label><input type="checkbox" class="col-toggle" data-col="3" checked> Vorname</label>
                                <label><input type="checkbox" class="col-toggle" data-col="4" checked> Stelle</label>
                                <label><input type="checkbox" class="col-toggle" data-col="5" checked> Team</label>
                                <label><input type="checkbox" class="col-toggle" data-col="6" checked> Benutzerverwaltung</label>
                                <label><input type="checkbox" class="col-toggle" data-col="7" checked> Logbuch</label>
                                <label><input type="checkbox" class="col-toggle" data-col="8" checked> Abteilung</label>
                            </div>
                            <div class="modal-buttons"> 
                                <button type="button" class="button create" onclick="hideColModal()">OK</button>
                            </div>
                        </div>
                    </div>
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
                                <td> <c:out value="${u.username}" /></td>
                                <td><c:out value="${u.name}" /></td>
                                <td><c:out value="${u.vorname}" /></td>
                                <td><c:out value="${u.abteilung}" /></td>
                                <td><c:out value="${u.team}" /></td>
                                <td><c:out value="${u.stelle}" /></td>
                                <td>${u.can_manage_users ? 'Ja' : 'Nein'}</td>
                                <td>${u.can_view_logbook ? 'Ja' : 'Nein'}</td>
                                <td style="text-align: center; vertical-align: middle;"> 
                                    <c:if test="${u.is_user}">
                                        <span title="Benutzerkonto" style="margin-right:4px; color:${u.see_all_users ? '#e74c3c' : '#007bff'}; vertical-align:middle;">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="vertical-align:middle;"><path d="M20 21v-2a4 4 0 0 0-3-3.87"/><path d="M4 21v-2a4 4 0 0 1 3-3.87"/><circle cx="12" cy="7" r="4"/></svg>
                                        </span>
                                    </c:if>
                                    <span class="user-status-pill ${u.active ? 'user-status-aktiv' : 'user-status-inaktiv'}">${u.active ? 'Aktiv' : 'Inaktiv'}</span>
                                </td>
                                <td>
                                    <button type="button" class="button small" onclick="showUserForm('edit', this)"
                                        data-id="${u.id}"
                                        data-username="${u.username}"
                                        data-name="${u.name}"
                                        data-vorname="${u.vorname}"
                                        data-stelle="${u.stelle}"
                                        data-team="${u.team}"
                                        data-abteilung="${u.abteilung}"
                                        data-active="${u.active}"
                                        data-is-user="${u.is_user}"
                                        data-can-manage-users="${u.can_manage_users}"
                                        data-can-view-logbook="${u.can_view_logbook}"
                                        data-can-manage-feiertage="${u.can_manage_feiertage}"
                                        data-see-all-users="${u.see_all_users}"
                                        data-can-manage-calendar="${u.can_manage_calendar}"
                                        data-can-manage-capacities="${u.can_manage_capacities}"
                                        data-can-manage-settings="${u.can_manage_settings}"
                                        data-can-manage-tasks="${u.can_manage_tasks}">
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

        <div id="userModal" class="modal-overlay" style="display:none;">
            <div class="modal-content">
                <form id="userForm" method="post">
                    <input type="hidden" name="id" id="userFormId" />
                    <input type="hidden" name="action" id="userFormAction" value="add" />
                    <div>
                        <label for="userFormUsername">Mitarbeiterkennung<span class="required-star">*</span>:</label>
                        <input type="text" id="userFormUsername" name="username" required />
                    </div>
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
                    <div style="display: flex; gap: 1em; align-items: center;">
                        <div style="flex:1;">
                            <label for="userFormIsUser">
                                <input type="checkbox" id="userFormIsUser" name="is_user" value="on" checked onchange="toggleUserFields()"> ist Benutzer
                            </label>
                        </div>
                        <div style="flex:1;" id="passwordFieldWrapper">
                            <label for="userFormPassword" id="passwordLabel"></label>
                            <input type="password" id="userFormPassword" name="password" />
                        </div>
                    </div>
                
                    <div id="rechteFieldWrapper" style="margin-top: 1em;">
                        <label style="display: block; margin-bottom: 10px; font-weight: bold;">Rechte:</label>
                        
                        <div style="display: flex; gap: 1.5em;">
                            <label><input type="checkbox" id="userFormCanManageUsers" name="can_manage_users"> Benutzerverwaltung</label>
                            <label><input type="checkbox" id="userFormSeeAllUsers" name="see_all_users"> Alle Benutzer sehen</label>
                        </div>
                        
                        <div style="display: flex; gap: 1.5em;">
                            <label><input type="checkbox" id="userFormCanManageCalendar" name="can_manage_calendar"> Abwesenheiten</label>
                            <label><input type="checkbox" id="userFormCanManageCapacities" name="can_manage_capacities"> Kapazitäten</label>
                            <label><input type="checkbox" id="userFormCanManageFeiertage" name="can_manage_feiertage"> Feiertage</label>
                        </div>

                        <div style="display: flex; gap: 1.5em;">
                            <label><input type="checkbox" id="userFormCanManageTasks" name="can_manage_tasks"> Aufgaben</label>
                            <label><input type="checkbox" id="userFormCanManageSettings" name="can_manage_settings"> Einstellungen</label>
                            <label><input type="checkbox" id="userFormCanViewLogbook" name="can_view_logbook"> Logbuch</label>
                        </div>
                    </div>
               
                    <div class="modal-buttons" style="margin-top: 2em;">
                        <button type="submit" class="button create">Speichern</button>
                        <button type="button" class="button delete" onclick="hideUserModal()">Abbrechen</button>
                    </div>
                </form>
 
            </div>
        </div>

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
            const searchInput = document.getElementById('userSearch');
            const statusFilter = document.getElementById('statusFilter');
            const typeFilter = document.getElementById('typeFilter');

            const filter = searchInput.value.toLowerCase();
            const status = statusFilter.value;
            const type = typeFilter.value;

            const table = document.getElementById('userTable');
            const tr = table.getElementsByTagName('tr');

            for (let i = 1; i < tr.length; i++) { // Start bei 1, um den Header zu überspringen
                const tds = tr[i].getElementsByTagName('td');
                const usernameTd = tds[1];
                const statusTd = tds[9];
                
                if (usernameTd && statusTd) {
                    const username = usernameTd.textContent || usernameTd.innerText;
                    
                    // Text-Filter
                    const textMatch = username.toLowerCase().indexOf(filter) > -1;

                    // Status-Filter
                    let statusMatch = true;
                    if (status !== 'all') {
                        const isActive = statusTd.querySelector('.user-status-aktiv') !== null;
                        statusMatch = (status === 'active' && isActive) || (status === 'inactive' && !isActive);
                    }
                    
                    // Typ-Filter
                    let typeMatch = true;
                    if (type === 'user') {
                        typeMatch = statusTd.querySelector('svg') !== null;
                    }
                    
                    if (textMatch && statusMatch && typeMatch) {
                        tr[i].style.display = "";
                    } else {
                        tr[i].style.display = "none";
                    }
                }
            }
        }
        
        // Initialer Aufruf, um die Standardeinstellung "Nur aktive" anzuwenden
        document.addEventListener('DOMContentLoaded', function() {
            filterTable();
        });


// --- Benutzer-Modal ---
        function showUserForm(mode, btn) {
        const modal = document.getElementById('userModal');
        const form = document.getElementById('userForm');
        
        form.action = "${pageContext.request.contextPath}/users";
        document.getElementById('userFormPassword').required = (mode === 'add');

        if (mode === 'add') {
            form.reset();
            document.getElementById('userFormAction').value = 'add';
            document.getElementById('userFormActive').checked = true;
            document.getElementById('userFormIsUser').checked = true;
        } else if (mode === 'edit' && btn) {
            form.reset();
            document.getElementById('userFormAction').value = 'edit';
            document.getElementById('userFormId').value = btn.dataset.id;
            document.getElementById('userFormUsername').value = btn.dataset.username;
            document.getElementById('userFormName').value = btn.dataset.name || '';
            document.getElementById('userFormVorname').value = btn.dataset.vorname || '';
            document.getElementById('userFormStelle').value = btn.dataset.stelle || '';
            document.getElementById('userFormTeam').value = btn.dataset.team || '';
            document.getElementById('userFormAbteilung').value = btn.dataset.abteilung || '';
            
            document.getElementById('userFormActive').checked = (btn.dataset.active === 'true');
            document.getElementById('userFormIsUser').checked = (btn.dataset.isUser === 'true');
            document.getElementById('userFormCanManageUsers').checked = (btn.dataset.canManageUsers === 'true');
            document.getElementById('userFormCanViewLogbook').checked = (btn.dataset.canViewLogbook === 'true');
            document.getElementById('userFormCanManageFeiertage').checked = (btn.dataset.canManageFeiertage === 'true');
            document.getElementById('userFormSeeAllUsers').checked = (btn.dataset.seeAllUsers === 'true');
            document.getElementById('userFormCanManageCalendar').checked = (btn.dataset.canManageCalendar === 'true');
            document.getElementById('userFormCanManageCapacities').checked = (btn.dataset.canManageCapacities === 'true');
            document.getElementById('userFormCanManageSettings').checked = (btn.dataset.canManageSettings === 'true');
            document.getElementById('userFormCanManageTasks').checked = (btn.dataset.canManageTasks === 'true');
        }
        toggleUserFields(); // Diese Funktion steuert jetzt die Passwort-Anforderung
            document.getElementById('userModal').style.display = 'flex';
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
        // --- Spaltenauswahl-Modal ---
        function showColModal() {
            document.getElementById('colModal').style.display = 'flex';
 }
        function hideColModal() {
            document.getElementById('colModal').style.display = 'none';
 }
        // --- Spaltenauswahl anwenden ---
        function applyColPrefs() {
            const colChecks = document.querySelectorAll('.col-toggle');
 const table = document.getElementById('userTable');
            if (!table) return;
            const ths = table.querySelectorAll('thead th');
 colChecks.forEach((cb, idx) => {
                if (ths[idx]) ths[idx].style.display = cb.checked ? '' : 'none';
            });
 const trs = table.querySelectorAll('tbody tr');
            trs.forEach(tr => {
                const tds = tr.querySelectorAll('td');
                colChecks.forEach((cb, idx) => {
                    if (tds[idx]) tds[idx].style.display = cb.checked ? '' : 'none';
                });
           
  });
        }
        // Eventlistener für Spaltenauswahl
        document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('.col-toggle').forEach(cb => {
                cb.addEventListener('change', function() {
                    applyColPrefs();
                });
         
    });
            applyColPrefs();
        });
 // --- Import-Modal ---
        function showImportModal() {
            document.getElementById('importUserModal').style.display = 'flex';
 }
        function hideImportModal() {
            document.getElementById('importUserModal').style.display = 'none';
 }
        // --- Import-Feedback-Modal ---
        function showImportFeedbackModal() {
            document.getElementById('importFeedbackModal').style.display = 'flex';
 }
        function hideImportFeedbackModal() {
            document.getElementById('importFeedbackModal').style.display = 'none';
 }

        // --- AJAX-Upload für Import und Feedback-Anzeige ---
        document.addEventListener('DOMContentLoaded', function() {
            var importForm = document.getElementById('importUserForm');
            if(importForm) {
                importForm.addEventListener('submit', function(e) {
                    e.preventDefault();
         
           var formData = new FormData(importForm);
                    fetch(importForm.action, {
                        method: 'POST',
                        body: formData
              
       })
                    .then(response => response.text())
                    .then(html => {
                        document.getElementById('importFeedbackModalBody').innerHTML = html;
                        
 hideImportModal();
                        showImportFeedbackModal();
                    })
                    .catch(err => {
                        document.getElementById('importFeedbackModalBody').innerHTML = '<div class="import-feedback-error">Fehler beim Upload</div>';
 hideImportModal();
                        showImportFeedbackModal();
                    });
                });
            }
        });
 // --- Felder ein-/ausblenden je nach "ist Benutzer" ---
        // (Logik für is_user entfernt)
        function toggleUserFields() {
            const isUser = document.getElementById('userFormIsUser').checked;
            const isAddMode = document.getElementById('userFormAction').value === 'add';
            const passwordInput = document.getElementById('userFormPassword');
            const passwordLabel = document.getElementById('passwordLabel');

            document.getElementById('passwordFieldWrapper').style.display = isUser ? '' : 'none';
            document.getElementById('rechteFieldWrapper').style.display = isUser ? '' : 'none';

            // KORREKTUR: Das Passwort ist nur dann erforderlich, wenn ein neuer Benutzer angelegt wird.
            if (isUser && isAddMode) {
                passwordLabel.innerHTML = 'Passwort<span class="required-star">*</span>:';
                passwordInput.required = true;
            } else {
                passwordLabel.innerHTML = 'Neues Passwort (optional):';
                passwordInput.required = false;
            }
        }
 // Auch beim Öffnen Modal setzen:
        // (Diese zweite Definition wird entfernt, die Logik ist bereits in der ersten showUserForm enthalten)
    </script>
</body>
</html>