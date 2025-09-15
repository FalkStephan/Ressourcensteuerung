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

        .detail-row-label {
            font-style: italic;
            font-weight: normal !important; /* WICHTIG: Überschreibt die fette Schrift */
            text-align: right !important;
            padding-right: 10px !important;
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
                </div>

                <div class="view-options">
                    <label><input type="checkbox" name="view" value="mak"> MAK-Kapazität</label>
                    <label><input type="checkbox" name="view" value="availability"> Verfügbarkeit</label>
                    <label><input type="checkbox" name="view" value="availability_percent"> Team-Verfügbarkeit</label>
                    <label><input type="checkbox" name="view" value="tasks"> Aufgaben</label>
                    <label><input type="checkbox" name="view" value="remaining"> Rest-Verfügbarkeit</label>
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


        /**
        * Hilfsfunktion: Findet die gültige Kapazität für ein bestimmtes Datum.
        * Geht davon aus, dass die Kapazitäten absteigend nach Datum sortiert sind.
        * @param {Array} capacities - Die Kapazitätshistorie eines Mitarbeiters.
        * @param {string} dateString - Das Datum des Kalendertages (z.B. "2025-09-10").
        * @returns {number|null} Die Kapazität in Prozent oder null, wenn keine gültig ist.
        */
        function getCapacityForDate(capacities, dateString) {
            // console.log('Info Employee.Tag:', dateString);
            // Sicherheitsprüfung für den Fall, dass ungültige Daten übergeben werden
            if (typeof dateString !== 'string' || !dateString || !capacities || capacities.length === 0) {
                return null;
            }

            if (!capacities || capacities.length === 0) {
                console.log(`Für Datum ${dateString}: Keine Kapazitätsdaten für diesen Mitarbeiter erhalten.`);
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
                        
                        // console.log(`TREFFER: `, activeCapacity);
                        return activeCapacity;
                    } 
                }


            }
            // console.log(`-> KEIN TREFFER für diesen Tag gefunden.`);
            return null; // Kein gültiger Kapazitätseintrag gefunden
        }

        /**
        * NEUE FUNKTION: Berechnet die Verfügbarkeit eines Mitarbeiters für einen bestimmten Tag.
        */
        function getAvailabilityForDate(day, employee) {
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


        /**
        * NEUE HILFSFUNKTION: Berechnet eine Farbe für einen Prozentwert
        * auf einer Skala von Rot (0%) über Gelb (50%) zu Grün (100%).
        */
        function getColorForPercentage(percent) {
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

        function updateCalendar() {
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
                document.getElementById('currentMonth').textContent = monthNames[currentDate.getMonth()] + ' ' + currentDate.getFullYear();

                const headerRow = document.querySelector('#calendarGrid thead tr');
                headerRow.innerHTML = '<th class="employee-name">Mitarbeiter</th>';
                data.days.forEach(day => {
                    const th = document.createElement('th');
                    th.textContent = day.dayOfMonth;
                    if (day.isWeekend) th.classList.add('weekend');
                    headerRow.appendChild(th);
                });

                const tbody = document.querySelector('#calendarGrid tbody');
                tbody.innerHTML = '';

                // Status der Checkboxen auslesen
                const showMakCapacity = document.querySelector('input[value="mak"]').checked;
                const showAvailability = document.querySelector('input[value="availability"]').checked;
                const showAvailabilityPercent = document.querySelector('input[value="availability_percent"]').checked;

                // console.log('Vom Server erhaltene Daten:', data); 

                Object.entries(data.departments).forEach(([department, employees]) => {
                    const headerRow = document.createElement('tr');
                    headerRow.classList.add('department-header');
                    const headerCell = document.createElement('td');
                    headerCell.textContent = department;
                    headerCell.colSpan = data.days.length + 1;
                    headerRow.appendChild(headerCell);
                    tbody.appendChild(headerRow);

                    employees.forEach(employee => {
                        // 1. Hauptzeile für den Mitarbeiter erstellen (wie bisher)
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

                            data.days.forEach(day => {
                                const td = document.createElement('td');
                                const capacity = getCapacityForDate(employee.capacities, day.date);
                                // console.log('Info Employee.Kapa:', capacity);
                                if (capacity !== null) {
                                    // td.textContent = capacity + '%';
                                    td.textContent = (capacity.value/100).toFixed(2);
                                    // Wenn das highlight-Flag gesetzt ist, die CSS-Klasse hinzufügen
                                    if (capacity.highlight) {
                                        td.classList.add('highlight');
                                    }
                                }
                                // Hier können optional noch Klassen für Styling (weekend, etc.) hinzugefügt werden
                                if (day.isWeekend) td.classList.add('weekend');
                                makRow.appendChild(td);
                            });
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
                                td.textContent = (availability/100).toFixed(2);
                                if (day.isWeekend) td.classList.add('weekend');
                                availabilityRow.appendChild(td);
                            });
                            tbody.appendChild(availabilityRow);
                        }
                    });
                });


                const allEmployees = Object.values(data.departments).flat();

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
                
                // #2: Zusammenfassung für Verfügbarkeit ---
                if (showAvailability) {
                    // 1. Array für die Tagessummen initialisieren
                    const dailyAvailabilityTotals = Array(data.days.length).fill(0);

                    // 2. Durch jeden Tag des Monats iterieren
                    data.days.forEach((day, index) => {
                        allEmployees.forEach(employee => {
                            const availability = getAvailabilityForDate(day, employee);
                            // console.log('Datum:', day);
                            // console.log('Employee:', employee);
                            // console.log('--> availability:', availability);
                            // console.log('availability:', day.date + ' / ' + employee.nachname + ', ' + employee.vorname + ' --> ' + availability);
                            if (typeof availability === 'number') {
                                dailyAvailabilityTotals[index] += availability;
                            }
                            // console.log('Gesamt: ', index + ' --> ' + dailyAvailabilityTotals[index]);
                        });
                    });

                    // console.log('Info zur Summe ', dailyAvailabilityTotals);
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
                    summaryLabelCell.textContent = 'Team-Verfügbarkeit';
                    summaryLabelCell.classList.add('employee-name', 'summary-label');
                    summaryRow.appendChild(summaryLabelCell);

                    // 4. Zellen für jede Tagessumme erstellen und füllen
                    dailyAvailabilitPercent.forEach((total, index) => {
                        const td = document.createElement('td');
                        
                        // if (total > 0) {
                        if (!data.days[index].isWeekend && !data.days[index].isHoliday) {
                            td.textContent = (total/dailyTotals[index]*100).toFixed(0) + '%';
                            console.log('Farbe:', getColorForPercentage(total/dailyTotals[index]*100));
                            td.style.backgroundColor = getColorForPercentage(total/dailyTotals[index]*100);
                        }
                        if (data.days[index].isWeekend) {
                            td.classList.add('weekend');
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
        
        function changeMonth(delta) {
            currentDate.setMonth(currentDate.getMonth() + delta);
            updateCalendar();
        }
        
        // Initial update
        updateCalendar();
    </script>
</body>
</html>
