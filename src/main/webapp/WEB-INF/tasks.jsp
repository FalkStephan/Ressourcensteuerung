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

            <a href="tasks?action=edit" class="button create">Neue Aufgabe anlegen</a>

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
                <div class="filter-group">
                    <label>
                        <input type="checkbox" id="showAssignments" onchange="updateTaskList()">
                        Zuweisungen anzeigen
                    </label>
                </div>
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
                        <tr class="task-item" data-task-id="${task.id}">
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
                                <a href="tasks?action=edit&id=${task.id}" class="button small">Bearbeiten</a>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </div>
    </main>
</div>

<script>
    const searchInput = document.getElementById('searchInput');
    const filterForm = document.getElementById('filterForm');
    let debounceTimer;
    let taskAssignments = new Map();
    let originalValues = new Map(); // Map für ursprüngliche Werte
    let assignedUsers = []; // Globales Array für zugewiesene Benutzer

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

    async function loadTaskAssignments(taskId) {
        try {
            if (!taskId) {
                console.error('Keine gültige Task-ID:', taskId);
                return [];
            }

            console.log('Lade Zuweisungen für Task:', taskId);
            const response = await fetch('tasks?action=getAssignedUsers&taskId=' + encodeURIComponent(taskId));
            
            if (!response.ok) {
                throw new Error('Fehler beim Laden der Zuweisungen');
            }
            
            const assignments = await response.json();
            console.log('Geladene Zuweisungen:', assignments);
            return assignments;
        } catch (error) {
            console.error('Fehler beim Laden der Zuweisungen:', error);
            return [];
        }
    }

    // Funktion zum Speichern der ursprünglichen Werte
    async function saveOriginalValues() {
        console.log('Alte Werte speichern');
        const taskElements = document.querySelectorAll('.task-item');
        console.log('. Taskelement:', teaskelements);
        taskElements.forEach(taskElement => {
            const taskId = taskElement.getAttribute('data-task-id');
            originalValues.set(taskId, {
                name: taskElement.querySelector('td:nth-child(1)').innerHTML,
                abteilung: taskElement.querySelector('td:nth-child(2)').innerHTML,
                start: taskElement.querySelector('td:nth-child(3)').innerHTML,
                end: taskElement.querySelector('td:nth-child(4)').innerHTML,
                effort: taskElement.querySelector('td:nth-child(5)').innerHTML
            });
        });
    }

    async function updateTaskList() {
        const showAssignments = document.getElementById('showAssignments').checked;
        const taskElements = document.querySelectorAll('.task-item');

        // Zuerst alle alten Zuweisungszeilen entfernen
        document.querySelectorAll('.task-assignment-row').forEach(row => row.remove());

        if (showAssignments) {
            for (const taskElement of taskElements) {
                const taskId = taskElement.getAttribute('data-task-id');
                if (taskId) {
                    try {
                        const assignments = await loadTaskAssignments(taskId);
                        if (assignments && assignments.length > 0) {
                            let lastElement = taskElement;
                            assignments.forEach(assignment => {
                                const newRow = document.createElement('tr');
                                newRow.className = 'task-assignment-row'; // Eine Klasse zum einfachen Finden und Entfernen

                                // HTML für die neue Zeile mit den Zuweisungsdaten in den richtigen Spalten
                                newRow.innerHTML = `
                                    <td></td> <td><div class="assignment-value">${assignment.abteilung || ''}</div></td>
                                    <td><div class="assignment-value">${assignment.name || ''}</div></td>
                                    <td><div class="assignment-value">${assignment.vorname || ''}</div></td>
                                    <td><div class="assignment-value">${assignment.effort_days || ''}</div></td>
                                    <td></td> <td></td> <td></td> `;

                                // Füge die neue Zeile nach dem Task-Element oder der letzten Zuweisungszeile ein
                                lastElement.parentNode.insertBefore(newRow, lastElement.nextSibling);
                                lastElement = newRow; // Aktualisiere das letzte Element für die nächste Iteration
                            });
                        }
                    } catch (error) {
                        console.error('Fehler beim Laden der Zuweisungen für Task', taskId, ':', error);
                        const errorRow = document.createElement('tr');
                        errorRow.className = 'task-assignment-row';
                        errorRow.innerHTML = `<td colspan="8"><div class="task-assignment error">Fehler beim Laden der Zuweisungen</div></td>`;
                        taskElement.parentNode.insertBefore(errorRow, taskElement.nextSibling);
                    }
                }
            }
        }
    }
    



    // Initialisierung
    document.addEventListener('DOMContentLoaded', function() {
        saveOriginalValues(); // Speichere ursprüngliche Werte beim Laden
        updateTaskList();
    });
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

    .task-assignments {
        margin-top: 0.5em;
        font-size: 0.9em;
        color: #666;
    }

    .task-assignment {
        display: block;
        margin: 0.2em 0;
        padding-left: 1em;
        border-left: 2px solid #e0e0e0;
    }

    .task-assignment .effort {
        font-weight: bold;
        color: #444;
    }

    .task-assignment.error {
        color: #dc3545;
    }

    .assignment-value {
        padding: 2px 0;
        border-bottom: 1px solid #eee;

    }

    .assignment-value:last-child {
        border-bottom: none;
    }

    td .assignment-value {
        font-size: 0.9em;
        color: #666;
        margin: 0 auto;
    }

    td .assignment-value:hover {
        background-color: #f8f9fa;
    }
</style>
</body>
</html>