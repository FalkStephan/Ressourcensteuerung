<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="de">
<head>
    <c:set var="title" value="Kalender" scope="request"/>
    <jsp:include page="/WEB-INF/_header.jsp"/>
    <style>
        .calendar-container {
            overflow-x: auto;
            margin-top: 1em;
        }
        .calendar-grid {
            border-collapse: collapse;
            min-width: 100%;
        }
        .calendar-grid th, .calendar-grid td {
            border: 1px solid #ddd;
            padding: 4px;
            text-align: center;
            min-width: 30px;
        }
        .calendar-grid th {
            background-color: #f5f5f5;
            position: sticky;
            top: 0;
            z-index: 1;
        }
        /* Farben werden dynamisch per JavaScript gesetzt*/
        .calendar-grid td.weekend,
        .calendar-grid td.holiday,
        .calendar-grid td.workday,
        
        
        
        .calendar-grid td.absence {
            transition: background-color 0.3s ease;
        }
        .calendar-controls {
            margin-bottom: 1em;
            display: flex;
            gap: 1em;
            align-items: center;
        }
        .employee-name {
            position: sticky;
            left: 0;
            background: white;
            z-index: 2;
            font-weight: bold;
            border-right: 2px solid #ddd;
            padding-left: 10px !important;
            text-align: left !important;
        }
        .department-header {
            background-color: #f0f0f0;
            font-weight: bold;
            text-align: left !important;
            padding-left: 5px !important;
        }
        .department-header td {
            border-top: 2px solid #999 !important;
            border-bottom: 2px solid #999 !important;
            text-align: left !important;
        }
    </style>
</head>
<body>
    <div class="layout-wrapper">
        <jsp:include page="/WEB-INF/_nav.jsp"/>
        <main>
            <div class="container">
                <h2>Kalenderübersicht</h2>
                
                <div class="calendar-controls">
                    <button onclick="changeMonth(-1)" class="button">&lt; Vorheriger Monat</button>
                    <span id="currentMonth"></span>
                    <button onclick="changeMonth(1)" class="button">Nächster Monat &gt;</button>
                </div>

                <div class="calendar-container">
                    <table class="calendar-grid" id="calendarGrid">
                        <thead>
                            <tr>
                                <th class="employee-name">Mitarbeiter</th>
                                <!-- Tage werden per JavaScript eingefügt -->
                            </tr>
                        </thead>
                        <tbody>
                            <!-- Mitarbeiter und Tage werden per JavaScript eingefügt -->
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>

    <script>
        let currentDate = new Date();
        
        function updateCalendarColors(colors) {
            // Debug-Ausgabe der Farben
            console.log('Erhaltene Farben:', colors);
            
            // Farben für verschiedene Zelltypen
            const colorMap = {
                'weekend': colors.calendar_color_weekend,
                'holiday': colors.calendar_color_holiday,
                'workday': colors.calendar_color_workday,
                'absence': colors.calendar_color_absence
            };
            
            // Farben auf alle TD-Elemente anwenden, außer der Namensspalte
            document.querySelectorAll('.calendar-grid td:not(.employee-name):not(.department-header td)').forEach(td => {
                for (const [className, color] of Object.entries(colorMap)) {
                    if (td.classList.contains(className)) {
                        td.style.backgroundColor = color;
                        break;  // Beende die Schleife, sobald eine passende Klasse gefunden wurde
                    }
                }
            });
        }

        function updateCalendar() {
            fetch('${pageContext.request.contextPath}/calendar-overview/data?' + new URLSearchParams({
                year: currentDate.getFullYear(),
                month: currentDate.getMonth() + 1
            }))
            .then(response => {
                console.log('Response Status:', response.status);
                return response.json();
            })
            .then(data => {
                // Debug-Ausgabe der gesamten Daten
                console.log('Erhaltene Daten:', data);
                
                const monthNames = ["Januar", "Februar", "März", "April", "Mai", "Juni",
                                  "Juli", "August", "September", "Oktober", "November", "Dezember"];
                
                // Aktualisiere Monatsanzeige
                document.getElementById('currentMonth').textContent = 
                    monthNames[currentDate.getMonth()] + ' ' + currentDate.getFullYear();
                
                // Erstelle Tabellenkopf mit Tagen
                const headerRow = document.querySelector('#calendarGrid thead tr');
                headerRow.innerHTML = '<th class="employee-name">Mitarbeiter</th>';
                
                data.days.forEach(day => {
                    const th = document.createElement('th');
                    th.textContent = day.dayOfMonth;
                    if (day.isWeekend) th.classList.add('weekend');
                    headerRow.appendChild(th);
                });
                
                // Erstelle Tabellenzeilen für Mitarbeiter, gruppiert nach Abteilungen
                const tbody = document.querySelector('#calendarGrid tbody');
                tbody.innerHTML = '';
                
                Object.entries(data.departments).forEach(([department, employees]) => {
                    // Abteilungsheader
                    const headerRow = document.createElement('tr');
                    headerRow.classList.add('department-header');
                    const headerCell = document.createElement('td');
                    headerCell.textContent = department;
                    headerCell.colSpan = data.days.length + 1; // +1 für die Namensspalte
                    headerRow.appendChild(headerCell);
                    tbody.appendChild(headerRow);
                    
                    // Mitarbeiter der Abteilung
                    employees.forEach(employee => {
                        const tr = document.createElement('tr');
                        const nameCell = document.createElement('td');
                        nameCell.textContent = employee.name;
                        nameCell.classList.add('employee-name');
                        tr.appendChild(nameCell);
                        
                        data.days.forEach(day => {
                            const td = document.createElement('td');
                            if (day.isWeekend) {
                                td.classList.add('weekend');
                            } else if (day.isHoliday) {
                                td.classList.add('holiday');
                                td.title = day.holidayName;
                            } else if (employee.absences.includes(day.date)) {
                                td.classList.add('absence');
                            } else {
                                td.classList.add('workday');
                            }
                            tr.appendChild(td);
                        });
                        
                        tbody.appendChild(tr);
                    });
                });
                
                // Farben aktualisieren nachdem alle Zellen erstellt wurden
                if (data.colors) {
                    updateCalendarColors(data.colors);
                }
            });
        }
        
        function changeMonth(delta) {
            currentDate.setMonth(currentDate.getMonth() + delta);
            updateCalendar();
        }
        
        // Initial update
        updateCalendar();
    </script>
</body>
</html>
