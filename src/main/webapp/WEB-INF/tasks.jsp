<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Aufgaben" scope="request"/>
    <jsp:include page="/WEB-INF/_header.jsp"/>
</head>
<body>
<div class="layout-wrapper">
    <jsp:include page="/WEB-INF/_nav.jsp"/>
    <main>
        <div class="container">
            <h2>Aufgaben</h2>

            <button class="button create" onclick="showTaskModal('add')">Neue Aufgabe anlegen</button>

            <form id="filterForm" action="tasks" method="get" class="search-container">
                <input type="text" id="searchInput" name="search" value="<c:out value='${currentSearch}'/>" placeholder="Aufgabe suchen...">
                <select name="status_filter" onchange="this.form.submit()" style="margin-left: 1em;">
                    <option value="">-- Alle Status --</option>
                    <c:forEach var="status" items="${taskStatuses}">
                        <option value="${status.id}" ${currentStatusFilter == status.id ? 'selected' : ''}>
                            <c:out value="${status.name}"/>
                        </option>
                    </c:forEach>
                </select>
            </form>

            
            
            <table>
                <thead>
                    <tr>
                        <th>Aufgabe</th>
                        <th>Abteilung</th>
                        <th>Start</th>
                        <th>Ende</th>
                        <th>Aufwand (PT)</th>
                        <th>Status</th>
                        <th>Fortschritt (%)</th>
                        <th>Aktionen</th>
                    </tr>
                </thead>
                <tbody>
                    <c:forEach var="task" items="${tasks}">
                        <tr>
                            <td><c:out value="${task.name}"/></td>
                            <td><c:out value="${task.abteilung}"/></td>
                            <td><fmt:formatDate value="${task.start_date}" type="date" pattern="dd.MM.yyyy"/></td>
                            <td><fmt:formatDate value="${task.end_date}" type="date" pattern="dd.MM.yyyy"/></td>
                            <td><c:out value="${task.effort_days}"/></td>
                            <td>
                                <c:if test="${not empty task.status_name}">
                                    <span style="background-color: ${not empty task.status_color ? task.status_color : '#FFFFFF'}; padding: 3px 10px; border-radius: 999px; border: 1px solid #ccc; font-size: 0.9em;">
                                        <c:out value="${task.status_name}"/>
                                    </span>
                                </c:if>
                            </td>
                            <td>
                                <div style="display: flex; align-items: center; gap: 8px;">
                                    <div style="width: 100px; background-color: #e9ecef; border: 1px solid #ccc; border-radius: 5px; overflow: hidden;">
                                        <div style="width: ${task.progress_percent}%; background-color: #28a745; height: 18px;"></div>
                                    </div>
                                    <span><c:out value="${task.progress_percent}"/>%</span>
                                </div>
                            </td>
                            <td>
                                <button class="button small" onclick="showTaskModal('edit', this)"
                                    data-id="${task.id}" data-name="${task.name}"
                                    data-start-date="${task.start_date}" data-end-date="${task.end_date}"
                                    data-effort-days="${task.effort_days}" data-status-id="${task.status_id}"
                                    data-progress-percent="${task.progress_percent}"
                                    data-abteilung="${task.abteilung}">
                                    Bearbeiten
                                </button>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </div>
    </main>
</div>

