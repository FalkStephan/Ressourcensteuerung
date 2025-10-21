<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="${task.id != null ? 'Aufgabe bearbeiten' : 'Neue Aufgabe'}" scope="request"/>
    <jsp:include page="/WEB-INF/_header.jsp"/>
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
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1.5em;
            margin-bottom: 1.5em;
        }
        .form-grid > div {
            margin-bottom: 1em;
        }
        .form-grid label {
            display: block;
            margin-bottom: 0.5em;
        }
        .form-grid input,
        .form-grid select {
            width: 100%;
        }
        .full-width {
            grid-column: 1 / -1;
        }
        .assigned-user input[type="number"] {
            width: 80px;
            margin: 0 1em;
            padding: 0.25em;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .assigned-user input[type="number"]:focus {
            border-color: #007bff;
            outline: none;
        }
    </style>
</head>
<body>
<div class="layout-wrapper">
    <jsp:include page="/WEB-INF/_nav.jsp"/>
    <main>
        <div class="container">
            <h2>${task.id != null ? 'Aufgabe bearbeiten' : 'Neue Aufgabe'}</h2>
            
            <form id="taskForm" method="post" action="tasks">
                <input type="hidden" name="action" value="${task.id != null ? 'edit' : 'add'}"/>
                <c:if test="${task.id != null}">
                    <input type="hidden" name="id" value="${task.id}"/>
                </c:if>
                
                <div class="form-grid">
                    <div class="full-width">
                        <label for="taskName">Name:</label>
                        <input type="text" name="name" id="taskName" value="${task.name}" required/>
                    </div>
                    
                    <div>
                        <label for="taskAbteilung">Abteilung:</label>
                        <c:choose>
                            <c:when test="${sessionScope.user.see_all_users}">
                                <input type="text" name="abteilung" id="taskAbteilung" value="${task.abteilung}" />
                            </c:when>
                            <c:otherwise>
                                <input type="text" name="abteilung" id="taskAbteilung" value="${sessionScope.user.abteilung}" readonly />
                            </c:otherwise>
                        </c:choose>
                    </div>
                    
                    <div>
                        <label for="taskStatus">Status:</label>
                        <select name="status_id" id="taskStatus" required>
                            <c:forEach var="status" items="${taskStatuses}">
                                <option value="${status.id}" ${task.status_id == status.id ? 'selected' : ''}>
                                    ${status.name}
                                </option>
                            </c:forEach>
                        </select>
                    </div>
                    
                    <div>
                        <label for="taskStartDate">Start-Datum:</label>
                        <input type="date" name="start_date" id="taskStartDate" value="${task.start_date}"/>
                    </div>
                    
                    <div>
                        <label for="taskEndDate">Ende-Datum:</label>
                        <input type="date" name="end_date" id="taskEndDate" value="${task.end_date}"/>
                    </div>
                    
                    <div>
                        <label for="taskEffort">Aufwand (PT):</label>
                        <input type="number" step="1" name="effort_days" id="taskEffort" value="${task.effort_days}" required/>
                    </div>
                    
                    <div>
                        <label for="taskProgress">Fortschritt (%):</label>
                        <input type="number" name="progress_percent" id="taskProgress" value="${task.progress_percent}" min="0" max="100" required/>
                    </div>

                    <div>
                        <label for="task_options">Verfügbarkeits-Option</label>
                        <select id="task_options" name="task_options" class="form-control">
                            <option value="waiting" ${task.task_options == 'waiting' ? 'selected' : ''}>
                                Aufgabe wartet auf Verfügbarkeit
                            </option>
                            <option value="continue" ${task.task_options == 'continue' ? 'selected' : ''}>
                                Aufgabe fällt auch an, wenn keine Verfügbarkeit vorhanden
                            </option>
                        </select>
                    </div>

                    <div>
                        <label for="description">Beschreibung:</label>
                        <textarea id="description" name="description" class="form-control" rows="3" style="resize: vertical; width: 100%;"><c:out value="${task.description}"/></textarea>
                    </div>
                </div>
                
                <div class="assigned-users-section">
                    <h3>Zugewiesene Benutzer</h3>
                    <div id="assignedUsersContainer">
                        <!-- Wird dynamisch befüllt -->
                    </div>
                    <div style="margin-top: 1em;">
                        <button type="button" class="button" onclick="showUserSelectDialog()">Benutzer hinzufügen</button>
                    </div>
                </div>
                
                <div style="margin-top: 2em;">
                    <button type="submit" class="button create">Speichern</button>
                    <a href="tasks" class="button delete">Abbrechen</a>
                </div>
            </form>
        </div>
    </main>
</div>

<dialog id="userSelectDialog">
    <h3>Benutzer auswählen</h3>
    <div style="margin: 1em 0;">
        <select id="userSelect">
            <c:forEach var="user" items="${availableUsers}">
                <option value="${user.id}">${user.name}, ${user.vorname} (${user.abteilung})</option>
            </c:forEach>
        </select>
    </div>
    <div class="dialog-buttons">
        <button class="button create" onclick="assignSelectedUser()">Hinzufügen</button>
        <button class="button delete" onclick="closeUserSelectDialog()">Abbrechen</button>
    </div>
</dialog>

<script>
    let assignedUsers = [];

    // Beim Laden der Seite
    document.addEventListener('DOMContentLoaded', function() {
        // Wenn eine Task-ID vorhanden ist, lade die zugewiesenen Benutzer
        const taskId = document.querySelector('input[name="id"]')?.value;
        // console.log('Aufruf der Seite.....');
        if (taskId) {
            // console.log('TaskId laden: ', taskId);
            loadAssignedUsers(taskId);
        }
        else {
            // console.log('neue TaskId!');
            // 1. Fortschritt auf 0 setzen
            const progressInput = document.getElementById('taskProgress');
            if (progressInput) {
                progressInput.value = 0;
            }

            // 1. Aufwand auf 0 setzen
            const effortInput = document.getElementById('taskEffort');
            if (effortInput) {
                effortInput.value = 0;
            }

            // 2. Start-Datum auf das heutige Datum setzen
            const startDateInput = document.getElementById('taskStartDate');
            if (startDateInput) {
                const today = new Date();
                // Formatiert das Datum in 'YYYY-MM-DD' für das <input type="date">-Feld
                const formattedDate = today.getFullYear() + '-' + ('0' + (today.getMonth() + 1)).slice(-2) + '-' + ('0' + today.getDate()).slice(-2);
                startDateInput.value = formattedDate;
            }
        }
        
        // Form Submit Handler ersetzen
        document.getElementById('taskForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            try {
                // FormData erstellen
                const form = this;
                const formData = new URLSearchParams(new FormData(form));
                
                // Debug-Ausgabe
                console.log('Sende Task-Daten:', Object.fromEntries(formData));
                
                // Task speichern
                const response = await fetch('tasks', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'Accept': 'application/json'
                    },
                    body: formData.toString()
                });
                
                const responseText = await response.text();
                console.log('Server-Antwort (Text):', responseText);
                // const taskId = formData.get('id') || (await getLastInsertedTaskId());
                // console.log('Task-ID nach dem Speichern:', taskId);
                
                let jsonResponse;
                try {
                    jsonResponse = JSON.parse(responseText);
                } catch (e) {
                    console.error('Fehler beim JSON-Parsen:', e);
                    throw new Error('Ungültige Server-Antwort');
                }
                
                if (!response.ok) {
                    throw new Error('Fehler beim Speichern der Aufgabe: ' + 
                                (jsonResponse.error || responseText));
                }
                
                // Task-ID ermitteln
                if (taskId) {
                    console.log('Vorhandene Task-ID: ', taskId);
                } else {
                    let taskId = document.querySelector('input[name="id"]')?.value;
                    console.log('Neue Task-ID aus Antwort_1: ', jsonResponse.taskId);
                    console.log('Neue Task-ID aus Antwort_2: ', taskId);
                }



                
                
                
                if (!taskId && jsonResponse.taskId) {
                    taskId = jsonResponse.taskId;
                }
                console.log('Task-ID: ', taskId);
                
                if (!taskId) {
                    throw new Error('Keine Task-ID verfügbar');
                }
                
                // Benutzerzuweisungen speichern
                // console.log('User: ', assignedUsers);
                if (assignedUsers.length > 0) {
                    const assignments = new URLSearchParams();
                    assignments.append('action', 'saveAssignments');
                    assignments.append('taskId', taskId);
                    assignments.append('count', assignedUsers.length.toString());
                    
                    // Korrekte Indizierung für jeden Benutzer
                    assignedUsers.forEach((user, index) => {
                        assignments.append(`userId_${index}`, user.id.toString());
                        assignments.append(`effortDays_${index}`, user.effort_days.toString());
                    });
                    
                    console.log('Sende Zuweisungen:', Object.fromEntries(assignments));
                    
                    const assignmentResponse = await fetch('tasks', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded'
                        },
                        body: assignments.toString()
                    });
                    
                    const assignmentText = await assignmentResponse.text();
                    console.log('Server-Antwort für Zuweisungen:', assignmentText);
                }
                
                // Erfolgreiche Speicherung
                window.location.href = 'tasks';
                
            } catch (error) {
                console.error('Fehler beim Speichern:', error);
                alert(error.message);
            }
        });
    });

    async function loadUserDetails(userId) {
        try {
            if (!userId || userId === 'undefined' || userId === 'null' || userId === '') {
                throw new Error('Keine Benutzer-ID angegeben');
            }
            
            const userIdStr = userId.toString().trim();
            
            if (!/^\d+$/.test(userIdStr)) {
                throw new Error('Ungültige Benutzer-ID: ' + userIdStr);
            }
            
            console.log('Lade Details für Benutzer:', userIdStr);
            
            const response = await fetch('tasks?action=getUserDetails&userId=' + userIdStr);
            
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.error || 'Fehler beim Laden der Benutzerdaten');
            }
            
            const data = await response.json();
            
            if (!data || typeof data !== 'object' || !data.id) {
                throw new Error('Ungültige Benutzerdaten empfangen');
            }
            
            return {
                id: data.id,
                name: data.name || 'N/A',
                vorname: data.vorname || '',
                abteilung: data.abteilung || ''
            };
            
        } catch (error) {
            console.error('Fehler in loadUserDetails:', error);
            throw error;
        }
    }

    async function loadAssignedUsers(taskId) {
        if (!taskId) {
            console.error('Keine Task-ID angegeben');
            return;
        }
        try {
            const response = await fetch('tasks?action=getAssignedUsers&taskId=' + taskId);
            if (!response.ok) {
                throw new Error('Fehler beim Laden der zugewiesenen Benutzer');
            }
            const users = await response.json();
            
            if (!Array.isArray(users)) {
                throw new Error('Ungültiges Datenformat für zugewiesene Benutzer');
            }
            console.log('User:', users);


            assignedUsers = users.map(user => ({
                id: user.user_id,
                name: user.name || 'N/A',
                vorname: user.vorname || '',
                abteilung: user.abteilung || '',
                effort_days: user.effort_days || 0
            }));
            
            // console.log('Geladene Zuweisungen:', assignedUsers);
            updateAssignedUsersDisplay();
            
            
        } catch (error) {
            console.error('Fehler beim Laden der zugewiesenen Benutzer:', error);
            alert('Fehler beim Laden der zugewiesenen Benutzer: ' + error.message);
        }
    }

    function showUserSelectDialog() {
        document.getElementById('userSelectDialog').showModal();
    }

    function closeUserSelectDialog() {
        document.getElementById('userSelectDialog').close();
    }

    async function assignSelectedUser() {
        try {
            const select = document.getElementById('userSelect');
            const userId = select.value;

            
            if (!userId) {
                throw new Error('Bitte wählen Sie einen Benutzer aus');
            }
            // Prüfen ob der Benutzer bereits zugewiesen ist
            // console.log ('Prüfung1: ', userId);
            // console.log ('Prüfung2: ', assignedUsers);
            if (assignedUsers.some(u => u.id.toString() === userId.toString())) {
            // if (assignedUsers.some(u => u.id === userId)) {
                alert('Dieser Benutzer ist bereits zugewiesen');
                closeUserSelectDialog();
                return;
            }
            
            
            // Füge den neuen Benutzer zur bestehenden Liste hinzu
            const selectedOption = select.options[select.selectedIndex];
            const [name, vorname] = selectedOption.text.split(', ');
            const abteilung = selectedOption.text.match(/\((.*?)\)/)?.[1] || '';
            
            assignedUsers.push({
                id: userId,
                name: name,
                vorname: vorname.replace(/ \(.*\)$/, ''), // Entferne die Abteilung aus dem Vornamen
                abteilung: abteilung,
                effort_days: 0
            });
            
            updateAssignedUsersDisplay();
            closeUserSelectDialog();
            
        } catch (error) {
            console.error('Fehler beim Zuweisen des Benutzers:', error);
            alert(error.message);
        }
    }

    function removeAssignedUser(userId) {
        assignedUsers = assignedUsers.filter(user => user.id != userId);
        updateAssignedUsersDisplay();
    }

    function updateAssignedUsersDisplay() {
        const container = document.getElementById('assignedUsersContainer');
        container.innerHTML = '';
        
        if (assignedUsers.length === 0) {
            container.innerHTML = '<p>Keine Benutzer zugewiesen</p>';
            return;
        }
        
        assignedUsers.forEach(user => {
            const div = document.createElement('div');
            div.className = 'assigned-user';
            
            const span = document.createElement('span');
            
            // Anzeige der Benutzerdaten
            // console.log('Zuweisung:', user.name + ', ' + user.vorname + ' (' + user.abteilung + ') -->' + user.effort_days);
            //if (user.vorname && user.abteilung) {
            //    span.textContent = `${user.name}, ${user.vorname} (${user.abteilung})`;
            // } else {
            //     span.textContent = user.name;
            //}
            span.textContent = user.name + ', ' + user.vorname + ' (' + user.abteilung + ')';
            div.appendChild(span);
            
            // Aufwand Input-Feld
            const effortInput = document.createElement('input');
            effortInput.type = 'number';
            effortInput.step = '0.5';
            effortInput.min = '0';
            effortInput.value = user.effort_days || 0;
            effortInput.style.width = '80px';
            effortInput.onchange = (e) => {
                user.effort_days = parseFloat(e.target.value) || 0;
            };
            div.appendChild(effortInput);
            
            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'button small delete';
            button.onclick = () => removeAssignedUser(user.id);
            button.textContent = 'Benutzer Entfernen';
            div.appendChild(button);
            
            container.appendChild(div);
        });
    }
</script>

</body>
</html>
