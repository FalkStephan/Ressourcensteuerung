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

        .view-options {
            display: flex;
            gap: 1.5em; /* Abstand zwischen den Checkboxen */
            margin-bottom: 1em; /* Abstand nach unten */
            flex-wrap: wrap; /* Sorgt für Umbruch auf kleineren Bildschirmen */
        }


        .detail-row {
            padding: 2px 8px; /* Reduziert den vertikalen und horizontalen Abstand in der Zelle */
            line-height: 1.2; /* Verringert den Zeilenabstand */     
            font-size: 0.85em; /* Macht die Schrift etwas kleiner */
            color: #333;      /* Etwas dunklere Schrift für bessere Lesbarkeit */     
        }
      
        .detail-row .highlight {
            background-color: #dbd000; /* Ein leichtes Türkis als Hintergrund */
            /* font-weight: bold; */
            color: #8a8300;
        }

        /* Macht die Aufgaben-Zeile klickbar */
        .detail-row.expandable {
            cursor: pointer;
        }
        .detail-row.expandable:hover {
            background-color: #f0e6c8;
        }

        .detail-row-label {
            font-style: italic;
            font-weight: normal !important; /* WICHTIG: Überschreibt die fette Schrift */
            text-align: right !important;
            padding-right: 10px !important;
        }




        /* Styling für die neuen Detailzeilen */
        .task-detail-row td {
            font-size: 0.75em;
            padding: 1px 4px;
            background-color: #fff;
            border-bottom: 1px dotted #ccc;
        }

        .task-detail-name {
            text-align: right !important;
            padding-right: 15px !important;
            color: #555;
        }

        .summary-row {
            border-top: 2px solid #333; /* Eine dicke Linie zur Abgrenzung */
        }

        .summary-row td {
            font-weight: bold;
            background-color: #e9ecef; /* Ein leichter Grauton */
            padding: 2px 8px; /* Reduziert den vertikalen und horizontalen Abstand in der Zelle */
            line-height: 1.2; /* Verringert den Zeilenabstand */     
            font-size: 0.85em; /* Macht die Schrift etwas kleiner */
            color: #333;      /* Etwas dunklere Schrift für bessere Lesbarkeit */    
        }

        .summary-label {
            font-style: italic;
            font-weight: normal;
            font-size: 0.85em; /* Macht die Schrift etwas kleiner */
            text-align: right !important;
            padding-right: 10px !important;
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

                    <div class="view-options">
                        <label><input type="radio" name="view" value="days" checked> Tage/Monat</label>
                        <label><input type="radio" name="view" value="weeks"> Wochen/Halbjahr</label>
                    </div>
                </div>

                <div class="view-options">
                    <label><input type="checkbox" name="view" value="mak"> MAK-Kapazität</label>
                    <label><input type="checkbox" name="view" value="availability"> Verfügbarkeit</label>
                    <label><input type="checkbox" name="view" value="availability_percent"> Verfügbarkeit (Team)</label>
                    <label><input type="checkbox" name="view" value="tasks"> Aufgaben</label>
                    <label><input type="checkbox" name="view" value="workload"> Auslastung</label>
                    <label><input type="checkbox" name="view" value="workload_team"> Auslastung (Team)</label>
                    <label><input type="checkbox" name="view" value="remaining"> Rest-Verfügbarkeit</label>
                    <label><input type="checkbox" name="view" value="remainingTeam"> Rest-Verfügbarkeit (Team)</label>
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
        
        // Event-Listener für alle Checkboxen hinzufügen
        document.querySelectorAll('.view-options input[type="checkbox"]').forEach(checkbox => {
            checkbox.addEventListener('change', updateCalendar);
        });

        // Event-Listener für die Radio-Buttons hinzufügen
        document.querySelectorAll('input[name="view"]').forEach(radio => {
            radio.addEventListener('change', updateCalendar);
        });

        // Event-Listener wird sicher an den Tabellenkörper gehängt
        document.addEventListener('DOMContentLoaded', function() {
            const tableBody = document.querySelector('#calendarGrid tbody');
            if (tableBody) {
                tableBody.addEventListener('click', function(event) {
                    // DEBUG 1: Prüfen, ob der Klick im Tabellenkörper überhaupt registriert wird.
                    // console.log("Klick im Tabellenkörper registriert. Geklicktes Element:", event.target);

                    const expandableRow = event.target.closest('.detail-row.expandable');

                    // DEBUG 2: Prüfen, ob die korrekte klickbare Zeile gefunden wurde.
                    if (expandableRow) {
                        // console.log("Klickbare 'Aufgaben'-Zeile gefunden. Blende Details ein/aus.", expandableRow);
                        toggleTaskDetails(expandableRow);
                    } else {
                        // console.log("Klick war nicht auf einer ausklappbaren 'Aufgaben'-Zeile.");
                    }
                });
            }
            // Initialen Kalender beim ersten Laden der Seite aufbauen
            // updateCalendar();
        });

        function changeMonth(delta) {
            currentDate.setMonth(currentDate.getMonth() + delta);
            updateCalendar();
        }

        function getWeekNumber(d) {
            // Hilfsfunktion zur Berechnung der Kalenderwoche
            d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
            d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay()||7));
            var yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1));
            var weekNo = Math.ceil(( ( (d - yearStart) / 86400000) + 1)/7);
            return weekNo;
        }

        function updateCalendarColors(colors) {
            // Debug-Ausgabe der Farben
            // console.log('Erhaltene Farben:', colors);
            
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

        function getCapacityForDate(capacities, dateString) {
            /**
            * Hilfsfunktion: Findet die gültige Kapazität für ein bestimmtes Datum.
            * Geht davon aus, dass die Kapazitäten absteigend nach Datum sortiert sind.
            * @param {Array} capacities - Die Kapazitätshistorie eines Mitarbeiters.
            * @param {string} dateString - Das Datum des Kalendertages (z.B. "2025-09-10").
            * @returns {number|null} Die Kapazität in Prozent oder null, wenn keine gültig ist.
            */
            // console.log('getCapacityForDate Tag:        ', dateString);
            // console.log('getCapacityForDate capacities: ', capacities);
            // Sicherheitsprüfung für den Fall, dass ungültige Daten übergeben werden
            if (typeof dateString !== 'string' || !dateString || !capacities || capacities.length === 0) {
                return null;
            }

            if (!capacities || capacities.length === 0) {
                // console.log(`Für Datum ${dateString}: Keine Kapazitätsdaten für diesen Mitarbeiter erhalten.`);
                return null;
            }

            // Zerlegt "YYYY-MM-DD" in seine Teile [YYYY, MM, DD]
            const [year, month, day] = dateString.split('-').map(Number);
            // Erstellt das Datum sicher. Monat ist 0-basiert (Januar=0), daher month - 1.
            // Die Uhrzeit wird auf 12:00 gesetzt, um Zeitzonenprobleme am Tageswechsel zu umgehen.
            const currentDay = new Date(year, month - 1, day, 12, 0, 0);

            let activeCapacity = null;


            // console.log(`--- Suche Kapazität für Tag: `, currentDay);
            // console.log(`--- Tag: `, dateString);
            // Da die Liste absteigend sortiert ist, ist der erste passende Eintrag der richtige.
            for (const capacity of capacities) {
                
                // console.log(`----> Schleife: `, capacity.start_date);

                // Nur Einträge verarbeiten, die ein gültiges Datum haben
                if (typeof capacity.start_date === 'string' && capacity.start_date) {
                    const [capYear, capMonth, capDay] = capacity.start_date.split('-').map(Number);
                    const validFromDate = new Date(capYear, capMonth - 1, capDay, 12, 0, 0);
                    const highlight = false;
                    
                    // console.log(`-> validFromDate.......`, validFromDate);
                    // console.log(`----> validFromDate: `, capacity.start_date);
                    // Prüfen, ob das Datum gültig ist und in der Vergangenheit oder am selben Tag liegt
                    if (capacity.start_date <= dateString) {
                    // if (dateString <= capacity.start_date) {
                        // Den korrekten Wert zurückgeben
                        // return capacity.capacity_percent;
                        activeCapacity = {
                            value: capacity.capacity_percent,
                            // Markieren, wenn das Startdatum der Kapazität genau auf den Kalendertag fällt.
                            highlight: dateString === capacity.start_date
                        };
                        
                        // onsole.log(`TREFFER: `, activeCapacity);
                        return activeCapacity;
                    } 
                }


            }
            // console.log(`-> KEIN TREFFER für diesen Tag gefunden.`);
            return null; // Kein gültiger Kapazitätseintrag gefunden
        }
      
        function getAvailabilityForDate(day, employee) {
            /**
            * Berechnet die Verfügbarkeit eines Mitarbeiters für einen bestimmten Tag.
            */
            // Regel 1: Wenn es ein Feiertag ist, ist die Verfügbarkeit 0.
            if (day.isHoliday) {
                return 0;
            }
            // Regel 2: Wenn der Mitarbeiter abwesend ist, ist die Verfügbarkeit 0.
            if (employee.absences && employee.absences.includes(day.date)) {
                return 0;
            }
            // Ansonsten entspricht die Verfügbarkeit der gültigen MAK-Kapazität.
            const capacityInfo = getCapacityForDate(employee.capacities, day.date);
            return capacityInfo ? capacityInfo.value : 0; // Gehe von 0 aus, wenn keine Kapazität definiert ist
        }
       
        function getColorForPercentage(percent) {
            /**
            * NEUE HILFSFUNKTION: Berechnet eine Farbe für einen Prozentwert
            * auf einer Skala von Rot (0%) über Gelb (50%) zu Grün (100%).
            */
            if (typeof percent !== 'number') return ''; // Keine Farbe, wenn der Wert ungültig ist

            // Begrenze den Wert auf den Bereich 0-100
            const p = Math.max(0, Math.min(100, percent));
            // console.log(`Farbinof p: `,p);

            // Wir interpolieren die Farbe im HSL-Farbraum (Farbton, Sättigung, Helligkeit)
            // Farbton (Hue): 0 ist Rot, 120 ist Grün.
            const hue = (p * 1.2).toString(10);
            const hueValue = "hsl(" + hue + ' ' + '90% 70%)';
            // console.log(`Farbinof hue: `,hueValue);
            // Sättigung und Helligkeit können wir konstant halten, um lebendige Farben zu erhalten.
            return hueValue;
        }

        function getWorkloadColor(workload, settings) {
            /**
            * Gibt die passende Farbe für die Auslastung (Workload) zurück,
            * basierend auf den Werten aus den Einstellungen.
            */
            if (typeof workload !== 'number' || workload <= 0) {
                return ''; // Keine Farbe, wenn keine Auslastung vorhanden ist
            }

            // Werte aus den Settings holen und in Zahlen umwandeln
            const mediumThreshold = parseFloat(settings.calendar_workload_value_medium); // z.B. 0.25
            const highThreshold = parseFloat(settings.calendar_workload_value_high);   // z.B. 0.8

            // console.log ('--> WL: ', workload);
            // console.log ('medium: ', mediumThreshold);
            // console.log ('high: ', highThreshold);
            

            if (workload/100 >= highThreshold) {
                return settings.calendar_workload_color_high;
            } else if (workload/100 > mediumThreshold) {
                return settings.calendar_workload_color_medium;
            } else {
                return settings.calendar_workload_color_low;
            }
        }

        function countWorkdays(startDateStr, endDateStr, holidays, absences = []) {
            /**
            * HILFSFUNKTION: Zählt die Arbeitstage zwischen zwei Daten.
            * Schließt Wochenenden und Feiertage aus.
            */
            let count = 0;
            const holidaySet = new Set(holidays.map(h => h.date)); // Für schnellen Zugriff
            const absenceSet = new Set(absences); // Für schnellen Zugriff
            let currentDate = new Date(startDateStr + "T12:00:00");
            const endDate = new Date(endDateStr + "T12:00:00");
            // console.log(' - Zeitraum: ', currentDate + ' bis ' + endDate);
            // console.log(' - Holiday: ', holidaySet);
            // console.log(' - Absence: ', absenceSet);

            while (currentDate <= endDate) {
                const dayOfWeek = currentDate.getDay();
                const dateStr = currentDate.toISOString().split('T')[0];

                if (dayOfWeek > 0 && dayOfWeek < 6 && !holidaySet.has(dateStr) && !absenceSet.has(dateStr)) {
                    count++;
                }
                currentDate.setDate(currentDate.getDate() + 1);
            }
            // console.log(' - Dauer: ', count);
            return count > 0 ? count : 1; // Division durch Null vermeiden
        }
        
        function getTaskEffortForDate(day, employee, holidays) {
            /**
            * FUNKTION: Berechnet die tägliche Aufgabenlast für einen Mitarbeiter.
            */
            // console.log(`--> Tag:   `,day);
            // console.log(`User:      `,employee);
            // console.log(`Feiertage: `,holidays);
            let totalEffort = 0;
            if (!employee.tasks) return 0;
            const currentDay = new Date(day.date + "T12:00:00");
            const absenceSet = new Set(employee.absences); // Für schnellen Zugriff
            // console.log(`User_Abs:      `,absenceSet);

            employee.tasks.forEach(task => {
                const startDate = new Date(task.start_date + "T12:00:00");
                const endDate = new Date(task.end_date + "T12:00:00");
                
                let workdays;
                // Prüfen, ob der aktuelle Kalendertag im Aufgabenzeitraum liegt
                if (currentDay >= startDate && currentDay <= endDate) {
                    // prüfen, ob der Mitarbeiter an diesem Tag abwesend ist
                    if (employee.absences && employee.absences.includes(day.date)) {
                        // abwesend
                        if (task.task_options === 'waiting') {
                            // abwesend und Aufgabe = waiting
                            // workdays = countWorkdays(task.start_date, task.end_date, holidays, absenceSet);    
                            workdays = 0;                    
                        } else { 
                            // abwesend und Aufgabe = 'continue' or undefined
                            workdays = countWorkdays(task.start_date, task.end_date, holidays);
                        }


                    } else {
                        // anwesend
                        if (task.task_options === 'waiting') {
                            // anwesend und Aufgabe = waiting
                            workdays = countWorkdays(task.start_date, task.end_date, holidays, absenceSet);                        
                        } else { 
                            // anwesend und Aufgabe = 'continue' or undefined
                            workdays = countWorkdays(task.start_date, task.end_date, holidays);
                        }

                    }

                    // console.log('Workdays: ', workdays);
                    let dailyEffort;
                    if (workdays >0) {
                        dailyEffort = task.effort_days / workdays;    
                    } else {
                        dailyEffort = 0;
                    }
                    
                    // const dailyEffort = task.effort_days / workdays;
                    // console.log('Workdays: ', workdays + ' // ' + day.date + ' : ' + employee.name + ' // ' +  task.task_name + ' // ' + task.task_options + ' // ' + dailyEffort);
                    totalEffort += dailyEffort;
                }




                /**
                if (currentDay >= startDate && currentDay <= endDate) {
                    let workdays;
                    // console.log('Tag: ', day.date + ' : ' + employee.name + ' // ' +  task.task_name + ' // ' + task.task_options);
                    if (task.task_options === 'waiting') {
                        workdays = countWorkdays(task.start_date, task.end_date, holidays, employee.absences);
                    } else { // 'continue' or undefined
                        workdays = countWorkdays(task.start_date, task.end_date, holidays);
                    }
                    const dailyEffort = task.effort_days / workdays;
                    totalEffort += dailyEffort;
                }
                */



            });

            // console.log(`Effort: `,day.date + ' --> ' + totalEffort + ' (' + employee.name + ')');
            // console.log(`User: `,employee);

            return totalEffort;
        }
     
        function toggleTaskDetails(clickedRow) {
            /**
            * Blendet die Aufgabendetails ein oder aus.
            */
            const nextRow = clickedRow.nextElementSibling;

            // Wenn Details schon sichtbar sind, ausblenden
            if (nextRow && nextRow.classList.contains('task-detail-row')) {
                let currentRow = nextRow;
                while (currentRow && currentRow.classList.contains('task-detail-row')) {
                    let next = currentRow.nextElementSibling;
                    currentRow.remove();
                    currentRow = next;
                }
                clickedRow.querySelector('.arrow-icon').innerHTML = '&#9662;'; // Pfeil nach unten
                return;
            }

            // Daten direkt aus dem 'data-*'-Attribut der angeklickten Zeile holen
            const tasks = JSON.parse(clickedRow.dataset.tasks);
            const holidays = JSON.parse(clickedRow.dataset.holidays);
            const absences = JSON.parse(clickedRow.dataset.absences);
            
            if (!tasks || tasks.length === 0) {
                const noTasksRow = document.createElement('tr');
                noTasksRow.classList.add('task-detail-row');
                noTasksRow.innerHTML = `<td colspan="100%" class="employee-name task-detail-name" style="font-style: italic;">Keine Aufgaben für diesen Mitarbeiter im Zeitraum gefunden.</td>`;
                clickedRow.parentNode.insertBefore(noTasksRow, clickedRow.nextSibling);
                clickedRow.querySelector('.arrow-icon').innerHTML = '&#9652;'; // Pfeil nach oben
                return;
            }

            let lastElement = clickedRow;

            tasks.forEach(task => {
                const detailRow = document.createElement('tr');
                detailRow.classList.add('task-detail-row');
                const nameCell = document.createElement('td');
                nameCell.textContent = task.task_name;
                nameCell.classList.add('employee-name', 'task-detail-name');
                detailRow.appendChild(nameCell);

                let workdays;
                if (task.task_options === 'waiting') {
                    workdays = countWorkdays(task.start_date, task.end_date, holidays, absences);
                } else { // 'continue' or undefined
                    workdays = countWorkdays(task.start_date, task.end_date, holidays);
                }
                const dailyEffort = task.effort_days / workdays;

                JSON.parse(clickedRow.dataset.days).forEach(day => {
                    const td = document.createElement('td');
                    const currentDay = new Date(day.date + "T12:00:00");
                    const startDate = new Date(task.start_date + "T12:00:00");
                    const endDate = new Date(task.end_date + "T12:00:00");

                    if (task.task_options === 'waiting') {
                        if (currentDay >= startDate && currentDay <= endDate && !day.isWeekend && !day.isHoliday && !absences.includes(day.date)) {
                            td.textContent = dailyEffort.toFixed(2);
                        }
                    } else { // 'continue' or undefined
                    if (currentDay >= startDate && currentDay <= endDate && !day.isWeekend && !day.isHoliday) {
                            td.textContent = dailyEffort.toFixed(2);    
                            // console.log('Datum: ',day.date);
                        }
                    }
                    if (day.isWeekend) td.classList.add('weekend');
                    detailRow.appendChild(td);
                });
                lastElement.parentNode.insertBefore(detailRow, lastElement.nextSibling);
                lastElement = detailRow;
            });
            clickedRow.querySelector('.arrow-icon').innerHTML = '&#9652;'; // Pfeil nach oben
        }


        



        function updateCalendar() {
            const viewType = document.querySelector('input[name="view"]:checked').value;
            fetch('${pageContext.request.contextPath}/calendar-overview/data?' + new URLSearchParams({
                year: currentDate.getFullYear(),
                month: currentDate.getMonth() + 1
            }))
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP-Fehler! Status: ${response.status}`);
                }
                return response.text(); // Antwort zuerst als reinen Text lesen
            })
            .then(text => {
                if (!text) {
                    // Fall 1: Die Antwort ist komplett leer
                    console.error("Leere Antwort vom Server erhalten. Möglicherweise ist ein Fehler im Servlet aufgetreten.");
                    throw new Error("Leere Server-Antwort.");
                }
                try {
                    // Fall 2: Die Antwort hat Inhalt, versuche sie zu parsen
                    return JSON.parse(text);
                } catch (e) {
                    // Fall 3: Die Antwort ist kein gültiges JSON (z.B. eine HTML-Fehlerseite)
                    console.error("Fehler beim Parsen der JSON-Antwort. Server-Antwort war:", text);
                    throw new Error("Ungültige JSON-Antwort vom Server.");
                }
            })
            .then(data => {
                const monthNames = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"];
                const currentMonthText = monthNames[currentDate.getMonth()] + ' ' + currentDate.getFullYear();
                document.getElementById('currentMonth').textContent = currentMonthText;



                // Status der Checkboxen auslesen
                const showMakCapacity = document.querySelector('input[value="mak"]').checked;
                const showAvailability = document.querySelector('input[value="availability"]').checked;
                const showAvailabilityPercent = document.querySelector('input[value="availability_percent"]').checked;
                const showTasks = document.querySelector('input[value="tasks"]').checked;
                const showWorkload = document.querySelector('input[value="workload"]').checked;
                const showWorkloadTeam = document.querySelector('input[value="workload_team"]').checked;
                const showRemaining = document.querySelector('input[value="remaining"]').checked;
                const showRemainingTeam = document.querySelector('input[value="remainingTeam"]').checked;                

                const thead = document.querySelector('#calendarGrid thead');
                const tbody = document.querySelector('#calendarGrid tbody');

                // Stellt sicher, dass die Tabellenteile existieren, bevor sie geleert werden
                if (!thead || !tbody) {
                    console.error("Fehler: <thead> oder <tbody> wurde in der Tabelle nicht gefunden.");
                    return;
                }
                thead.innerHTML = '';
                tbody.innerHTML = '';

                


                if (viewType === 'weeks') {
                    // --- Wochenansicht ---
                    // fullWidthMonthCell.colSpan = 21; // Mitarbeiter + 20 Wochen

                    const monthHeaderRow = document.createElement('tr');
                    monthHeaderRow.innerHTML = '<th class="employee-name" style="border:0;"></th>';

                    const weekHeaderRow = document.createElement('tr');
                    weekHeaderRow.innerHTML = '<th class="employee-name">KW</th>';

                    let firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
                    let monthMap = new Map();

                    for (let i = 0; i < 20; i++) {
                        let weekDate = new Date(firstDayOfMonth.getTime());
                        weekDate.setDate(weekDate.getDate() + (i * 7));
                        const month = monthNames[weekDate.getMonth()];
                        if (!monthMap.has(month)) {
                            monthMap.set(month, 0);
                        }
                        monthMap.set(month, monthMap.get(month) + 1);

                        const th = document.createElement('th');
                        th.textContent = getWeekNumber(weekDate);
                        weekHeaderRow.appendChild(th);
                    }

                    monthMap.forEach((colSpan, month) => {
                        const th = document.createElement('th');
                        th.colSpan = colSpan;
                        th.textContent = month;
                        monthHeaderRow.appendChild(th);
                    });

                    thead.appendChild(monthHeaderRow);
                    thead.appendChild(weekHeaderRow);


                    /**
                    Object.entries(data.departments).forEach(([department, employees]) => {
                        const departmentRow = document.createElement('tr');
                        departmentRow.classList.add('department-header');
                        const departmentCell = document.createElement('td');
                        departmentCell.textContent = department;
                        departmentCell.colSpan = 21;
                        departmentRow.appendChild(departmentCell);
                        tbody.appendChild(departmentRow);

                        employees.forEach(employee => {
                            const tr = document.createElement('tr');
                            const nameCell = document.createElement('td');
                            nameCell.textContent = employee.name;
                            nameCell.classList.add('employee-name');
                            tr.appendChild(nameCell);

                            for (let i = 0; i < 20; i++) {
                                const td = document.createElement('td');
                                tr.appendChild(td);
                            }
                            tbody.appendChild(tr);
                        });
                    });
                    */

                } else {
                    // Zeile für den Monatsnamen über die gesamte Breite
                    const fullWidthMonthRow = document.createElement('tr');
                    const fullWidthMonthCell = document.createElement('th');
                    fullWidthMonthCell.textContent = currentMonthText;
                    fullWidthMonthCell.style.textAlign = 'center';
                    fullWidthMonthRow.appendChild(fullWidthMonthCell);
                    thead.appendChild(fullWidthMonthRow);


                    // --- Tagesansicht (Originalfunktionalität) ---
                    fullWidthMonthCell.colSpan = data.days.length + 1;

                    const dayHeaderRow = document.createElement('tr');
                    dayHeaderRow.innerHTML = '<th class="employee-name">Tag</th>';
                    data.days.forEach(day => {
                        const th = document.createElement('th');
                        th.textContent = day.dayOfMonth;
                        if (day.isWeekend) th.classList.add('weekend');
                        dayHeaderRow.appendChild(th);
                    });
                    thead.appendChild(dayHeaderRow);


                    const holidays = data.days.filter(d => d.isHoliday);

                    // console.log('Vom Server erhaltene Daten:', data); 
                }

                    Object.entries(data.departments).forEach(([department, employees]) => {
                        const headerRow = document.createElement('tr');
                        headerRow.classList.add('department-header');
                        const headerCell = document.createElement('td');
                        headerCell.textContent = department;
                        if (viewType === 'weeks') {
                            headerCell.colSpan = 21; // Mitarbeiter + 20 Wochen
                        } else {    
                            headerCell.colSpan = data.days.length + 1;
                        }
                        
                        headerRow.appendChild(headerCell);
                        tbody.appendChild(headerRow);

                        employees.forEach(employee => {
                            // 1. Hauptzeile für den Mitarbeiter erstellen (wie bisher)
                            const tr = document.createElement('tr');
                            const nameCell = document.createElement('td');
                            nameCell.textContent = employee.name;
                            nameCell.classList.add('employee-name');
                            tr.appendChild(nameCell);

                            if (viewType === 'days') {
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
                            }

                            tbody.appendChild(tr);

                            // 2. Wenn Checkbox aktiv ist, die Kapazitätszeile erstellen
                            if (showMakCapacity) {
                                const makRow = document.createElement('tr');
                                makRow.classList.add('detail-row'); // Eigene Klasse für Styling
                                // console.log('Info Employee.Kapa:', employee.capacities);
                                // console.log('Info Employee.Abwesenheit:', employee.absences);

                                const makNameCell = document.createElement('td');
                                makNameCell.textContent = 'MAK-Kapazität';
                                makNameCell.classList.add('employee-name', 'detail-row-label');
                                makRow.appendChild(makNameCell);

                                if (viewType === 'days') {
                                    data.days.forEach(day => {
                                        const td = document.createElement('td');
                                        const capacity = getCapacityForDate(employee.capacities, day.date);
                                        // console.log('Info Employee.Kapa:', capacity);
                                        if (capacity !== null) {
                                            // td.textContent = capacity + '%';
                                            if (!day.isWeekend && !day.isHoliday) {
                                                td.textContent = (capacity.value/100).toFixed(2);
                                                // Wenn das highlight-Flag gesetzt ist, die CSS-Klasse hinzufügen
                                                if (capacity.highlight) {
                                                    td.classList.add('highlight');
                                                }
                                            }
                                        }
                                        // Hier können optional noch Klassen für Styling (weekend, etc.) hinzugefügt werden
                                        if (day.isWeekend) td.classList.add('weekend');
                                        makRow.appendChild(td);
                                    });
                                } else if (viewType === 'weeks') {
                                    // Wochenansicht: Durchschnittliche Kapazität pro Woche berechnen
                                    let firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
                                    for (let i = 0; i < 20; i++) {
                                        let weekDate = new Date(firstDayOfMonth.getTime()); 
                                        weekDate.setDate(weekDate.getDate() + (i * 7));
                                        // Berechne Start- und Enddatum der Woche (Montag bis Sonntag)
                                        let weekStart = new Date(weekDate);
                                        weekStart.setDate(weekStart.getDate() - weekStart.getDay() + 2); // Montag
                                        let weekEnd = new Date(weekStart);
                                        weekEnd.setDate(weekEnd.getDate() + 6); // Sonntag
                                        
                                        let daysInWeek;
                                        for (let j = 0; j < 7; j++) {
                                            let dDate = new Date(weekStart);
                                            dDate.setDate(dDate.getDate() + j);
                                            let dDateStr = dDate.toISOString().split('T')[0];
                                            let dayInfo = data.days.find(d => d.date === dDateStr);
                                            if (dDateStr) {
                                                if (!daysInWeek) daysInWeek = [];   
                                                daysInWeek.push(dDateStr);
                                            }
                                        }
                                        
                                        // Berechne die durchschnittliche Kapazität für diese Tage
                                        let totalCapacity = 0;
                                        let count = 0;
                                        daysInWeek.forEach(day => {
                                            let cap = getCapacityForDate(employee.capacities, day);
                                            if (cap !== null) {
                                                totalCapacity += cap.value;
                                                count++;
                                            }
                                        });

                                        const avgCapacity = count > 0 ? (totalCapacity / count) : null;
                                        const td = document.createElement('td');
                                        if (avgCapacity !== null) {
                                            td.textContent = (avgCapacity/100).toFixed(2);
                                        }
                                        makRow.appendChild(td);
                                    }
                                }
                                tbody.appendChild(makRow);
                            }
                            // 3. Verfügbarkeit anzeigen ---
                            if (showAvailability) {
                                const availabilityRow = document.createElement('tr');
                                availabilityRow.classList.add('detail-row');

                                const availabilityLabelCell = document.createElement('td');
                                availabilityLabelCell.textContent = 'Verfügbarkeit';
                                availabilityLabelCell.classList.add('employee-name', 'detail-row-label');
                                availabilityRow.appendChild(availabilityLabelCell);

                                data.days.forEach(day => {
                                    const td = document.createElement('td');
                                    const availability = getAvailabilityForDate(day, employee);
                                    if (!day.isWeekend && !day.isHoliday) {
                                        td.textContent = (availability/100).toFixed(2);
                                    }
                                    if (day.isWeekend) td.classList.add('weekend');
                                    availabilityRow.appendChild(td);
                                });
                                tbody.appendChild(availabilityRow);
                            }

                            // 4. Aufgaben anzeigen
                            if (showTasks) {
                                const employeeTaskRow = document.createElement('tr');
                                employeeTaskRow.classList.add('detail-row', 'expandable');
                                employeeTaskRow.dataset.employeeId = employee.id;
                                employeeTaskRow.dataset.holidays = JSON.stringify(holidays);
                                employeeTaskRow.dataset.days = JSON.stringify(data.days);
                                employeeTaskRow.dataset.tasks = JSON.stringify(employee.tasks || []); // Wichtig: Leeres Array als Fallback
                                employeeTaskRow.dataset.absences = JSON.stringify(employee.absences || []);

                                const TaskLabelCell = document.createElement('td');
                                TaskLabelCell.innerHTML = `<span class="arrow-icon">&#9662;</span> Aufgaben`;
                                // TaskLabelCell.textContent = 'Aufgaben';
                                TaskLabelCell.classList.add('employee-name', 'detail-row-label');
                                employeeTaskRow.appendChild(TaskLabelCell);

                                data.days.forEach(day => {
                                    const td = document.createElement('td');
                                    const taskeffort = getTaskEffortForDate(day, employee, holidays);
                                    // console.log ('Datum: ', day.date + ' --> ' + taskeffort + ' (' + employee.name + ')');
                                    if (!day.isWeekend && !day.isHoliday) {
                                        td.textContent = (taskeffort).toFixed(2);
                                    }
                                    if (day.isWeekend) td.classList.add('weekend');
                                    employeeTaskRow.appendChild(td);
                                });
                                tbody.appendChild(employeeTaskRow);                            
                            }


                            // 5. Auslastung (Workload) anzeigen
                            if (showWorkload) {
                                const WorkloadRow = document.createElement('tr');
                                WorkloadRow.classList.add('detail-row');

                                const WorkloadLabelCell = document.createElement('td');
                                WorkloadLabelCell.textContent = 'Auslastung';
                                WorkloadLabelCell.classList.add('employee-name', 'detail-row-label');
                                WorkloadRow.appendChild(WorkloadLabelCell);

                                data.days.forEach(day => {
                                    const td = document.createElement('td');
                                    const taskeffort = getTaskEffortForDate(day, employee, holidays);
                                    const availability = getAvailabilityForDate(day, employee);
                                    const workload = taskeffort / (availability/100)*100;
                                    if (!day.isWeekend && !day.isHoliday) {
                                        if (!availability==0) {
                                            td.textContent = (workload).toFixed(0) + '%';
                                            td.style.backgroundColor = getWorkloadColor(workload, data.colors);
                                        }
                                        else {
                                            if (workload > 0) {
                                                td.textContent = '∞';
                                                td.style.backgroundColor = getWorkloadColor(workload, data.colors);
                                            }
                                            else
                                            td.textContent = '';
                                        }
                                    }

                                    // const wlcolor = getWorkloadColor(workload, data.colors);

                                    // console.log ('Color: ', workload + ' / ' + wlcolor);
                                    // td.style.backgroundColor = getWorkloadColor(taskeffort, data.colors);
                                    if (day.isWeekend) td.classList.add('weekend');
                                    WorkloadRow.appendChild(td);
                                });
                                tbody.appendChild(WorkloadRow);                            
                            }



                            // #6 Rest-Verfügbarkeit anzeigen
                            if (showRemaining) {
                                const RemainingRow = document.createElement('tr');
                                RemainingRow.classList.add('detail-row');

                                const RemainingLabelCell = document.createElement('td');
                                RemainingLabelCell.textContent = 'Rest-Verfügbarkeit (MAK)';
                                RemainingLabelCell.classList.add('employee-name', 'detail-row-label');
                                RemainingRow.appendChild(RemainingLabelCell);

                                data.days.forEach(day => {
                                    const td = document.createElement('td');
                                    const taskeffort = getTaskEffortForDate(day, employee, holidays);
                                    const availability = getAvailabilityForDate(day, employee);
                                    const remaining = (availability/100) - taskeffort;  
                                    if (remaining < 0) {
                                        td.style.color  = 'red'; // Hellrot für negative Werte
                                    } 
                                    else if (remaining > 0) {
                                        td.style.color  = 'green'; // Grün für positive Werte
                                    } 
                                    else {
                                        td.style.color  = 'grey'; // Schwarz für Null
                                    }


                                    if (!day.isWeekend && !day.isHoliday) {
                                        td.textContent = (remaining).toFixed(2);                                   
                                    }

                                    // td.style.backgroundColor = getWorkloadColor(taskeffort, data.colors);
                                    if (day.isWeekend) td.classList.add('weekend');
                                    RemainingRow.appendChild(td);
                                });
                                tbody.appendChild(RemainingRow);                            
                            }

                        });
                    });
                

                const allEmployees = Object.values(data.departments).flat();
                // console.log('Alle Mitarbeiter:', allEmployees);

                // #1: Zusammenfassung für MAK-Kapazität ---
                if (showMakCapacity) {
                    // 1. Array für die Tagessummen initialisieren
                    const dailyTotals = Array(data.days.length).fill(0);

                    // 2. Durch jeden Tag des Monats iterieren
                    data.days.forEach((day, index) => {
                        // Für jeden Tag die Kapazität aller Mitarbeiter aufaddieren
                        allEmployees.forEach(employee => {
                            const capacityInfo = getCapacityForDate(employee.capacities, day.date);
                            // console.log('capacityInfo_2:', capacityInfo);
                            if (capacityInfo && typeof capacityInfo.value === 'number') {
                                dailyTotals[index] += capacityInfo.value;
                            }
                        });
                    });

                    // 3. Die Summenzeile erstellen
                    const summaryRow = document.createElement('tr');
                    summaryRow.classList.add('summary-row');

                    const summaryLabelCell = document.createElement('td');
                    summaryLabelCell.textContent = 'MAK-Kapazität';
                    summaryLabelCell.classList.add('employee-name', 'summary-label');
                    summaryRow.appendChild(summaryLabelCell);

                    // 4. Zellen für jede Tagessumme erstellen und füllen
                    dailyTotals.forEach((total, index) => {
                        const td = document.createElement('td');
                        // Summe nur anzeigen, wenn sie größer als 0 ist
                        // console.log('Summe:', 'Index = ' + index + ': ' + total);
                        // if (total > 0) {
                        if (!data.days[index].isWeekend && !data.days[index].isHoliday && total > 0) {                            
                            td.textContent = (total/100).toFixed(2);
                        }
                        if (data.days[index].isWeekend) {
                            td.classList.add('weekend');
                        }
                        summaryRow.appendChild(td);
                    });

                    // 5. Die fertige Zeile an die Tabelle anhängen
                    tbody.appendChild(summaryRow);
                }
                
                // #2: Zusammenfassung für Verfügbarkeit ---
                if (showAvailability) {
                    // 1. Array für die Tagessummen initialisieren
                    const dailyAvailabilityTotals = Array(data.days.length).fill(0);

                    // 2. Durch jeden Tag des Monats iterieren
                    data.days.forEach((day, index) => {
                        allEmployees.forEach(employee => {
                            const availability = getAvailabilityForDate(day, employee);
                            // if (typeof availability === 'number') {
                            if (!data.days[index].isWeekend && !data.days[index].isHoliday && typeof availability === 'number') {         
                                dailyAvailabilityTotals[index] += availability;
                            }
                            // console.log('Gesamt: ', index + ' --> ' + dailyAvailabilityTotals[index]);
                        });
                    });

                    // 3. Die Summenzeile erstellen
                    const summaryRow = document.createElement('tr');
                    summaryRow.classList.add('summary-row');

                    const summaryLabelCell = document.createElement('td');
                    summaryLabelCell.textContent = 'Verfügbarkeit';
                    summaryLabelCell.classList.add('employee-name', 'summary-label');
                    summaryRow.appendChild(summaryLabelCell);

                    // 4. Zellen für jede Tagessumme erstellen und füllen
                    dailyAvailabilityTotals.forEach((total, index) => {
                        const td = document.createElement('td');
                        if (total > 0) {
                            td.textContent = (total/100).toFixed(2);
                        }
                        if (data.days[index].isWeekend) {
                            td.classList.add('weekend');
                        }
                        summaryRow.appendChild(td);
                    });

                    // 5. Die fertige Zeile an die Tabelle anhängen
                    tbody.appendChild(summaryRow);
                }      

                // #3: Zusammenfassung für Verfügbarkeit in % ---
                if (showAvailabilityPercent) {
                    // 1. Array für die Tagessummen initialisieren
                    const dailyAvailabilitPercent = Array(data.days.length).fill(0);
                    const dailyTotals = Array(data.days.length).fill(0);
                    // console.log('dailyAvailabilitPercent:', dailyAvailabilitPercent);

                    // 2. Durch jeden Tag des Monats iterieren
                    data.days.forEach((day, index) => {
                        allEmployees.forEach(employee => {
                            const availabilityPercent = getAvailabilityForDate(day, employee);
                            const capacityInfo = getCapacityForDate(employee.capacities, day.date);
                            if (typeof availabilityPercent === 'number') {
                                dailyAvailabilitPercent[index] += availabilityPercent;
                            }
                            if (capacityInfo && typeof capacityInfo.value === 'number') {
                                dailyTotals[index] += capacityInfo.value;
                            }
                        });
                    });

                    // 3. Die Summenzeile erstellen
                    const summaryRow = document.createElement('tr');
                    summaryRow.classList.add('summary-row');

                    const summaryLabelCell = document.createElement('td');
                    summaryLabelCell.textContent = 'Verfügbarkeit (Team)';
                    summaryLabelCell.classList.add('employee-name', 'summary-label');
                    summaryRow.appendChild(summaryLabelCell);

                    // 4. Zellen für jede Tagessumme erstellen und füllen
                    dailyAvailabilitPercent.forEach((total, index) => {
                        const td = document.createElement('td');
                        
                        // if (total > 0) {
                        if (!data.days[index].isWeekend && !data.days[index].isHoliday) {
                            td.textContent = (total/dailyTotals[index]*100).toFixed(0) + '%';
                            // console.log('Farbe:', getColorForPercentage(total/dailyTotals[index]*100));
                            td.style.backgroundColor = getColorForPercentage(total/dailyTotals[index]*100);
                            // const PercentValue = 100 - total/dailyTotals[index]*100;
                            // console.log (PercentValue);
                            // if (PercentValue >= 100) {
                            //     td.style.backgroundColor = getWorkloadColor(100, data.colors);
                            // }
                            // else {
                                
                            //     td.style.backgroundColor = getWorkloadColor(PercentValue, data.colors);
                            // }
                            
                        }
                        if (data.days[index].isWeekend) {
                            td.classList.add('weekend');
                        }
                        summaryRow.appendChild(td);
                    });

                    // 5. Die fertige Zeile an die Tabelle anhängen
                    tbody.appendChild(summaryRow);
                }     




                // #4: Zusammenfassung für Aufgaben
                if (showTasks) {
                    // 1. Array für die Tagessummen initialisieren
                    const TaskTotals = Array(data.days.length).fill(0);
                    
                    // 2. Durch jeden Tag des Monats iterieren
                    data.days.forEach((day, index) => {
                        allEmployees.forEach(employee => {
                            const Tasks = getTaskEffortForDate(day, employee, data.days.filter(d => d.isHoliday));
                            if (!data.days[index].isWeekend && !data.days[index].isHoliday) {         
                                TaskTotals[index] += Tasks;
                            }
                        });
                    });

                    // 3. Die Summenzeile erstellen
                    const summaryRow = document.createElement('tr');
                    summaryRow.classList.add('summary-row');

                    const summaryLabelCell = document.createElement('td');
                    summaryLabelCell.textContent = 'Aufgaben';
                    summaryLabelCell.classList.add('employee-name', 'summary-label');
                    summaryRow.appendChild(summaryLabelCell);

                    // 4. Zellen für jede Tagessumme erstellen und füllen
                    TaskTotals.forEach((total, index) => {
                        const td = document.createElement('td');
                        if (total > 0) {
                            td.textContent = total.toFixed(2);
                        }
                        if (data.days[index].isWeekend) {
                            td.classList.add('weekend');
                        }
                        summaryRow.appendChild(td);
                    });

                    // 5. Die fertige Zeile an die Tabelle anhängen
                    tbody.appendChild(summaryRow);
                }


                // #4: Zusammenfassung für Workload (Team)
                if (showWorkloadTeam) {
                    // 1. Array für die Tagessummen initialisieren
                    const dailyAvailabilityTotals = Array(data.days.length).fill(0);
                    const TaskTotals = Array(data.days.length).fill(0);

                    // 2. Durch jeden Tag des Monats iterieren
                    data.days.forEach((day, index) => {
                        allEmployees.forEach(employee => {
                            const availability = getAvailabilityForDate(day, employee);
                            // if (typeof availability === 'number') {
                            if (!data.days[index].isWeekend && !data.days[index].isHoliday && typeof availability === 'number') {         
                                dailyAvailabilityTotals[index] += availability;
                            }
                            
                            const Tasks = getTaskEffortForDate(day, employee, data.days.filter(d => d.isHoliday));
                            if (!data.days[index].isWeekend && !data.days[index].isHoliday) {         
                                TaskTotals[index] += Tasks;
                            }
                        });
                    });

                    // 3. Die Summenzeile erstellen
                    const summaryRow = document.createElement('tr');
                    summaryRow.classList.add('summary-row');

                    const summaryLabelCell = document.createElement('td');
                    summaryLabelCell.textContent = 'Auslastung (Team)';
                    summaryLabelCell.classList.add('employee-name', 'summary-label');
                    summaryRow.appendChild(summaryLabelCell);

                    // 4. Zellen für jede Tagessumme erstellen und füllen
                    // console.log('dailyAvailabilityTotals', dailyAvailabilityTotals);
                    // console.log('TaskTotals', TaskTotals);
                    let ergebnis;

                    dailyAvailabilityTotals.forEach((total, index) => {
                        const td = document.createElement('td');
                        ergebnis = (TaskTotals[index] *100 / dailyAvailabilityTotals[index]);
                        // console.log('ergebnis (', index + ') ' + ergebnis);
                        if (ergebnis > 0) {
                            td.textContent = (ergebnis*100).toFixed(0) + '%';
                            td.style.backgroundColor = getColorForPercentage(100 - ergebnis*100, data.colors);
                        }
                        if (data.days[index].isWeekend) {
                            td.classList.add('weekend');
                        }
                        summaryRow.appendChild(td);
                    });

                    // 5. Die fertige Zeile an die Tabelle anhängen
                    tbody.appendChild(summaryRow);
                }


                

                     


                // #5: Zusammenfassung für Rest-Verfügbarkeit
                if (showRemaining  || showRemainingTeam) {
                    // 1. Array für die Tagessummen initialisieren
                    const TaskTotals = Array(data.days.length).fill(0);
                    const dailyAvailabilityTotals = Array(data.days.length).fill(0);

                    // 2. Durch jeden Tag des Monats iterieren
                    data.days.forEach((day, index) => {
                        allEmployees.forEach(employee => {
                            const Tasks = getTaskEffortForDate(day, employee, data.days.filter(d => d.isHoliday));
                            if (!data.days[index].isWeekend && !data.days[index].isHoliday) {         
                                TaskTotals[index] += Tasks;
                            }

                            const availability = getAvailabilityForDate(day, employee);
                            if (!data.days[index].isWeekend && !data.days[index].isHoliday && typeof availability === 'number') {         
                                dailyAvailabilityTotals[index] += availability;
                            }
                        });
                    });

                    // 3. Die Summenzeile erstellen
                    const summaryRow = document.createElement('tr');
                    summaryRow.classList.add('summary-row');

                    const summaryLabelCell = document.createElement('td');
                    summaryLabelCell.textContent = 'Rest-Verfügbarkeit (MAK)';
                    summaryLabelCell.classList.add('employee-name', 'summary-label');
                    summaryRow.appendChild(summaryLabelCell);

                    // 4. Zellen für jede Tagessumme erstellen und füllen
                    TaskTotals.forEach((total, index) => {
                        const td = document.createElement('td');
                        const RemainValue = dailyAvailabilityTotals[index]/100 - total;
                        const RemainValuePercent = RemainValue / (RemainValue + total);
                        // console.log ('Remaining:   ', ' --> ' + RemainValue ); 
                        // console.log ('Total:       ', ' --> ' + total ); 
                        // console.log ('Remaining_%: ', ' ----> ' + RemainValuePercent ); 
                        
                        if (data.days[index].isWeekend) {
                            td.classList.add('weekend');
                        }
                        else {
                            td.textContent = RemainValue.toFixed(2);
                        }
                            
                        if (RemainValue < 0) {
                            td.style.color  = 'red'; // Hellrot für negative Werte
                            td.style.backgroundColor = data.colors.calendar_workload_color_high;
                        } 
                        else if (RemainValue > 0) {
                            td.style.color  = 'green'; // Grün für positive Werte
                            td.style.backgroundColor = getColorForPercentage(100-RemainValue, data.colors);
                        } 
                        else {
                            td.style.color  = 'grey'; // Schwarz für Null
                            td.style.backgroundColor = getColorForPercentage(100-RemainValue, data.colors);
                        }
                        
                        summaryRow.appendChild(td);
                    });

                    // 5. Die fertige Zeile an die Tabelle anhängen
                    tbody.appendChild(summaryRow);
                }





                if (data.colors) {
                    updateCalendarColors(data.colors);
                }
            });
        }
    
        
        // Initial update
        updateCalendar();
    </script>
</body>
</html>        