<div id="taskModal" class="modal-overlay" style="display:none;">
    <div class="modal-content">
        <h3 id="taskModalTitle"></h3>
        <form id="taskForm" method="post" action="tasks">
            <input type="hidden" name="action" id="taskAction"/>
            <input type="hidden" name="id" id="taskId"/>
            <div><label>Name:</label><input type="text" name="name" id="taskName" required/></div>
            <div>
                <label>Abteilung:</label>
                <c:choose>
                    <c:when test="${sessionScope.user.see_all_users}">
                        <input type="text" name="abteilung" id="taskAbteilung" />
                    </c:when>
                    <c:otherwise>
                        <input type="text" name="abteilung" id="taskAbteilung" value="<c:out value='${sessionScope.user.abteilung}'/>" readonly />
                    </c:otherwise>
                </c:choose>
            </div>
            <div style="display: flex; gap: 1.5em;">
                <div><label>Start-Datum:</label><input type="date" name="start_date" id="taskStartDate"/></div>
                <div><label>Ende-Datum:</label><input type="date" name="end_date" id="taskEndDate"/></div>
            </div>
            <div><label>Aufwand (PT):</label><input type="number" step="0.1" name="effort_days" id="taskEffort" value="0" required/></div>
            <div style="display: flex; gap: 1.5em;">
                <div><label>Fortschritt (%):</label><input type="number" name="progress_percent" id="taskProgress" value="0" min="0" max="100" required/></div>
                <div>
                    <label>Status:</label>
                    <select name="status_id" id="taskStatus" required>
                        <c:forEach var="status" items="${taskStatuses}">
                            <option value="${status.id}">${status.name}</option>
                        </c:forEach>
                    </select>
                </div>
            </div>
            <div class="assigned-users-section">
                <h4>Zugewiesene Benutzer</h4>
                <div id="assignedUsersContainer">
                    <!-- Hier werden die zugewiesenen Benutzer dynamisch eingefügt -->
                </div>
                <button type="button" class="button" onclick="showAssignUserModal()">Benutzer zuweisen</button>
            </div>
            <div class="modal-buttons">
                <button type="submit" class="button create">Speichern</button>
                <button type="button" class="button delete" onclick="hideTaskModal()">Abbrechen</button>
            </div>
        </form>
    </div>
</div>

<script>
    const searchInput = document.getElementById('searchInput');
    const filterForm = document.getElementById('filterForm');
    let debounceTimer;

    searchInput.addEventListener('keyup', () => {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            filterForm.submit();
        }, 500);
    });

    function showTaskModal(mode, btn) {
        const form = document.getElementById('taskForm');
        form.reset();
        
        const abteilungInput = document.getElementById('taskAbteilung');
        const userCanSeeAll = ${sessionScope.user.can_manage_users};

        if (mode === 'add') {
            document.getElementById('taskModalTitle').textContent = 'Neue Aufgabe';
            document.getElementById('taskAction').value = 'add';
            if (!userCanSeeAll) {
                abteilungInput.value = "${sessionScope.user.abteilung}";
            }
            // Zugewiesene Benutzer zurücksetzen
            loadAssignedUsers(null);
        } else {
            document.getElementById('taskModalTitle').textContent = 'Aufgabe bearbeiten';
            document.getElementById('taskAction').value = 'edit';
            const taskId = btn.dataset.id;
            document.getElementById('taskId').value = taskId;
            document.getElementById('taskName').value = btn.dataset.name;
            document.getElementById('taskStartDate').value = btn.dataset.startDate;
            document.getElementById('taskEndDate').value = btn.dataset.endDate;
            document.getElementById('taskEffort').value = btn.dataset.effortDays;
            document.getElementById('taskStatus').value = btn.dataset.statusId;
            document.getElementById('taskProgress').value = btn.dataset.progressPercent;
            abteilungInput.value = btn.dataset.abteilung;
            
            // Zugewiesene Benutzer laden
            loadAssignedUsers(taskId);
        }
        document.getElementById('taskModal').style.display = 'flex';
    }
    
    function hideTaskModal() {
        document.getElementById('taskModal').style.display = 'none';
    }

    // Globales Array für zugewiesene Benutzer
    let assignedUsers = [];

    function showAssignUserModal() {
        // AJAX-Aufruf um verfügbare Benutzer zu laden
        fetch('tasks?action=getAvailableUsers&abteilung=' + encodeURIComponent(document.getElementById('taskAbteilung').value))
            .then(response => response.json())
            .then(users => {
                const modal = document.createElement('div');
                modal.className = 'modal-overlay';
                modal.id = 'assignUserModal';
                modal.style.display = 'flex';
                
                const content = `
                    <div class="modal-content">
                        <h3>Benutzer zuweisen</h3>
                        <div>
                            <label>Benutzer:</label>
                            <select id="userSelect">
                                <c:forEach var="user" items="${users}">
                                    <option value="${user.id}"><c:out value="${user.name}, ${user.vorname}"/></option>
                                </c:forEach>
                            </select>
                        </div>
                        <div>
                            <label>Aufwand (PT):</label>
                            <input type="number" id="userEffort" step="0.1" min="0" value="0" />
                        </div>
                        <div class="modal-buttons">
                            <button type="button" class="button create" onclick="assignUser()">Zuweisen</button>
                            <button type="button" class="button delete" onclick="hideAssignUserModal()">Abbrechen</button>
                        </div>
                    </div>
                `;
                
                modal.innerHTML = content;
                document.body.appendChild(modal);
            });
    }

    function hideAssignUserModal() {
        const modal = document.getElementById('assignUserModal');
        if (modal) {
            modal.remove();
        }
    }

    function assignUser() {
        const select = document.getElementById('userSelect');
        const effort = document.getElementById('userEffort').value;
        const userId = select.value;
        const userName = select.options[select.selectedIndex].text;
        
        // Benutzer zum Array hinzufügen
        assignedUsers.push({
            userId: userId,
            name: userName,
            effort: effort
        });
        
        // Benutzer-Container aktualisieren
        updateAssignedUsersDisplay();
        
        // Modal schließen
        hideAssignUserModal();
    }

    function updateAssignedUsersDisplay() {
        const container = document.getElementById('assignedUsersContainer');
        container.innerHTML = '';
        
        assignedUsers.forEach(user => {
            const div = document.createElement('div');
            div.className = 'assigned-user';
            
            const span = document.createElement('span');
            span.textContent = user.name;
            div.appendChild(span);
            
            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'button small delete';
            button.onclick = () => removeAssignedUser(user.id || user.userId);
            button.textContent = 'Entfernen';
            div.appendChild(button);
            
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'assigned_user_ids[]';
            input.value = user.id || user.userId;
            div.appendChild(input);
            
            container.appendChild(div);
        });
    }

    // Event-Listener für das Formular
    document.getElementById('taskForm').addEventListener('submit', async function(e) {
        e.preventDefault();
        
        // Erst das Task speichern/aktualisieren
        const formData = new FormData(this);
        await fetch('tasks', {
            method: 'POST',
            body: formData
        });

        // Dann die Benutzerzuweisungen speichern
        const taskId = formData.get('id') || (await getLastInsertedTaskId());
        const userIds = assignedUsers.map(user => user.id || user.userId);
        
        await fetch('tasks', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
                'action': 'saveAssignments',
                'taskId': taskId,
                'userIds[]': userIds
            })
        });

        // Seite neu laden
        window.location.reload();
    });

    function removeAssignedUser(userId) {
        assignedUsers = assignedUsers.filter(user => user.userId !== userId);
        updateAssignedUsersDisplay();
    }

    function loadAssignedUsers(taskId) {
        if (taskId) {
            fetch('tasks?action=getAssignedUsers&taskId=' + taskId)
                .then(response => response.json())
                .then(users => {
                    assignedUsers = users;
                    updateAssignedUsersDisplay();
                });
        } else {
            assignedUsers = [];
            updateAssignedUsersDisplay();
        }
    }
    
    async function getLastInsertedTaskId() {
        const response = await fetch('tasks?action=getLastInsertedTaskId');
        const data = await response.json();
        return data.taskId;
    }
</script>
<style>
    .assigned-users-section {
        margin-top: 1.5em;
        border-top: 1px solid #ddd;
        padding-top: 1em;
    }
    .assigned-user {
        display: flex;
        align-items: center;
        gap: 1em;
        margin: 0.5em 0;
        padding: 0.5em;
        background: #f5f5f5;
        border-radius: 4px;
    }
    .assigned-user span {
        flex-grow: 1;
    }
</style>
</body>
</html>